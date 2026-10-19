import 'package:flutter_test/flutter_test.dart';
import 'package:last/core/utils/geo_distance.dart';
import 'package:last/features/tracking/models/check_in_proximity.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/services/check_in_proximity_service.dart';

void main() {
  const checkIn = CheckInLocation(
    id: 'loc-1',
    name: 'PPA Check-in Office',
    latitude: 11.240800,
    longitude: 125.003900,
  );

  const geofence = Geofence(
    id: 'loc-1',
    paroleeId: 'p1',
    name: 'PPA Check-in Office',
    centerLat: 11.240800,
    centerLng: 125.003900,
    radiusMeters: 500,
  );

  final tracker = GpsTracker(
    id: 'TRK-001',
    deviceIdentifier: 'dev-1',
    paroleeId: 'p1',
    paroleeName: 'Juan',
  );

  final now = DateTime(2026, 10, 12, 10, 0);

  LocationRecord reading({
    required double distanceMetersNorth,
    double accuracy = 5,
    DateTime? recordedAt,
    String id = 'loc-a',
  }) {
    // ~111_320 meters per degree latitude.
    final latOffset = distanceMetersNorth / 111320.0;
    return LocationRecord(
      id: id,
      trackerId: 'TRK-001',
      paroleeId: 'p1',
      latitude: checkIn.latitude + latOffset,
      longitude: checkIn.longitude,
      accuracy: accuracy,
      recordedAt: recordedAt ?? now,
    );
  }

  final service = CheckInProximityService(radiusMeters: 50);

  group('CheckInProximityService distance thresholds', () {
    test('20 meters → inside', () {
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: reading(distanceMetersNorth: 20),
        checkInLocation: checkIn,
        now: now,
      );
      expect(result.status, CheckInProximityStatus.inside);
      expect(result.distanceMeters, closeTo(20, 1));
    });

    test('exactly 50 meters → inside', () {
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: reading(distanceMetersNorth: 50),
        checkInLocation: checkIn,
        now: now,
      );
      expect(result.status, CheckInProximityStatus.inside);
      expect(result.distanceMeters, closeTo(50, 1));
    });

    test('51 meters → outside (no proximity qualify)', () {
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: reading(distanceMetersNorth: 51),
        checkInLocation: checkIn,
        now: now,
      );
      expect(result.status, CheckInProximityStatus.outside);
      expect(result.distanceMeters, closeTo(51, 1));
    });
  });

  group('GPS trust rules', () {
    test('invalid 0,0 coordinates → GPS unavailable', () {
      final loc = LocationRecord(
        id: 'zero',
        trackerId: 'TRK-001',
        paroleeId: 'p1',
        latitude: 0,
        longitude: 0,
        accuracy: 5,
        recordedAt: now,
      );
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: loc,
        checkInLocation: checkIn,
        now: now,
      );
      expect(result.status, CheckInProximityStatus.gpsUnavailable);
    });

    test('null location → GPS unavailable', () {
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: null,
        checkInLocation: checkIn,
        now: now,
      );
      expect(result.status, CheckInProximityStatus.gpsUnavailable);
    });

    test('stale reading → location unverified', () {
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: reading(
          distanceMetersNorth: 20,
          recordedAt: now.subtract(const Duration(minutes: 5)),
        ),
        checkInLocation: checkIn,
        now: now,
      );
      expect(result.status, CheckInProximityStatus.locationUnverified);
    });

    test('poor accuracy → location unverified', () {
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: reading(distanceMetersNorth: 20, accuracy: 80),
        checkInLocation: checkIn,
        now: now,
      );
      expect(result.status, CheckInProximityStatus.locationUnverified);
    });

    test('missing accuracy → location unverified', () {
      final loc = LocationRecord(
        id: 'x',
        trackerId: 'TRK-001',
        paroleeId: 'p1',
        latitude: checkIn.latitude,
        longitude: checkIn.longitude,
        recordedAt: now,
      );
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: loc,
        checkInLocation: checkIn,
        now: now,
      );
      expect(result.status, CheckInProximityStatus.locationUnverified);
    });

    test('unauthorized tracker → unauthorized', () {
      final result = service.evaluate(
        isAuthorized: false,
        tracker: tracker,
        location: reading(distanceMetersNorth: 10),
        checkInLocation: checkIn,
        now: now,
      );
      expect(result.status, CheckInProximityStatus.unauthorized);
    });

    test('no check-in location → location unverified', () {
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: reading(distanceMetersNorth: 10),
        geofences: const [],
        now: now,
      );
      expect(result.status, CheckInProximityStatus.locationUnverified);
    });

    test('resolves check-in location from geofence', () {
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: reading(distanceMetersNorth: 10),
        geofences: [geofence],
        now: now,
      );
      expect(result.status, CheckInProximityStatus.inside);
      expect(result.locationName, 'PPA Check-in Office');
    });

    test('prefers a geofence named as check-in over a larger monitoring zone', () {
      const monitoring = Geofence(
        id: 'zone',
        paroleeId: 'p1',
        name: 'Tacloban Monitoring Zone',
        centerLat: 11.25,
        centerLng: 125.01,
        radiusMeters: 1500,
      );
      const office = Geofence(
        id: 'office',
        paroleeId: 'p1',
        name: 'PPA Check-in Office',
        centerLat: 11.240800,
        centerLng: 125.003900,
        radiusMeters: 50,
      );
      final result = service.evaluate(
        isAuthorized: true,
        tracker: tracker,
        location: reading(distanceMetersNorth: 10),
        geofences: [monitoring, office],
        now: now,
      );
      expect(result.locationId, 'office');
      expect(result.status, CheckInProximityStatus.inside);
    });

    test('mobile and ESP32 sources use the same 50 m rules', () {
      for (final source in [GpsSource.mobile, GpsSource.esp32, GpsSource.simulated]) {
        final loc = LocationRecord(
          id: 'loc-$source',
          trackerId: 'TRK-001',
          paroleeId: 'p1',
          latitude: checkIn.latitude,
          longitude: checkIn.longitude,
          accuracy: 5,
          recordedAt: now,
          source: source,
        );
        final result = service.evaluate(
          isAuthorized: true,
          tracker: tracker,
          location: loc,
          checkInLocation: checkIn,
          now: now,
        );
        expect(result.status, CheckInProximityStatus.inside);
        expect(result.isSimulated, source == GpsSource.simulated);
      }
    });
  });

  group('GeoDistance', () {
    test('haversine is ~0 at same point', () {
      expect(
        GeoDistance.metersBetween(
          lat1: 11.24,
          lng1: 125.0,
          lat2: 11.24,
          lng2: 125.0,
        ),
        closeTo(0, 0.01),
      );
    });
  });
}
