const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const crypto = require("crypto");

setGlobalOptions({ region: "asia-southeast1", maxInstances: 10 });

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const MIN_COORD_DELTA = 0.00001;
const DUPLICATE_WINDOW_MS = 30 * 1000;
const MAX_SPEED_KMH = 300;

function sha256Hex(value) {
  return crypto.createHash("sha256").update(String(value), "utf8").digest("hex");
}

function bearerToken(req) {
  const header = req.get("Authorization") || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (match) return match[1].trim();
  return (req.get("X-Device-Token") || "").trim();
}

function deviceIdFrom(req, body) {
  return (
    (req.get("X-Device-Id") || "").trim() ||
    String(body.device_id || body.deviceId || "").trim()
  );
}

function metersBetween(lat1, lng1, lat2, lng2) {
  const r = 6371000;
  const p1 = (lat1 * Math.PI) / 180;
  const p2 = (lat2 * Math.PI) / 180;
  const dp = ((lat2 - lat1) * Math.PI) / 180;
  const dl = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dp / 2) ** 2 +
    Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) ** 2;
  return 2 * r * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function isValidCoordinates(lat, lng) {
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return false;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
  if (Math.abs(lat) < 0.0001 && Math.abs(lng) < 0.0001) return false;
  return true;
}

function tokenMatches(data, token) {
  if (!token) return false;
  const hash = sha256Hex(token);
  if (data.tokenHash && data.tokenHash === hash) return true;
  if (data.deviceToken && data.deviceToken === token) return true;
  if (data.apiTokenHash && data.apiTokenHash === token) return true;
  return false;
}

async function findTracker(deviceId) {
  const byId = await db.collection("gps_trackers").doc(deviceId).get();
  if (byId.exists) return { id: byId.id, data: byId.data() };
  const q = await db
    .collection("gps_trackers")
    .where("deviceIdentifier", "==", deviceId)
    .limit(1)
    .get();
  if (!q.empty) {
    const doc = q.docs[0];
    return { id: doc.id, data: doc.data() };
  }
  return null;
}

async function latestLocation(paroleeId) {
  const snap = await db
    .collection("location_records")
    .where("paroleeId", "==", paroleeId)
    .orderBy("recordedAt", "desc")
    .limit(1)
    .get();
  if (snap.empty) return null;
  return snap.docs[0].data();
}

exports.ingestLocation = onRequest({ cors: false, invoker: "public" }, async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ message: "Method not allowed" });
    return;
  }

  const body = req.body && typeof req.body === "object" ? req.body : {};
  const token = bearerToken(req);
  const deviceId = deviceIdFrom(req, body);
  if (!token || !deviceId) {
    res.status(401).json({ message: "Device credentials required" });
    return;
  }

  const lat = Number(body.latitude);
  const lng = Number(body.longitude);
  if (!isValidCoordinates(lat, lng)) {
    res.status(422).json({ message: "Invalid coordinates" });
    return;
  }

  const tracker = await findTracker(deviceId);
  if (!tracker) {
    res.status(401).json({ message: "Unknown device" });
    return;
  }

  if (!tokenMatches(tracker.data, token)) {
    res.status(401).json({ message: "Invalid device token" });
    return;
  }

  const status = tracker.data.status || "";
  if (status === "inactive" || status === "maintenance") {
    res.status(403).json({ message: "Device is not accepting locations" });
    return;
  }

  const paroleeId = tracker.data.paroleeId;
  if (!paroleeId) {
    res.status(422).json({ message: "Tracker is not assigned to a parolee" });
    return;
  }

  const recordedAt = body.timestamp
    ? new Date(body.timestamp)
    : new Date();
  if (Number.isNaN(recordedAt.getTime())) {
    res.status(422).json({ message: "Invalid timestamp" });
    return;
  }
  const recordedIso = recordedAt.toISOString();

  const previous = await latestLocation(paroleeId);
  if (previous && previous.recordedAt) {
    const prevAt = new Date(previous.recordedAt);
    const dt = Math.abs(recordedAt.getTime() - prevAt.getTime());
    if (
      dt <= DUPLICATE_WINDOW_MS &&
      Math.abs(Number(previous.latitude) - lat) < MIN_COORD_DELTA &&
      Math.abs(Number(previous.longitude) - lng) < MIN_COORD_DELTA
    ) {
      res.status(200).json({ message: "Duplicate location ignored" });
      return;
    }
    const seconds = (recordedAt.getTime() - prevAt.getTime()) / 1000;
    if (seconds > 0) {
      const distanceM = metersBetween(
        Number(previous.latitude),
        Number(previous.longitude),
        lat,
        lng,
      );
      const speedKmh = (distanceM / seconds) * 3.6;
      if (speedKmh > MAX_SPEED_KMH) {
        res.status(422).json({ message: "Location rejected as implausible" });
        return;
      }
    }
  }

  const now = new Date();
  const id = crypto.randomUUID();
  const accuracy = Number(body.accuracy);
  const speed = Number(body.speed);
  const battery = Number(body.battery_level ?? body.batteryLevel);

  await db.collection("location_records").doc(id).set({
    id,
    trackerId: tracker.id,
    paroleeId,
    latitude: lat,
    longitude: lng,
    accuracy: Number.isFinite(accuracy) ? accuracy : null,
    speed: Number.isFinite(speed) ? speed : null,
    batteryLevel: Number.isFinite(battery) ? battery : null,
    recordedAt: recordedIso,
    receivedAt: now.toISOString(),
    createdAt: now.toISOString(),
    source: "device",
  });

  await db.collection("gps_trackers").doc(tracker.id).update({
    batteryLevel: Number.isFinite(battery) ? battery : tracker.data.batteryLevel || null,
    lastSeenAt: now.toISOString(),
    status: "active",
    updatedAt: now.toISOString(),
  });

  res.status(201).json({
    message: "Location recorded.",
    id,
    received_at: now.toISOString(),
  });
});
