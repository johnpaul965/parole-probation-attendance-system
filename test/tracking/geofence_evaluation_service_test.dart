import 'package:flutter_test/flutter_test.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/services/geofence_evaluation_service.dart';

void main() {
  final service = GeofenceEvaluationService();

  const geofence = Geofence(
    id: 'gf-1',
    paroleeId: 'p1',
    name: 'Zone',
    centerLat: 11.240800,
    centerLng: 125.003900,
    radiusMeters: 500,
  );

  LocationRecord atCenter() => LocationRecord(
        id: 'loc',
        trackerId: 't1',
        paroleeId: 'p1',
        latitude: 11.240800,
        longitude: 125.003900,
      );

  LocationRecord farAway() => LocationRecord(
        id: 'loc',
        trackerId: 't1',
        paroleeId: 'p1',
        latitude: 11.300000,
        longitude: 125.100000,
      );

  group('GeofenceEvaluationService', () {
    test('returns INSIDE when location is within radius', () {
      expect(
        service.evaluate(location: atCenter(), geofences: [geofence]),
        GeofenceStatus.inside,
      );
    });

    test('returns OUTSIDE when location is beyond radius', () {
      expect(
        service.evaluate(location: farAway(), geofences: [geofence]),
        GeofenceStatus.outside,
      );
    });

    test('returns NO_GEOFENCE when no geofences configured', () {
      expect(
        service.evaluate(location: atCenter(), geofences: []),
        GeofenceStatus.noGeofence,
      );
    });

    test('returns UNKNOWN when location is null', () {
      expect(
        service.evaluate(location: null, geofences: [geofence]),
        GeofenceStatus.unknown,
      );
    });

    test('ignores 50 m check-in points so leaving them is not a geofence exit', () {
      const checkIn = Geofence(
        id: 'gf-checkin',
        paroleeId: 'p1',
        name: 'PPA Check-in Office',
        centerLat: 11.240800,
        centerLng: 125.003900,
        radiusMeters: 50,
      );
      expect(
        service.evaluate(location: farAway(), geofences: [checkIn]),
        GeofenceStatus.noGeofence,
      );
    });
  });
}
