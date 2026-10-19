import 'dart:async';
import 'dart:math' as math;

import 'package:last/core/constants/tracking_config.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/models/parolee_tracking_summary.dart';
import 'package:last/features/tracking/services/check_in_proximity_service.dart';
import 'package:last/features/tracking/services/geofence_evaluation_service.dart';
import 'package:last/features/tracking/services/tracking_authorization_service.dart';
import 'package:last/features/tracking/services/tracking_repository.dart';
import 'package:last/features/tracking/services/tracking_status_service.dart';

/// Development-only mock tracking with simulated movement around Tacloban City.
class MockTrackingRepository implements TrackingRepository {
  MockTrackingRepository({
    TrackingAuthorizationService? authService,
    TrackingStatusService? statusService,
    GeofenceEvaluationService? geofenceService,
    CheckInProximityService? proximityService,
  })  : _auth = authService ?? TrackingAuthorizationService(),
        _status = statusService ?? TrackingStatusService(),
        _geofence = geofenceService ?? GeofenceEvaluationService(),
        _proximity = proximityService ?? CheckInProximityService() {
    for (final p in _demoParolees) {
      _parolees[p.id] = p;
    }
    _movementTimer = Timer.periodic(TrackingConfig.mockUpdateInterval, (_) {
      _tick++;
      _updateMockLocations();
    });
    _updateMockLocations();
  }

  final TrackingAuthorizationService _auth;
  final TrackingStatusService _status;
  final GeofenceEvaluationService _geofence;
  final CheckInProximityService _proximity;
  final _random = math.Random(42);

  final _parolees = <String, _MockParolee>{};
  Timer? _movementTimer;
  int _tick = 0;

