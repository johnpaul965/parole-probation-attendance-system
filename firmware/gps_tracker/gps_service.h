#ifndef GPS_SERVICE_H
#define GPS_SERVICE_H

#include <TinyGPSPlus.h>
#include <HardwareSerial.h>

struct GpsFix {
  bool valid;
  double latitude;
  double longitude;
  double speedKmh;
  double accuracy;
};

class GpsService {
public:
  void begin(int rxPin, int txPin, uint32_t baud = 9600) {
    _serial = new HardwareSerial(1);
    _serial->begin(baud, SERIAL_8N1, rxPin, txPin);
  }

  bool update() {
    while (_serial->available()) {
      if (_gps.encode(_serial->read())) {
        if (_gps.location.isValid()) {
          _lastFix.valid = true;
          _lastFix.latitude = _gps.location.lat();
          _lastFix.longitude = _gps.location.lng();
          _lastFix.speedKmh = _gps.speed.kmph();
          _lastFix.accuracy = _gps.hdop.isValid() ? _gps.hdop.hdop() * 5.0 : 10.0;
          return true;
        }
      }
    }
    return false;
  }

  GpsFix getFix() const { return _lastFix; }

  bool hasValidFix() const {
    return _lastFix.valid &&
           _lastFix.latitude >= -90 && _lastFix.latitude <= 90 &&
           _lastFix.longitude >= -180 && _lastFix.longitude <= 180 &&
           !(_lastFix.latitude == 0 && _lastFix.longitude == 0);
  }

private:
  TinyGPSPlus _gps;
  HardwareSerial* _serial = nullptr;
  GpsFix _lastFix = {false, 0, 0, 0, 0};
};

#endif
