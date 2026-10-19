import 'package:last/core/constants/tracking_config.dart';
import 'package:last/core/utils/geo_distance.dart';
import 'package:last/features/tracking/models/check_in_proximity.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';

/// Evaluates whether a parolee's GPS reading is within the check-in proximity
/// radius. Pure logic — no UI or notification side effects.
class CheckInProximityService {
  CheckInProximityService({
    this.radiusMeters = TrackingConfig.checkInProximityRadiusMeters,
    this.maxAccuracyMeters = TrackingConfig.maxGpsAccuracyMeters,
    this.maxAge = TrackingConfig.maxGpsAgeForProximity,
  });

  /// Configurable geofence radius; defaults to 50 meters.
  final double radiusMeters;
  final double maxAccuracyMeters;
  final Duration maxAge;

  /// Resolve the assigned check-in location from active geofences (preferred)
  /// or an explicit override.
  CheckInLocation? resolveCheckInLocation({
    List<Geofence> geofences = const [],
    CheckInLocation? override,
  }) {
    if (override != null) return override;
    final active = geofences.where((g) => g.isActive).toList();
    if (active.isEmpty) return null;
    final namedCheckIn = active.where((g) => g.isCheckInPoint);
    final g = namedCheckIn.isNotEmpty ? namedCheckIn.first : active.first;
    return CheckInLocation(
      id: g.id,
      name: g.name,
      latitude: g.centerLat,
      longitude: g.centerLng,
    );
  }

  CheckInProximityResult evaluate({
    required bool isAuthorized,
    GpsTracker? tracker,
    LocationRecord? location,
    CheckInLocation? checkInLocation,
    List<Geofence> geofences = const [],
    DateTime? now,
    String? sessionId,
    bool isSimulated = false,
  }) {
    final reference = now ?? DateTime.now();
    final session = sessionId ?? _defaultSessionId(reference);
    final simulated = isSimulated || location?.isSimulated == true;

    if (!isAuthorized || tracker == null || !tracker.isAssigned) {
      return CheckInProximityResult(
        status: CheckInProximityStatus.unauthorized,
        sessionId: session,
        isSimulated: simulated,
      );
    }

    final checkIn = checkInLocation ??
        resolveCheckInLocation(geofences: geofences);
    if (checkIn == null) {
      return CheckInProximityResult(
        status: CheckInProximityStatus.locationUnverified,
        evaluatedAt: reference,
        sessionId: session,
        isSimulated: simulated,
      );
    }

    if (location == null || !_hasUsableCoordinates(location)) {
      return CheckInProximityResult(
        status: CheckInProximityStatus.gpsUnavailable,
        locationName: checkIn.name,
        locationId: checkIn.id,
        evaluatedAt: reference,
        sessionId: session,
        isSimulated: simulated,
      );
    }

    if (!_isFresh(location, reference) || !_isAccurateEnough(location)) {
      return CheckInProximityResult(
        status: CheckInProximityStatus.locationUnverified,
        locationName: checkIn.name,
        locationId: checkIn.id,
        evaluatedAt: reference,
        sessionId: session,
        isSimulated: simulated,
      );
    }

    final distance = GeoDistance.metersBetween(
      lat1: location.latitude,
      lng1: location.longitude,
      lat2: checkIn.latitude,
      lng2: checkIn.longitude,
    );

    final inside = distance <= radiusMeters;
    return CheckInProximityResult(
      status: inside
          ? CheckInProximityStatus.inside
          : CheckInProximityStatus.outside,
      distanceMeters: distance,
      locationName: checkIn.name,
      locationId: checkIn.id,
      evaluatedAt: location.recordedAt ?? location.receivedAt ?? reference,
      sessionId: session,
      isSimulated: simulated,
    );
  }

  bool _hasUsableCoordinates(LocationRecord location) {
    if (!location.hasValidCoordinates) return false;
    if (location.latitude.abs() < 0.0001 && location.longitude.abs() < 0.0001) {
      return false;
    }
    return true;
  }

  bool _isFresh(LocationRecord location, DateTime now) {
    final stamped = location.recordedAt ?? location.receivedAt;
    if (stamped == null) return false;
    return now.difference(stamped) <= maxAge;
  }

  bool _isAccurateEnough(LocationRecord location) {
    final accuracy = location.accuracy;
    if (accuracy == null) return false;
    return accuracy <= maxAccuracyMeters;
  }

  String _defaultSessionId(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
