import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:last/core/services/notification_service.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/tracking/models/check_in_proximity.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/models/parolee_tracking_summary.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/features/tracking/services/check_in_proximity_notifier.dart';
import 'package:last/features/tracking/services/check_in_proximity_service.dart';
import 'package:last/features/tracking/services/proximity_latch_store.dart';
import 'package:last/features/tracking/services/tracking_alert_service.dart';
import 'package:last/features/tracking/services/tracking_audit_service.dart';
import 'package:last/features/tracking/services/tracking_repository.dart';

class _NoopLatchStore extends ProximityLatchStore {
  @override
  Future<void> hydrate(CheckInProximityNotifier notifier) async {}

  @override
  Future<void> persist(CheckInProximityNotifier notifier) async {}
}

class _FakeRepo implements TrackingRepository {
  final controller = StreamController<List<ParoleeTrackingSummary>>.broadcast();

  @override
  Stream<List<ParoleeTrackingSummary>> watchAssignedParolees({
    required AppUser requester,
    required String officerId,
  }) =>
      controller.stream;

  @override
  Stream<ParoleeTrackingSummary> watchParoleeTracking({
    required AppUser requester,
    required String paroleeId,
  }) =>
      const Stream.empty();

  @override
  Future<LocationRecord?> getLatestLocation({
    required AppUser requester,
    required String paroleeId,
  }) async =>
      null;

  @override
  Future<List<LocationRecord>> getLocationHistory({
    required AppUser requester,
    required String paroleeId,
    DateTime? start,
    DateTime? end,
    int limit = 50,
    String? startAfterId,
  }) async =>
      [];

  @override
  Future<GpsTracker?> getTrackerForParolee(String paroleeId) async => null;

  @override
  Future<List<Geofence>> getGeofencesForParolee(String paroleeId) async => [];

  @override
  Future<void> submitLocation({
    required String trackerId,
    required String deviceToken,
    required LocationRecord location,
  }) async {}

  @override
  void dispose() {
    controller.close();
  }
}

