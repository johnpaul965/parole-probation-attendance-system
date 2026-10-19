/// Origin of a GPS reading. Same proximity rules apply to every source.
enum GpsSource {
  mobile,
  esp32,
  simulated;

  static GpsSource? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final source in GpsSource.values) {
      if (source.name == value) return source;
    }
    return null;
  }
}

class LocationRecord {
  const LocationRecord({
    required this.id,
    required this.trackerId,
    required this.paroleeId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.batteryLevel,
    this.recordedAt,
    this.receivedAt,
    this.createdAt,
    this.source,
  });

  final String id;
  final String trackerId;
  final String paroleeId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final int? batteryLevel;
  final DateTime? recordedAt;
  final DateTime? receivedAt;
  final DateTime? createdAt;
  final GpsSource? source;

  bool get isSimulated => source == GpsSource.simulated;

  bool get hasValidCoordinates =>
      latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;

  Map<String, dynamic> toMap() => {
        'id': id,
        'trackerId': trackerId,
        'paroleeId': paroleeId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'batteryLevel': batteryLevel,
        'recordedAt': recordedAt?.toIso8601String(),
        'receivedAt': receivedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'source': source?.name,
      };

  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    return LocationRecord(
      id: map['id'] as String? ?? '',
      trackerId: map['trackerId'] as String? ?? '',
      paroleeId: map['paroleeId'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      batteryLevel: (map['batteryLevel'] as num?)?.toInt(),
      recordedAt: _parseDate(map['recordedAt']),
      receivedAt: _parseDate(map['receivedAt']),
      createdAt: _parseDate(map['createdAt']),
      source: GpsSource.tryParse(map['source'] as String?),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
