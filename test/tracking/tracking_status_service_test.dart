import 'package:flutter_test/flutter_test.dart';
import 'package:last/core/constants/tracking_config.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/features/tracking/services/tracking_status_service.dart';

void main() {
  final service = TrackingStatusService();
  final now = DateTime(2026, 8, 24, 12, 0);

  GpsTracker tracker({DateTime? lastSeen, int? battery}) => GpsTracker(
        id: 'TRK-001',
        deviceIdentifier: 'dev-001',
        paroleeId: 'p1',
        paroleeName: 'Test',
        status: TrackerDeviceStatus.active,
        batteryLevel: battery ?? 80,
        lastSeenAt: lastSeen ?? now,
      );

  LocationRecord location({
    DateTime? recordedAt,
    int? battery,
    double lat = 11.24,
    double lng = 125.0,
  }) =>
      LocationRecord(
        id: 'loc-1',
        trackerId: 'TRK-001',
        paroleeId: 'p1',
        latitude: lat,
        longitude: lng,
        accuracy: 5,
        batteryLevel: battery ?? 80,
        recordedAt: recordedAt ?? now,
      );

  group('TrackingStatusService', () {
    test('returns NO_TRACKER when tracker is null', () {
      expect(
        service.resolve(tracker: null, latestLocation: null, now: now),
        TrackingStatus.noTracker,
      );
    });

    test('returns ACTIVE for phone GPS without a hardware tracker', () {
      expect(
        service.resolve(
          tracker: null,
          latestLocation: LocationRecord(
            id: 'loc-phone',
            trackerId: 'phone_p1',
            paroleeId: 'p1',
            latitude: 11.24,
            longitude: 125.0,
            accuracy: 5,
            recordedAt: now,
            source: GpsSource.mobile,
          ),
          now: now,
        ),
        TrackingStatus.active,
      );
    });

    test('returns ACTIVE for recent valid location', () {
      expect(
        service.resolve(
          tracker: tracker(),
          latestLocation: location(),
          now: now,
        ),
        TrackingStatus.active,
      );
    });

    test('returns OFFLINE when location is stale', () {
      expect(
        service.resolve(
          tracker: tracker(),
          latestLocation: location(
            recordedAt: now.subtract(TrackingConfig.offlineTimeout + const Duration(minutes: 1)),
          ),
          now: now,
        ),
        TrackingStatus.offline,
      );
    });

    test('returns LOW_BATTERY when battery below threshold', () {
      expect(
        service.resolve(
          tracker: tracker(battery: 15),
          latestLocation: location(battery: 15),
          now: now,
        ),
        TrackingStatus.lowBattery,
      );
    });

    test('returns GPS_UNAVAILABLE for invalid coordinates', () {
      expect(
        service.resolve(
          tracker: tracker(),
          latestLocation: location(lat: 0, lng: 0),
          now: now,
        ),
        TrackingStatus.gpsUnavailable,
      );
    });

    test('returns OFFLINE when no location and tracker last seen is stale', () {
      expect(
        service.resolve(
          tracker: tracker(lastSeen: now.subtract(const Duration(hours: 1))),
          latestLocation: null,
          now: now,
        ),
        TrackingStatus.offline,
      );
    });
  });
}
