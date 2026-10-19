class AppConfig {
  static const bool useFirebase = true;

  /// GPS simulation is off for production ingest (ESP32 Cloud Function).
  static bool get enableMockLocationSimulator => false;
}
