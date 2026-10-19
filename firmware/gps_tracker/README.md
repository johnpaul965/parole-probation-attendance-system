# GPS Tracker Firmware (Supabase REST)

Modular ESP32 firmware for the **PPA-TAC** system. The device sends coordinates directly to Supabase PostgreSQL through the **PostgREST API** over HTTPS.

## Hardware Support

- **MCU:** ESP32 (NodeMCU / DOIT ESP32 DevKit)
- **GPS Module:** NEO-6M, NEO-7M, NEO-M8N, Quectel L86, or any NMEA GPS via `TinyGPSPlus`
- **Connectivity:** Wi-Fi (built-in ESP32) or GSM/GPRS module (SIM800L / SIM7600)
- **Battery:** ADC via voltage divider (GPIO 34)

## Required Arduino Libraries

Install these via the **Arduino IDE Library Manager**:
1. `TinyGPSPlus` by Mikal Hart
2. `ArduinoJson` by Benoit Blanchon (version 6.x or 7.x)

## Project Structure

```
firmware/gps_tracker/
├── gps_tracker.ino      # Main setup and loop
├── device_config.h      # Supabase URL, Anon Key, pin configurations
├── gps_service.h        # GPS reading and parsing via TinyGPSPlus
├── battery_service.h    # Battery level ADC calculations
├── network_service.h    # Wi-Fi connection and reconnect handling
└── api_client.h         # Direct Supabase PostgREST HTTPS client
```

## Quick Start & Flashing Instructions

1. **Open in Arduino IDE**:
   - Open `firmware/gps_tracker/gps_tracker.ino`.
2. **Configure Wi-Fi**:
   - In `gps_tracker.ino`, replace `your-wifi-ssid` and `your-wifi-password` with your network credentials.
3. **Verify Configuration**:
   - `device_config.h` is pre-configured with your Supabase endpoint:
     `https://iqltrfkyzbeepfpmsxci.supabase.co`
     and public Anon key.
4. **Flash to ESP32**:
   - Connect your ESP32 board via USB.
   - Select **Tools → Board → ESP32 Dev Module**.
   - Select the correct COM/Serial port.
   - Click **Upload**.
5. **Open Serial Monitor**:
   - Set baud rate to **115200**.
   - When the GPS acquires satellite fix, coordinates will be sent directly to your Supabase `location_logs` table!

## Adaptive Transmission Strategy

| State | Speed | Transmission Interval |
| :--- | :--- | :--- |
| **Moving** | > 3 km/h | 30 seconds |
| **Normal** | 0.5 – 3 km/h | 60 seconds |
| **Stationary** | < 0.5 km/h | 120 seconds |
