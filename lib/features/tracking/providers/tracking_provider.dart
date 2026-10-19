import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/tracking/models/check_in_proximity.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/models/parolee_tracking_summary.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/features/tracking/services/check_in_proximity_notifier.dart';
import 'package:last/features/tracking/services/proximity_latch_store.dart';
import 'package:last/features/tracking/services/tracking_alert_service.dart';
import 'package:last/features/tracking/services/tracking_authorization_service.dart';
import 'package:last/features/tracking/services/tracking_repository.dart';
import 'package:last/features/tracking/services/tracking_service_factory.dart';

class TrackingProvider extends ChangeNotifier {
  TrackingProvider({
    TrackingRepository? repository,
    TrackingAlertService? alertService,
    CheckInProximityNotifier? proximityNotifier,
    ProximityLatchStore? latchStore,
  })  : _repository = repository ?? createTrackingRepository(),
        _alerts = alertService ?? createTrackingAlertService(),
        _proximityNotifier = proximityNotifier ?? CheckInProximityNotifier(),
        _latchStore = latchStore ?? ProximityLatchStore();

  final TrackingRepository _repository;
  final TrackingAlertService _alerts;
  final CheckInProximityNotifier _proximityNotifier;
  final ProximityLatchStore _latchStore;
  Future<void>? _hydrateFuture;
  bool _latchesReady = false;
  bool _disposed = false;

  List<ParoleeTrackingSummary> _assignedParolees = [];
  ParoleeTrackingSummary? _activeTracking;
  List<LocationRecord> _locationHistory = [];
  bool _hasMoreHistory = false;
  String? _lastHistoryCursor;
  bool _assignedLoading = false;
  bool _paroleeLoading = false;
  bool _historyLoading = false;
  String? _assignedError;
  String? _paroleeError;
  String? _historyError;
  StreamSubscription<List<ParoleeTrackingSummary>>? _assignedSub;
  StreamSubscription<ParoleeTrackingSummary>? _trackingSub;
  final Map<String, TrackingStatus> _lastKnownStatus = {};
  final Map<String, GeofenceStatus> _lastGeofenceStatus = {};
  final List<ProximityAlertEvent> _recentProximityAlerts = [];

  List<ParoleeTrackingSummary> get assignedParolees => _assignedParolees;
  ParoleeTrackingSummary? get activeTracking => _activeTracking;
  List<LocationRecord> get locationHistory => _locationHistory;
  bool get hasMoreHistory => _hasMoreHistory;
  bool get isLoading => _assignedLoading;
  bool get isParoleeLoading => _paroleeLoading;
  bool get isHistoryLoading => _historyLoading;
  String? get error => _assignedError;
  String? get paroleeError => _paroleeError;
  String? get historyError => _historyError;

  /// Recent in-session proximity entry alerts for officer UI.
  List<ProximityAlertEvent> get recentProximityAlerts =>
      List.unmodifiable(_recentProximityAlerts);

  ParoleeTrackingSummary? summaryForTracker(String trackerId) {
    for (final p in _assignedParolees) {
      if (p.tracker?.id == trackerId) return p;
    }
    return null;
  }

  ParoleeTrackingSummary? summaryForParolee(String paroleeId) {
    for (final p in _assignedParolees) {
      if (p.paroleeId == paroleeId) return p;
    }
    return null;
  }

  TrackingDashboardStats get dashboardStats {
    final active = _assignedParolees.where((p) => p.trackingStatus.isLive).length;
    final offline = _assignedParolees
        .where((p) => p.trackingStatus == TrackingStatus.offline)
        .length;
    return TrackingDashboardStats(
      totalAssigned: _assignedParolees.length,
      activeTrackers: active,
      offlineTrackers: offline,
      recentAlerts: offline + _recentProximityAlerts.length,
    );
  }

