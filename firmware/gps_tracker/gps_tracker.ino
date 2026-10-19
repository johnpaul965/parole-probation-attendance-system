/**
 * GPS Tracker — Main firmware
 *
 * Libraries required (Arduino Library Manager):
 *   - TinyGPSPlus by Mikal Hart
 *   - ArduinoJson by Benoit Blanchon
 *
 * For GSM/GPRS instead of Wi-Fi, replace NetworkService with
 * a SIM800L HTTP client using AT commands.
 */

#include <time.h>
#include "device_config.h"
#include "gps_service.h"
#include "battery_service.h"
#include "network_service.h"
#include "api_client.h"

// Wi-Fi credentials for ESP32 (or use GSM module)
const char* WIFI_SSID = "your-wifi-ssid";
const char* WIFI_PASS = "your-wifi-password";

GpsService gps;
BatteryService battery;
NetworkService network;
ApiClient api;

// Offline queue
LocationPayload queue[MAX_QUEUE_SIZE];
int queueHead = 0;
int queueTail = 0;

// Last sent position (avoid duplicate sends)
double lastSentLat = 0;
double lastSentLng = 0;
unsigned long lastSentMs = 0;

unsigned long lastTransmitMs = 0;

void enqueue(const LocationPayload& loc) {
  int next = (queueTail + 1) % MAX_QUEUE_SIZE;
  if (next == queueHead) return; // full
  queue[queueTail] = loc;
  queueTail = next;
}

bool dequeue(LocationPayload& loc) {
  if (queueHead == queueTail) return false;
  loc = queue[queueHead];
  queueHead = (queueHead + 1) % MAX_QUEUE_SIZE;
  return true;
}

bool isDuplicate(double lat, double lng) {
  if (millis() - lastSentMs < 30000) {
    if (abs(lat - lastSentLat) < 0.00001 && abs(lng - lastSentLng) < 0.00001) {
      return true;
    }
  }
  return false;
}

unsigned long getInterval(double speedKmh) {
  if (speedKmh > MOVING_SPEED_KMH) return INTERVAL_MOVING_MS;
  if (speedKmh > 0.5) return INTERVAL_NORMAL_MS;
  return INTERVAL_STATIONARY_MS;
}

String isoTimestamp() {
  time_t now = time(nullptr);
  if (now < 1700000000) {
    return "";
  }
  struct tm timeinfo;
  gmtime_r(&now, &timeinfo);
  char buf[32];
  strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);
  return String(buf);
}

bool transmit(LocationPayload loc) {
  if (isDuplicate(loc.latitude, loc.longitude)) return true;

  if (!network.isConnected()) {
    enqueue(loc);
    return false;
  }

  if (api.sendLocation(loc)) {
    lastSentLat = loc.latitude;
    lastSentLng = loc.longitude;
    lastSentMs = millis();
    return true;
  }

  enqueue(loc);
  return false;
}

void flushQueue() {
  LocationPayload loc;
  while (dequeue(loc)) {
    if (!transmit(loc)) {
      enqueue(loc); // put back if failed
      break;
    }
    delay(200); // rate limit
  }
}

void setup() {
  Serial.begin(115200);
  gps.begin(GPS_RX_PIN, GPS_TX_PIN);
  battery.begin(BATTERY_ADC_PIN);
  network.begin(WIFI_SSID, WIFI_PASS);
  Serial.println("GPS Tracker initialized");
}

void loop() {
  network.reconnect(WIFI_SSID, WIFI_PASS);

  if (gps.update() && gps.hasValidFix()) {
    auto fix = gps.getFix();
    unsigned long interval = getInterval(fix.speedKmh);

    if (millis() - lastTransmitMs >= interval) {
      LocationPayload payload;
      payload.latitude = fix.latitude;
      payload.longitude = fix.longitude;
      payload.accuracy = fix.accuracy;
      payload.speed = fix.speedKmh;
      payload.batteryLevel = battery.readPercent();
      payload.timestamp = isoTimestamp();

      transmit(payload);
      lastTransmitMs = millis();
    }
  }

  flushQueue();
  delay(1000);
}
