import 'package:last/core/utils/geo_distance.dart';
import 'package:last/features/tracking/models/location_record.dart';

/// Validates GPS payloads from IoT devices before storage.
class LocationValidationService {
  static const double minCoordinateDelta = 0.00001;

  bool isValidCoordinates(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    if (latitude.abs() < 0.0001 && longitude.abs() < 0.0001) return false;
    return true;
  }

  bool isDuplicate({
    required LocationRecord existing,
    required double latitude,
    required double longitude,
    required DateTime recordedAt,
    Duration window = const Duration(seconds: 30),
  }) {
    if (existing.recordedAt == null) return false;
    final withinWindow = recordedAt.difference(existing.recordedAt!).abs() <= window;
    if (!withinWindow) return false;

    final latMatch = (existing.latitude - latitude).abs() < minCoordinateDelta;
    final lngMatch = (existing.longitude - longitude).abs() < minCoordinateDelta;
    return latMatch && lngMatch;
  }

  bool isImpossibleJump({
    required LocationRecord? previous,
    required double latitude,
    required double longitude,
    required DateTime recordedAt,
    double maxSpeedKmh = 300,
  }) {
    if (previous == null || previous.recordedAt == null) return false;

    final seconds = recordedAt.difference(previous.recordedAt!).inSeconds;
    if (seconds <= 0) return false;

    final distanceM = GeoDistance.metersBetween(
      lat1: previous.latitude,
      lng1: previous.longitude,
      lat2: latitude,
      lng2: longitude,
    );
    final speedKmh = (distanceM / seconds) * 3.6;
    return speedKmh > maxSpeedKmh;
  }
}