  static final _demoParolees = [
    _MockParolee(
      id: 'demo-parolee',
      fullName: 'Juan Dela Cruz',
      caseNumber: 'CASE-001',
      officerId: 'demo-officer',
      tracker: GpsTracker(
        id: 'TRK-001',
        deviceIdentifier: 'mock-dev-001',
        paroleeId: 'demo-parolee',
        paroleeName: 'Juan Dela Cruz',
        status: TrackerDeviceStatus.active,
        batteryLevel: 82,
        lastSeenAt: DateTime.now(),
      ),
    ),
    _MockParolee(
      id: 'demo-parolee-2',
      fullName: 'Maria Santos',
      caseNumber: 'CASE-002',
      officerId: 'demo-officer',
      tracker: GpsTracker(
        id: 'TRK-002',
        deviceIdentifier: 'mock-dev-002',
        paroleeId: 'demo-parolee-2',
        paroleeName: 'Maria Santos',
        status: TrackerDeviceStatus.offline,
        batteryLevel: 15,
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    ),
    _MockParolee(
      id: 'demo-parolee-3',
      fullName: 'Pedro Reyes',
      caseNumber: 'CASE-003',
      officerId: 'demo-officer',
      tracker: GpsTracker(
        id: 'TRK-003',
        deviceIdentifier: 'mock-dev-003',
        paroleeId: 'demo-parolee-3',
        paroleeName: 'Pedro Reyes',
        status: TrackerDeviceStatus.active,
        batteryLevel: 64,
        lastSeenAt: DateTime.now(),
      ),
    ),
  ];

  void _updateMockLocations() {
    final now = DateTime.now();
    for (final entry in _parolees.entries) {
      final p = entry.value;
      if (p.tracker == null) continue;

      // Orbit ≈ 50 m so simulated GPS actually enters and leaves the radius.
      final phase = p.tracker!.id == 'TRK-003' ? 2.1 : 0.0;
      final angle = _tick * 0.3 + phase + _random.nextDouble() * 0.05;
      final orbit = TrackingConfig.mockProximityOrbitDegrees;
      final offsetLat = math.sin(angle) * orbit;
      final offsetLng = math.cos(angle) * orbit;

      final isOffline = p.tracker!.id == 'TRK-002';
      if (isOffline) continue;

      final location = LocationRecord(
        id: 'mock-loc-${p.id}-$_tick',
        trackerId: p.tracker!.id,
        paroleeId: p.id,
        latitude: TrackingConfig.mockBaseLatitude + offsetLat,
        longitude: TrackingConfig.mockBaseLongitude + offsetLng,
        accuracy: 4.0 + _random.nextDouble() * 3,
        speed: 2.0 + _random.nextDouble() * 4,
        batteryLevel: p.tracker!.batteryLevel,
        recordedAt: now,
        receivedAt: now,
        source: GpsSource.simulated,
      );

      p.latestLocation = location;
      p.tracker = p.tracker!.copyWith(lastSeenAt: now, updatedAt: now);
      p.history.insert(0, location);
      if (p.history.length > 100) p.history.removeLast();
    }
  }

  AppUser _asAppUser(_MockParolee p) => AppUser(
        id: p.id,
        email: '${p.id}@demo.local',
        fullName: p.fullName,
        role: UserRole.parolee,
        caseNumber: p.caseNumber,
        officerId: p.officerId,
        trackerId: p.tracker?.id,
      );

  ParoleeTrackingSummary _toSummary(_MockParolee p) {
    final geofences = p.geofences;
    final geofenceStatus = _geofence.evaluate(location: p.latestLocation, geofences: geofences);
    final checkInProximity = _proximity.evaluate(
      isAuthorized: p.tracker != null && p.tracker!.isAssigned,
      tracker: p.tracker,
      location: p.latestLocation,
      geofences: geofences,
      isSimulated: true,
    );
    return ParoleeTrackingSummary(
      paroleeId: p.id,
      fullName: p.fullName,
      caseNumber: p.caseNumber,
      officerId: p.officerId,
      trackingStatus: _status.resolve(tracker: p.tracker, latestLocation: p.latestLocation),
      tracker: p.tracker,
      latestLocation: p.latestLocation,
      geofenceStatus: geofenceStatus,
      geofences: geofences,
      checkInProximity: checkInProximity,
    );
  }

  @override
  Stream<List<ParoleeTrackingSummary>> watchAssignedParolees({
    required AppUser requester,
    required String officerId,
  }) {
    final controller = StreamController<List<ParoleeTrackingSummary>>();
    Timer? timer;

    void emit() {
      if (controller.isClosed) return;
      final list = _parolees.values
          .where((p) => p.officerId == officerId)
          .map(_toSummary)
          .toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
      controller.add(list);
    }

    emit();
    timer = Timer.periodic(TrackingConfig.mockUpdateInterval, (_) => emit());

    controller.onCancel = () => timer?.cancel();
    return controller.stream;
  }

  @override
  Stream<ParoleeTrackingSummary> watchParoleeTracking({
    required AppUser requester,
    required String paroleeId,
  }) {
    final controller = StreamController<ParoleeTrackingSummary>();
    Timer? timer;

    void emit() {
      if (controller.isClosed) return;
      final p = _parolees[paroleeId];
      if (p == null) {
        controller.addError(TrackingAuthorizationException('Parolee not found.'));
        return;
      }
      _auth.assertCanTrack(requester, _asAppUser(p));
      controller.add(_toSummary(p));
    }

    emit();
    timer = Timer.periodic(TrackingConfig.mockUpdateInterval, (_) => emit());

    controller.onCancel = () => timer?.cancel();
    return controller.stream;
  }

  @override
  Future<LocationRecord?> getLatestLocation({
    required AppUser requester,
    required String paroleeId,
  }) async {
    final p = _parolees[paroleeId];
    if (p == null) return null;
    _auth.assertCanTrack(requester, _asAppUser(p));
    return p.latestLocation;
  }

  @override
  Future<List<LocationRecord>> getLocationHistory({
    required AppUser requester,
    required String paroleeId,
    DateTime? start,
    DateTime? end,
    int limit = 50,
    String? startAfterId,
  }) async {
    final p = _parolees[paroleeId];
    if (p == null) return [];
    _auth.assertCanTrack(requester, _asAppUser(p));

    var list = p.history;
    if (start != null) {
      list = list.where((r) => r.recordedAt != null && !r.recordedAt!.isBefore(start)).toList();
    }
    if (end != null) {
      list = list.where((r) => r.recordedAt != null && !r.recordedAt!.isAfter(end)).toList();
    }
    if (startAfterId != null) {
      final idx = list.indexWhere((r) => r.id == startAfterId);
      if (idx >= 0) list = list.sublist(idx + 1);
    }
    return list.take(limit).toList();
  }

  @override
  Future<GpsTracker?> getTrackerForParolee(String paroleeId) async {
    return _parolees[paroleeId]?.tracker;
  }

  @override
  Future<List<Geofence>> getGeofencesForParolee(String paroleeId) async {
    return _parolees[paroleeId]?.geofences ?? [];
  }

  @override
  Future<void> submitLocation({
    required String trackerId,
    required String deviceToken,
    required LocationRecord location,
  }) async {
    throw UnsupportedError('Mock repository does not accept device submissions');
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
  }
}

class _MockParolee {
  _MockParolee({
    required this.id,
    required this.fullName,
    required this.caseNumber,
    required this.officerId,
    this.tracker,
  }) : geofences = [
          Geofence(
            id: 'gf-checkin-$id',
            paroleeId: id,
            name: 'PPA Check-in Office',
            centerLat: TrackingConfig.mockBaseLatitude,
            centerLng: TrackingConfig.mockBaseLongitude,
            radiusMeters: TrackingConfig.checkInProximityRadiusMeters,
          ),
          if (id == 'demo-parolee')
            Geofence(
              id: 'gf-1',
              paroleeId: id,
              name: 'Tacloban Monitoring Zone',
              centerLat: TrackingConfig.mockBaseLatitude,
              centerLng: TrackingConfig.mockBaseLongitude,
              radiusMeters: 1500,
            ),
        ];

  final String id;
  final String fullName;
  final String caseNumber;
  final String officerId;
  GpsTracker? tracker;
  LocationRecord? latestLocation;
  final List<LocationRecord> history = [];
  final List<Geofence> geofences;
}
