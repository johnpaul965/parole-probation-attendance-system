import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/constants/tracking_config.dart';
import 'package:last/core/utils/error_handler.dart';
import 'package:last/core/utils/token_hash.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/services/tracking_audit_service.dart';
import 'package:uuid/uuid.dart';

class CreateTrackerResult {
  const CreateTrackerResult({required this.tracker, required this.deviceToken});

  final GpsTracker tracker;
  final String deviceToken;
}

abstract class TrackerAdminService {
  Stream<List<GpsTracker>> watchAllTrackers();
  Future<List<GpsTracker>> getAllTrackers();
  Future<GpsTracker?> getTrackerById(String trackerId);
  Future<CreateTrackerResult> createTracker({required String trackerId, required String deviceIdentifier});
  Future<void> assignTracker({
    required String trackerId,
    required String paroleeId,
    required String paroleeName,
    String? assignedBy,
  });
  Future<void> unassignTracker(String trackerId, {String? actorId});
  Future<void> updateTrackerStatus(String trackerId, TrackerDeviceStatus status);
  Future<void> setIngestAuthUid(String trackerId, String ingestAuthUid);
  Future<String> rotateDeviceToken(String trackerId);
  Future<List<LocationRecord>> getDeviceLocationLogs(String trackerId, {int limit = 50});
  Future<void> assignGeofence({
    required String paroleeId,
    required String name,
    required double centerLat,
    required double centerLng,
    double radiusMeters = TrackingConfig.defaultGeofenceRadiusMeters,
  });
  Future<List<Geofence>> getGeofencesForParolee(String paroleeId);
}