void main() {
  const officer = AppUser(
    id: 'off-1',
    email: 'o@demo.local',
    fullName: 'Officer',
    role: UserRole.officer,
  );

  final tracker = GpsTracker(
    id: 'TRK-001',
    deviceIdentifier: 'dev-1',
    paroleeId: 'p1',
    paroleeName: 'Juan',
  );

  const checkIn = CheckInLocation(
    id: 'loc-1',
    name: 'PPA Check-in Office',
    latitude: 11.240800,
    longitude: 125.003900,
  );

  final proximity = CheckInProximityService(radiusMeters: 50);
  final now = DateTime(2026, 10, 12, 10);

  LocationRecord loc({required double metersNorth, String id = 'a'}) {
    return LocationRecord(
      id: id,
      trackerId: 'TRK-001',
      paroleeId: 'p1',
      latitude: checkIn.latitude + metersNorth / 111320.0,
      longitude: checkIn.longitude,
      accuracy: 5,
      recordedAt: now,
      source: GpsSource.simulated,
    );
  }

  ParoleeTrackingSummary summary({
    required LocationRecord? location,
    String paroleeId = 'p1',
    String name = 'Juan Dela Cruz',
  }) {
    final result = proximity.evaluate(
      isAuthorized: true,
      tracker: tracker,
      location: location,
      checkInLocation: checkIn,
      now: now,
      sessionId: 'sess-1',
    );
    return ParoleeTrackingSummary(
      paroleeId: paroleeId,
      fullName: name,
      caseNumber: 'CASE-001',
      officerId: officer.id,
      trackingStatus: TrackingStatus.active,
      tracker: tracker,
      latestLocation: location,
      checkInProximity: result,
    );
  }

  TrackingProvider makeProvider(_FakeRepo repo) {
    return TrackingProvider(
      repository: repo,
      alertService: TrackingAlertService(
        notificationService: InMemoryNotificationService(),
        cooldownService: TrackingAlertCooldownService(),
      ),
      latchStore: _NoopLatchStore(),
    );
  }

  test('notifies once at 20 m, ignores further updates while inside', () async {
    final repo = _FakeRepo();
    final provider = makeProvider(repo);
    provider.startWatchingAssigned(requester: officer, officerId: officer.id);

    repo.controller.add([summary(location: loc(metersNorth: 20, id: '1'))]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.recentProximityAlerts, hasLength(1));

    repo.controller.add([summary(location: loc(metersNorth: 20, id: '2'))]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.recentProximityAlerts, hasLength(1));

    provider.dispose();
  });

  test('exactly 50 m notifies once; 51 m does not notify', () async {
    final repo = _FakeRepo();
    final provider = makeProvider(repo);
    provider.startWatchingAssigned(requester: officer, officerId: officer.id);

    repo.controller.add([summary(location: loc(metersNorth: 51, id: 'out'))]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.recentProximityAlerts, isEmpty);

    repo.controller.add([summary(location: loc(metersNorth: 50, id: 'edge'))]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.recentProximityAlerts, hasLength(1));

    provider.dispose();
  });

  test('leave then re-enter notifies again', () async {
    final repo = _FakeRepo();
    final provider = makeProvider(repo);
    provider.startWatchingAssigned(requester: officer, officerId: officer.id);

    repo.controller.add([summary(location: loc(metersNorth: 20, id: 'in1'))]);
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([summary(location: loc(metersNorth: 80, id: 'out'))]);
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([summary(location: loc(metersNorth: 20, id: 'in2'))]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.recentProximityAlerts, hasLength(2));
    provider.dispose();
  });

  test('stale GPS and missing GPS do not notify', () async {
    final repo = _FakeRepo();
    final provider = makeProvider(repo);
    provider.startWatchingAssigned(requester: officer, officerId: officer.id);

    final stale = LocationRecord(
      id: 'stale',
      trackerId: 'TRK-001',
      paroleeId: 'p1',
      latitude: checkIn.latitude,
      longitude: checkIn.longitude,
      accuracy: 5,
      recordedAt: now.subtract(const Duration(minutes: 10)),
    );
    repo.controller.add([summary(location: stale)]);
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([summary(location: null)]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.recentProximityAlerts, isEmpty);
    provider.dispose();
  });

  test('two parolees generate independent notifications', () async {
    final repo = _FakeRepo();
    final provider = makeProvider(repo);
    provider.startWatchingAssigned(requester: officer, officerId: officer.id);

    repo.controller.add([
      summary(location: loc(metersNorth: 20, id: 'p1-in'), paroleeId: 'p1', name: 'Juan'),
      ParoleeTrackingSummary(
        paroleeId: 'p2',
        fullName: 'Maria',
        caseNumber: 'CASE-002',
        officerId: officer.id,
        trackingStatus: TrackingStatus.active,
        tracker: tracker.copyWith(paroleeId: 'p2'),
        latestLocation: loc(metersNorth: 15, id: 'p2-in'),
        checkInProximity: proximity.evaluate(
          isAuthorized: true,
          tracker: tracker.copyWith(paroleeId: 'p2'),
          location: loc(metersNorth: 15, id: 'p2-in'),
          checkInLocation: checkIn,
          now: now,
          sessionId: 'sess-1',
        ),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.recentProximityAlerts, hasLength(2));
    provider.dispose();
  });

  test('duplicate ESP32 / device event key does not create a second alert', () async {
    final repo = _FakeRepo();
    final provider = makeProvider(repo);
    provider.startWatchingAssigned(requester: officer, officerId: officer.id);

    final reading = loc(metersNorth: 20, id: 'esp32-dup');
    repo.controller.add([summary(location: reading)]);
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([summary(location: reading)]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.recentProximityAlerts, hasLength(1));
    provider.dispose();
  });

  test('new check-in session allows another notification while still inside', () async {
    final repo = _FakeRepo();
    final provider = makeProvider(repo);
    provider.startWatchingAssigned(requester: officer, officerId: officer.id);

    repo.controller.add([summary(location: loc(metersNorth: 20, id: 's1'))]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.recentProximityAlerts, hasLength(1));

    provider.beginCheckInSession(paroleeId: 'p1', sessionId: 'sess-2');
    repo.controller.add([summary(location: loc(metersNorth: 20, id: 's2'))]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.recentProximityAlerts, hasLength(2));
    provider.dispose();
  });
}
