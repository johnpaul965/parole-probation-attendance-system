enum TrackerDeviceStatus {
  active,
  inactive,
  offline,
  maintenance,
  unassigned;

  static TrackerDeviceStatus fromString(String? value) {
    return TrackerDeviceStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => TrackerDeviceStatus.unassigned,
    );
  }

  String get label => switch (this) {
        TrackerDeviceStatus.active => 'Active',
        TrackerDeviceStatus.inactive => 'Inactive',
        TrackerDeviceStatus.offline => 'Offline',
        TrackerDeviceStatus.maintenance => 'Maintenance',
        TrackerDeviceStatus.unassigned => 'Unassigned',
      };
}

class GpsTracker {
  const GpsTracker({
    required this.id,
    required this.deviceIdentifier,
    this.deviceName,
    this.deviceType,
    this.serialNumber,
    this.paroleeId,
    this.paroleeName,
    this.status = TrackerDeviceStatus.unassigned,
    this.batteryLevel,
    this.lastSeenAt,
    this.assignedAt,
    this.createdAt,
    this.updatedAt,
    this.ingestAuthUid,
  });

  final String id;
  final String deviceIdentifier;

  /// Human-readable device ID (e.g. DEV-000001). Falls back to [id].
  String get deviceId => deviceIdentifier.isNotEmpty ? deviceIdentifier : id;
  final String? deviceName;
  final String? deviceType;
  final String? serialNumber;
  final String? paroleeId;
  final String? paroleeName;
  final TrackerDeviceStatus status;
  final int? batteryLevel;
  final DateTime? lastSeenAt;
  final DateTime? assignedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? ingestAuthUid;

  bool get isAssigned => paroleeId != null && paroleeId!.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'deviceIdentifier': deviceIdentifier,
        'deviceName': deviceName,
        'deviceType': deviceType,
        'serialNumber': serialNumber,
        'paroleeId': paroleeId,
        'paroleeName': paroleeName,
        'status': status.name,
        'batteryLevel': batteryLevel,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'assignedAt': assignedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'ingestAuthUid': ingestAuthUid,
      };

  factory GpsTracker.fromMap(Map<String, dynamic> map) {
    return GpsTracker(
      id: map['id'] as String? ?? '',
      deviceIdentifier: map['deviceIdentifier'] as String? ?? map['device_id'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? map['device_name'] as String?,
      deviceType: map['deviceType'] as String? ?? map['device_type'] as String?,
      serialNumber: map['serialNumber'] as String? ?? map['serial_number'] as String?,
      paroleeId: map['paroleeId'] as String?,
      paroleeName: map['paroleeName'] as String?,
      status: TrackerDeviceStatus.fromString(map['status'] as String?),
      batteryLevel: (map['batteryLevel'] as num?)?.toInt(),
      lastSeenAt: _parseDate(map['lastSeenAt']),
      assignedAt: _parseDate(map['assignedAt']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      ingestAuthUid: map['ingestAuthUid'] as String?,
    );
  }

  GpsTracker copyWith({
    String? paroleeId,
    String? paroleeName,
    TrackerDeviceStatus? status,
    int? batteryLevel,
    DateTime? lastSeenAt,
    DateTime? updatedAt,
    String? ingestAuthUid,
  }) {
    return GpsTracker(
      id: id,
      deviceIdentifier: deviceIdentifier,
      paroleeId: paroleeId ?? this.paroleeId,
      paroleeName: paroleeName ?? this.paroleeName,
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ingestAuthUid: ingestAuthUid ?? this.ingestAuthUid,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