  void startWatchingAssigned({required AppUser requester, required String officerId}) {
    _assignedSub?.cancel();
    _assignedLoading = true;
    _assignedError = null;
    notifyListeners();

    _assignedSub = _repository
        .watchAssignedParolees(requester: requester, officerId: officerId)
        .listen(
      (list) {
        _assignedParolees = list;
        _assignedLoading = false;
        _assignedError = null;
        if (_latchesReady) {
          _checkAlerts(requester.id, list);
        }
        notifyListeners();
      },
      onError: (Object e) {
        _assignedError = e is TrackingAuthorizationException
            ? e.message
            : 'Unable to load tracking data';
        _assignedLoading = false;
        notifyListeners();
      },
    );

    unawaited(_finishHydrateAndReplayAlerts(officerId));
  }

  Future<void> _finishHydrateAndReplayAlerts(String officerId) async {
    await _hydrateLatches();
    if (_disposed) return;
    _latchesReady = true;
    if (_assignedParolees.isNotEmpty) {
      _checkAlerts(officerId, _assignedParolees);
      notifyListeners();
    }
  }

  void startWatchingParolee({
    required AppUser requester,
    required String paroleeId,
  }) {
    _trackingSub?.cancel();
    _paroleeLoading = true;
    _paroleeError = null;
    notifyListeners();

    _trackingSub = _repository
        .watchParoleeTracking(requester: requester, paroleeId: paroleeId)
        .listen(
      (summary) {
        _activeTracking = summary;
        _paroleeLoading = false;
        _paroleeError = null;
        notifyListeners();
      },
      onError: (Object e) {
        _paroleeError = e is TrackingAuthorizationException
            ? e.message
            : 'Unable to load tracking data';
        _paroleeLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> loadLocationHistory({
    required AppUser requester,
    required String paroleeId,
    DateTime? start,
    DateTime? end,
    bool append = false,
  }) async {
    _historyLoading = true;
    _historyError = null;
    if (!append) {
      _lastHistoryCursor = null;
    }
    notifyListeners();
    try {
      final records = await _repository.getLocationHistory(
        requester: requester,
        paroleeId: paroleeId,
        start: start,
        end: end,
        startAfterId: append ? _lastHistoryCursor : null,
      );
      if (append) {
        _locationHistory = [..._locationHistory, ...records];
      } else {
        _locationHistory = records;
      }
      _hasMoreHistory = records.length >= 50;
      if (records.isNotEmpty) {
        _lastHistoryCursor = records.last.id;
      }
    } on TrackingAuthorizationException catch (e) {
      _historyError = e.message;
    } catch (_) {
      _historyError = 'Unable to load location history';
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLocation({
    required AppUser requester,
    required String paroleeId,
  }) async {
    try {
      final location = await _repository.getLatestLocation(
        requester: requester,
        paroleeId: paroleeId,
      );
      if (_activeTracking != null && _activeTracking!.paroleeId == paroleeId) {
        _activeTracking = ParoleeTrackingSummary(
          paroleeId: _activeTracking!.paroleeId,
          fullName: _activeTracking!.fullName,
          caseNumber: _activeTracking!.caseNumber,
          officerId: _activeTracking!.officerId,
          trackingStatus: _activeTracking!.trackingStatus,
          tracker: _activeTracking!.tracker,
          latestLocation: location ?? _activeTracking!.latestLocation,
          geofenceStatus: _activeTracking!.geofenceStatus,
          geofences: _activeTracking!.geofences,
          checkInProximity: _activeTracking!.checkInProximity,
        );
        notifyListeners();
      }
    } catch (_) {
      _paroleeError = 'Unable to refresh location';
      notifyListeners();
    }
  }

  /// Call when a new attendance / check-in session begins for a parolee.
  void beginCheckInSession({
    required String paroleeId,
    String? locationId,
    String? sessionId,
  }) {
    _proximityNotifier.resetSession(
      paroleeId: paroleeId,
      clearAllForParolee: true,
    );
    _latchStore.persist(_proximityNotifier);
  }

  Future<void> _hydrateLatches() {
    return _hydrateFuture ??= _latchStore.hydrate(_proximityNotifier);
  }

  void stopWatchingParolee() {
    _trackingSub?.cancel();
    _trackingSub = null;
    _activeTracking = null;
    _paroleeLoading = false;
    _paroleeError = null;
    _locationHistory = [];
    notifyListeners();
  }

  void _checkAlerts(String officerId, List<ParoleeTrackingSummary> list) {
    for (final p in list) {
      final prev = _lastKnownStatus[p.paroleeId];
      final current = p.trackingStatus;
      final prevGeofence = _lastGeofenceStatus[p.paroleeId];
      final currentGeofence = p.geofenceStatus;

      if (prev != current) {
        final trackerId = p.tracker?.id ?? p.paroleeId;
        if (current == TrackingStatus.offline && prev != null) {
          _alerts.sendTrackerOffline(
            officerId: officerId,
            paroleeName: p.fullName,
            trackerId: trackerId,
            lastSeen: p.lastUpdated,
          );
        } else if (current == TrackingStatus.lowBattery) {
          _alerts.sendLowBattery(
            officerId: officerId,
            paroleeName: p.fullName,
            trackerId: trackerId,
            batteryLevel: p.batteryLevel ?? 0,
          );
        } else if (current == TrackingStatus.gpsUnavailable) {
          _alerts.sendGpsFailure(
            officerId: officerId,
            paroleeName: p.fullName,
            trackerId: trackerId,
          );
        }
        _lastKnownStatus[p.paroleeId] = current;
      }

      if (prevGeofence != currentGeofence &&
          currentGeofence == GeofenceStatus.outside &&
          prevGeofence != null) {
        _alerts.sendGeofenceViolation(
          officerId: officerId,
          paroleeName: p.fullName,
          trackerId: p.tracker?.id ?? p.paroleeId,
        );
      }
      _lastGeofenceStatus[p.paroleeId] = currentGeofence;

      _checkProximityAlert(officerId, p);
    }
  }

  void _checkProximityAlert(String officerId, ParoleeTrackingSummary p) {
    final proximity = p.checkInProximity;
    final eventKey = p.latestLocation?.id;
    final wasLatched = _proximityNotifier.isLatchedInside(
      paroleeId: p.paroleeId,
      locationId: proximity.locationId,
      sessionId: proximity.sessionId,
    );
    final shouldNotify = _proximityNotifier.shouldNotify(
      paroleeId: p.paroleeId,
      result: proximity,
      eventKey: eventKey,
    );
    if (!shouldNotify) {
      if (wasLatched && proximity.status == CheckInProximityStatus.outside) {
        _latchStore.persist(_proximityNotifier);
      }
      return;
    }

    final distance = proximity.distanceMeters ?? 0;
    _latchStore.persist(_proximityNotifier);
    unawaited(
      _alerts
          .sendCheckInProximity(
            officerId: officerId,
            paroleeName: p.fullName,
            paroleeId: p.paroleeId,
            trackerId: p.tracker?.id ?? p.paroleeId,
            distanceMeters: distance,
            locationName: proximity.locationName ?? 'Assigned check-in location',
            timestamp: proximity.evaluatedAt,
            isSimulated: proximity.isSimulated,
          )
          .catchError((_) {}),
    );

    _recentProximityAlerts.insert(
      0,
      ProximityAlertEvent(
        paroleeId: p.paroleeId,
        paroleeName: p.fullName,
        distanceMeters: distance,
        locationName: proximity.locationName ?? 'Assigned check-in location',
        timestamp: proximity.evaluatedAt ?? DateTime.now(),
        isSimulated: proximity.isSimulated,
      ),
    );
    if (_recentProximityAlerts.length > 20) {
      _recentProximityAlerts.removeLast();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _assignedSub?.cancel();
    _trackingSub?.cancel();
    _repository.dispose();
    super.dispose();
  }
}

/// In-session proximity entry alert for officer UI.
class ProximityAlertEvent {
  const ProximityAlertEvent({
    required this.paroleeId,
    required this.paroleeName,
    required this.distanceMeters,
    required this.locationName,
    required this.timestamp,
    this.isSimulated = false,
  });

  final String paroleeId;
  final String paroleeName;
  final double distanceMeters;
  final String locationName;
  final DateTime timestamp;
  final bool isSimulated;
}
