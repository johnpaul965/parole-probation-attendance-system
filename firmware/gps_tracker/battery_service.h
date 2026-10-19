#ifndef BATTERY_SERVICE_H
#define BATTERY_SERVICE_H

class BatteryService {
public:
  void begin(int adcPin) { _pin = adcPin; }

  int readPercent() {
    if (_pin < 0) return -1;
    int raw = analogRead(_pin);
    // Map ADC reading to 0-100% (calibrate per hardware divider)
    float voltage = (raw / 4095.0) * 3.3 * 2.0; // example 2:1 divider
    int percent = (int)((voltage - 3.0) / (4.2 - 3.0) * 100.0);
    if (percent < 0) percent = 0;
    if (percent > 100) percent = 100;
    return percent;
  }

private:
  int _pin = -1;
};

#endif
