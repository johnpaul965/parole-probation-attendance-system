import 'package:last/features/tracking/models/check_in_proximity.dart';

/// Edge-triggered proximity notification decisions.
///
/// Notifies once when a parolee enters the radius for a given check-in session.
/// Suppresses repeats while remaining inside. Resets after a reliable exit
/// (or when the session / check-in location changes).
class CheckInProximityNotifier {
  CheckInProximityNotifier({Map<String, ProximityEdgeState>? initialState})
      : _state = initialState ?? {};

  final Map<String, ProximityEdgeState> _state;

  /// Returns true only when an officer notification should be sent for this
  /// evaluation (enter event). Updates internal edge state.
  bool shouldNotify({
    required String paroleeId,
    required CheckInProximityResult result,
    String? eventKey,
  }) {
    final key = _stateKey(
      paroleeId: paroleeId,
      locationId: result.locationId,
      sessionId: result.sessionId,
    );
    final previous = _state[key];

    if (result.status != CheckInProximityStatus.inside) {
      if (result.status == CheckInProximityStatus.outside) {
        // Reliable exit — allow a future re-entry notification.
        _state[key] = ProximityEdgeState(
          isInside: false,
          hasNotified: false,
          lastEventKey: eventKey,
        );
      }
      // Invalid / unverified / unavailable: do not notify and do not reset
      // an active "inside + notified" latch (avoids spam from flaky GPS).
      return false;
    }

    // Duplicate device message with the same event key while already notified.
    if (previous != null &&
        previous.hasNotified &&
        previous.isInside &&
        eventKey != null &&
        previous.lastEventKey == eventKey) {
      return false;
    }

    if (previous != null && previous.isInside && previous.hasNotified) {
      // Still inside after a prior notification — no repeat.
      _state[key] = previous.copyWith(lastEventKey: eventKey);
      return false;
    }

    _state[key] = ProximityEdgeState(
      isInside: true,
      hasNotified: true,
      lastEventKey: eventKey,
    );
    return true;
  }

  /// Clears latch for a parolee (e.g. new check-in session started).
  ///
  /// Passing only [paroleeId] (or [clearAllForParolee] true) drops every
  /// location/session latch so the next qualifying entry can notify again.
  void resetSession({
    required String paroleeId,
    String? locationId,
    String? sessionId,
    bool clearAllForParolee = false,
  }) {
    if (clearAllForParolee || (locationId == null && sessionId == null)) {
      _state.removeWhere((k, _) => k.startsWith('$paroleeId|'));
      return;
    }
    _state.remove(_stateKey(
      paroleeId: paroleeId,
      locationId: locationId,
      sessionId: sessionId,
    ));
  }

  List<Map<String, String?>> dumpLatched() {
    return _state.entries
        .where((e) => e.value.isInside && e.value.hasNotified)
        .map((e) {
      final parts = e.key.split('|');
      return {
        'paroleeId': parts.isNotEmpty ? parts[0] : null,
        'locationId': parts.length > 1 && parts[1] != 'none' ? parts[1] : null,
        'sessionId': parts.length > 2 && parts[2] != 'none' ? parts[2] : null,
        'eventKey': e.value.lastEventKey,
      };
    }).toList();
  }

  void restoreLatched(List<dynamic> items) {
    for (final raw in items) {
      if (raw is! Map) continue;
      final paroleeId = raw['paroleeId'] as String?;
      if (paroleeId == null || paroleeId.isEmpty) continue;
      hydrateNotifiedInside(
        paroleeId: paroleeId,
        locationId: raw['locationId'] as String?,
        sessionId: raw['sessionId'] as String?,
        eventKey: raw['eventKey'] as String?,
      );
    }
  }

  /// Restores a persisted "already notified while inside" latch (app restart).
  void hydrateNotifiedInside({
    required String paroleeId,
    String? locationId,
    String? sessionId,
    String? eventKey,
  }) {
    final key = _stateKey(
      paroleeId: paroleeId,
      locationId: locationId,
      sessionId: sessionId,
    );
    _state[key] = ProximityEdgeState(
      isInside: true,
      hasNotified: true,
      lastEventKey: eventKey,
    );
  }

  bool isLatchedInside({
    required String paroleeId,
    String? locationId,
    String? sessionId,
  }) {
    final s = _state[_stateKey(
      paroleeId: paroleeId,
      locationId: locationId,
      sessionId: sessionId,
    )];
    return s != null && s.isInside && s.hasNotified;
  }

  String _stateKey({
    required String paroleeId,
    String? locationId,
    String? sessionId,
  }) =>
      '$paroleeId|${locationId ?? 'none'}|${sessionId ?? 'none'}';
}

class ProximityEdgeState {
  const ProximityEdgeState({
    required this.isInside,
    required this.hasNotified,
    this.lastEventKey,
  });

  final bool isInside;
  final bool hasNotified;
  final String? lastEventKey;

  ProximityEdgeState copyWith({
    bool? isInside,
    bool? hasNotified,
    String? lastEventKey,
  }) {
    return ProximityEdgeState(
      isInside: isInside ?? this.isInside,
      hasNotified: hasNotified ?? this.hasNotified,
      lastEventKey: lastEventKey ?? this.lastEventKey,
    );
  }
}
