import 'package:last/core/constants/tracking_config.dart';

/// Proximity of a parolee GPS reading to their assigned check-in location.
enum CheckInProximityStatus {
  /// Valid reading at or within the configured radius (default 50 m).
  inside,

  /// Valid reading beyond the configured radius.
  outside,

  /// No usable GPS payload (missing, invalid coords, or GPS failure).
  gpsUnavailable,

  /// Reading present but not trusted (stale, inaccurate, or no check-in point).
  locationUnverified,

  /// Tracker / device not authorized for this parolee.
  unauthorized;

  static int get radiusMetersLabel =>
      TrackingConfig.checkInProximityRadiusMeters.round();

  String get label => switch (this) {
        CheckInProximityStatus.inside => 'Inside $radiusMetersLabel m',
        CheckInProximityStatus.outside => 'Outside $radiusMetersLabel m',
        CheckInProximityStatus.gpsUnavailable => 'GPS unavailable',
        CheckInProximityStatus.locationUnverified => 'Location unverified',
        CheckInProximityStatus.unauthorized => 'Unauthorized',
      };

  /// True when the reading is trusted enough to show a measured distance.
  bool get hasTrustedDistance =>
      this == CheckInProximityStatus.inside || this == CheckInProximityStatus.outside;
}

/// Immutable evaluation of one GPS reading against a check-in location.
class CheckInProximityResult {
  const CheckInProximityResult({
    required this.status,
    this.distanceMeters,
    this.locationName,
    this.locationId,
    this.evaluatedAt,
    this.sessionId,
    this.isSimulated = false,
  });

  final CheckInProximityStatus status;
  final double? distanceMeters;
  final String? locationName;
  final String? locationId;
  final DateTime? evaluatedAt;
  final String? sessionId;
  final bool isSimulated;

  static const CheckInProximityResult unauthorized = CheckInProximityResult(
    status: CheckInProximityStatus.unauthorized,
  );

  static const CheckInProximityResult gpsUnavailable = CheckInProximityResult(
    status: CheckInProximityStatus.gpsUnavailable,
  );

  CheckInProximityResult copyWith({
    CheckInProximityStatus? status,
    double? distanceMeters,
    String? locationName,
    String? locationId,
    DateTime? evaluatedAt,
    String? sessionId,
    bool? isSimulated,
  }) {
    return CheckInProximityResult(
      status: status ?? this.status,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      locationName: locationName ?? this.locationName,
      locationId: locationId ?? this.locationId,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      sessionId: sessionId ?? this.sessionId,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }
}

/// Assigned check-in / authorized location used for the 50 m geofence.
class CheckInLocation {
  const CheckInLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
}
