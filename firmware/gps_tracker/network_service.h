#ifndef NETWORK_SERVICE_H
#define NETWORK_SERVICE_H

#include <WiFi.h>
#include <time.h>

class NetworkService {
public:
  bool begin(const char* ssid, const char* password) {
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);
    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - start < 30000) {
      delay(500);
    }
    if (WiFi.status() == WL_CONNECTED) {
      configTime(8 * 3600, 0, "pool.ntp.org", "time.nist.gov");
    }
    return WiFi.status() == WL_CONNECTED;
  }

  bool isConnected() { return WiFi.status() == WL_CONNECTED; }

  void reconnect(const char* ssid, const char* password) {
    if (!isConnected()) begin(ssid, password);
  }
};

#endif