class FirebaseTrackerAdminService implements TrackerAdminService {
  FirebaseTrackerAdminService({
    FirebaseFirestore? firestore,
    TrackingAuditService? auditService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _audit = auditService ?? TrackingAuditService();

  final FirebaseFirestore _db;
  final TrackingAuditService _audit;

  @override
  Stream<List<GpsTracker>> watchAllTrackers() {
    return _db.collection(FirestoreCollections.gpsTrackers).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => GpsTracker.fromMap({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      return list;
    });
  }

  @override
  Future<List<GpsTracker>> getAllTrackers() async {
    final snap = await _db.collection(FirestoreCollections.gpsTrackers).get();
    return snap.docs.map((d) => GpsTracker.fromMap({...d.data(), 'id': d.id})).toList();
  }

  @override
  Future<GpsTracker?> getTrackerById(String trackerId) async {
    final doc = await _db.collection(FirestoreCollections.gpsTrackers).doc(trackerId).get();
    if (!doc.exists) return null;
    return GpsTracker.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<CreateTrackerResult> createTracker({
    required String trackerId,
    required String deviceIdentifier,
  }) async {
    final now = DateTime.now();
    final deviceToken = const Uuid().v4();
    final tracker = GpsTracker(
      id: trackerId,
      deviceIdentifier: deviceIdentifier,
      status: TrackerDeviceStatus.unassigned,
      createdAt: now,
      updatedAt: now,
    );
    await _db.collection(FirestoreCollections.gpsTrackers).doc(trackerId).set({
      ...tracker.toMap(),
      'tokenHash': sha256Hex(deviceToken),
    });

    await _audit.logDeviceAssignment(
      action: 'device_registered',
      trackerId: trackerId,
      actorRole: 'officer',
    );

    return CreateTrackerResult(tracker: tracker, deviceToken: deviceToken);
  }

  @override
  Future<void> assignTracker({
    required String trackerId,
    required String paroleeId,
    required String paroleeName,
    String? assignedBy,
  }) async {
    try {
      final batch = _db.batch();
      final trackerRef = _db.collection(FirestoreCollections.gpsTrackers).doc(trackerId);
      final paroleeRef = _db.collection(FirestoreCollections.users).doc(paroleeId);

      // Unassign tracker from any previous parolee.
      final existing = await _db
          .collection(FirestoreCollections.gpsTrackers)
          .where('paroleeId', isEqualTo: paroleeId)
          .get();
      for (final doc in existing.docs) {
        if (doc.id != trackerId) {
          batch.update(doc.reference, {
            'paroleeId': null,
            'paroleeName': null,
            'status': TrackerDeviceStatus.unassigned.name,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }

      // Ensure tracker is not assigned to another parolee.
      final trackerDoc = await trackerRef.get();
      if (trackerDoc.exists) {
        final prevParoleeId = trackerDoc.data()?['paroleeId'] as String?;
        if (prevParoleeId != null && prevParoleeId != paroleeId) {
          await _db.collection(FirestoreCollections.users).doc(prevParoleeId).update({
            'trackerId': null,
          });
        }
      }

      final now = DateTime.now().toIso8601String();
      batch.update(trackerRef, {
        'paroleeId': paroleeId,
        'paroleeName': paroleeName,
        'status': TrackerDeviceStatus.active.name,
        'assignedAt': now,
        'updatedAt': now,
      });
      batch.update(paroleeRef, {
        'trackerId': trackerId,
        'assignedTrackerId': trackerId,
      });

      batch.set(_db.collection(FirestoreCollections.deviceAssignments).doc(), {
        'trackerId': trackerId,
        'paroleeId': paroleeId,
        'paroleeName': paroleeName,
        'assignedBy': assignedBy,
        'assignedAt': now,
        'status': 'active',
        'createdAt': now,
      });

      await batch.commit();

      await _audit.logDeviceAssignment(
        action: 'device_assigned',
        trackerId: trackerId,
        paroleeId: paroleeId,
        actorId: assignedBy,
        actorRole: 'officer',
      );
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to assign tracker');
    }
  }

  @override
  Future<void> unassignTracker(String trackerId, {String? actorId}) async {
    try {
      final trackerRef = _db.collection(FirestoreCollections.gpsTrackers).doc(trackerId);
      final trackerDoc = await trackerRef.get();
      if (!trackerDoc.exists) return;

      final paroleeId = trackerDoc.data()?['paroleeId'] as String?;
      final batch = _db.batch();
      batch.update(trackerRef, {
        'paroleeId': null,
        'paroleeName': null,
        'status': TrackerDeviceStatus.unassigned.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (paroleeId != null) {
        batch.update(_db.collection(FirestoreCollections.users).doc(paroleeId), {
          'trackerId': null,
          'assignedTrackerId': null,
        });
      }
      await batch.commit();

      await _audit.logDeviceAssignment(
        action: 'device_unassigned',
        trackerId: trackerId,
        paroleeId: paroleeId,
        actorId: actorId,
        actorRole: 'officer',
      );
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to unassign tracker');
    }
  }

  @override
  Future<void> updateTrackerStatus(String trackerId, TrackerDeviceStatus status) async {
    await _db.collection(FirestoreCollections.gpsTrackers).doc(trackerId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> setIngestAuthUid(String trackerId, String ingestAuthUid) async {
    final uid = ingestAuthUid.trim();
    if (uid.isEmpty) {
      throw ErrorHandler.wrap(Exception('empty'), 'Device Auth UID is required');
    }
    try {
      await _db.collection(FirestoreCollections.gpsTrackers).doc(trackerId).update({
        'ingestAuthUid': uid,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to link device Auth UID');
    }
  }

  @override
  Future<String> rotateDeviceToken(String trackerId) async {
    final newToken = const Uuid().v4();
    await _db.collection(FirestoreCollections.gpsTrackers).doc(trackerId).update({
      'tokenHash': sha256Hex(newToken),
      'deviceToken': FieldValue.delete(),
      'apiTokenHash': FieldValue.delete(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _audit.logDeviceAssignment(
      action: 'device_token_rotated',
      trackerId: trackerId,
      actorRole: 'officer',
    );
    return newToken;
  }

  @override
  Future<List<LocationRecord>> getDeviceLocationLogs(String trackerId, {int limit = 50}) async {
    final snap = await _db
        .collection(FirestoreCollections.locationRecords)
        .where('trackerId', isEqualTo: trackerId)
        .orderBy('recordedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => LocationRecord.fromMap({...d.data(), 'id': d.id})).toList();
  }

  @override
  Future<void> assignGeofence({
    required String paroleeId,
    required String name,
    required double centerLat,
    required double centerLng,
    double radiusMeters = TrackingConfig.defaultGeofenceRadiusMeters,
  }) async {
    final id = const Uuid().v4();
    final geofence = Geofence(
      id: id,
      paroleeId: paroleeId,
      name: name,
      centerLat: centerLat,
      centerLng: centerLng,
      radiusMeters: radiusMeters,
    );
    await _db.collection(FirestoreCollections.geofences).doc(id).set(geofence.toMap());
  }

  @override
  Future<List<Geofence>> getGeofencesForParolee(String paroleeId) async {
    final snap = await _db
        .collection(FirestoreCollections.geofences)
        .where('paroleeId', isEqualTo: paroleeId)
        .get();
    return snap.docs.map((d) => Geofence.fromMap({...d.data(), 'id': d.id})).toList();
  }
}

TrackerAdminService createTrackerAdminService() => FirebaseTrackerAdminService();
