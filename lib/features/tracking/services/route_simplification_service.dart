import 'package:last/features/tracking/models/location_record.dart';

/// Downsamples a route polyline for map rendering without loading thousands of points.
class RouteSimplificationService {
  /// Douglas-Peucker simplification with tolerance in degrees (~111m per 0.001°).
  List<LocationRecord> simplify(
    List<LocationRecord> points, {
    double tolerance = 0.0001,
    int maxPoints = 200,
  }) {
    if (points.length <= 2) return points;
    if (points.length <= maxPoints) {
      return _douglasPeucker(points, tolerance);
    }

    // First simplify, then uniform sample if still too many
    var simplified = _douglasPeucker(points, tolerance);
    if (simplified.length <= maxPoints) return simplified;

    final step = (simplified.length / maxPoints).ceil();
    final sampled = <LocationRecord>[];
    for (var i = 0; i < simplified.length; i += step) {
      sampled.add(simplified[i]);
    }
    if (sampled.last != simplified.last) {
      sampled.add(simplified.last);
    }
    return sampled;
  }

  List<LocationRecord> _douglasPeucker(List<LocationRecord> points, double tolerance) {
    if (points.length < 3) return points;

    double maxDist = 0;
    int index = 0;
    final start = points.first;
    final end = points.last;

    for (var i = 1; i < points.length - 1; i++) {
      final d = _perpendicularDistance(points[i], start, end);
      if (d > maxDist) {
        maxDist = d;
        index = i;
      }
    }

    if (maxDist > tolerance) {
      final left = _douglasPeucker(points.sublist(0, index + 1), tolerance);
      final right = _douglasPeucker(points.sublist(index), tolerance);
      return [...left.sublist(0, left.length - 1), ...right];
    }

    return [start, end];
  }

  double _perpendicularDistance(LocationRecord point, LocationRecord lineStart, LocationRecord lineEnd) {
    final dx = lineEnd.longitude - lineStart.longitude;
    final dy = lineEnd.latitude - lineStart.latitude;
    if (dx == 0 && dy == 0) {
      return _dist(point, lineStart);
    }
    final t = ((point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy) /
        (dx * dx + dy * dy);
    final clamped = t.clamp(0.0, 1.0);
    final projLat = lineStart.latitude + clamped * dy;
    final projLng = lineStart.longitude + clamped * dx;
    return _dist(point, LocationRecord(
      id: '',
      trackerId: '',
      paroleeId: '',
      latitude: projLat,
      longitude: projLng,
    ));
  }

  double _dist(LocationRecord a, LocationRecord b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
  }
}
