import 'package:last/core/utils/geo_distance.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/location_record.dart';

class GeofenceEvaluationService {
  GeofenceStatus evaluate({
    required LocationRecord? location,
    required List<Geofence> geofences,
  }) {
    if (location == null || !location.hasValidCoordinates) {
      return GeofenceStatus.unknown;
    }

    final active = geofences
        .where((g) => g.isActive && !g.isCheckInPoint)
        .toList();
    if (active.isEmpty) return GeofenceStatus.noGeofence;

    final insideAny = active.any(
      (g) =>
          GeoDistance.metersBetween(
            lat1: location.latitude,
            lng1: location.longitude,
            lat2: g.centerLat,
            lng2: g.centerLng,
          ) <=
          g.radiusMeters,
    );

    return insideAny ? GeofenceStatus.inside : GeofenceStatus.outside;
  }
}
