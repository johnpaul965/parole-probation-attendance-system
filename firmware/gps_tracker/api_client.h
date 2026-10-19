#ifndef API_CLIENT_H
#define API_CLIENT_H

#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include "device_config.h"

struct LocationPayload {
  double latitude;
  double longitude;
  double accuracy;
  double speed;
  int batteryLevel;
  String timestamp;
};

class ApiClient {
public:
  bool sendLocation(const LocationPayload& loc) {
    WiFiClientSecure client;
#if USE_INSECURE_TLS
    client.setInsecure();
#endif

    HTTPClient http;
    String endpoint = String(SUPABASE_URL) + "/rest/v1/location_logs";

    if (!http.begin(client, endpoint)) {
      Serial.println("[HTTP] Failed to connect to Supabase endpoint");
      return false;
    }

    // Set Supabase PostgREST headers
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", SUPABASE_ANON_KEY);
    http.addHeader("Authorization", String("Bearer ") + SUPABASE_ANON_KEY);
    http.addHeader("Prefer", "return=minimal");

    // Construct JSON payload matching Supabase location_logs schema
    StaticJsonDocument<256> doc;
    doc["latitude"] = loc.latitude;
    doc["longitude"] = loc.longitude;
    doc["speed"] = loc.speed;
    doc["battery_level"] = loc.batteryLevel;
    doc["tracker_id"] = TRACKER_ID;

    String requestBody;
    serializeJson(doc, requestBody);

    int httpResponseCode = http.POST(requestBody);
    http.end();

    if (httpResponseCode >= 200 && httpResponseCode < 300) {
      Serial.printf("[Supabase] Location log recorded: %.5f, %.5f (Code: %d)\n",
                    loc.latitude, loc.longitude, httpResponseCode);
      return true;
    } else {
      Serial.printf("[Supabase] POST error code: %d\n", httpResponseCode);
      return false;
    }
  }
};

#endif
