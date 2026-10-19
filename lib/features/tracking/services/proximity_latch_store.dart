import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:last/features/tracking/services/check_in_proximity_notifier.dart';

/// Persists "already notified while inside" latches across app restarts.
class ProximityLatchStore {
  ProximityLatchStore({this.prefsKey = 'ppamts_check_in_proximity_latches'});

  final String prefsKey;

  Future<void> hydrate(CheckInProximityNotifier notifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        notifier.restoreLatched(decoded);
      }
    } catch (_) {
      // Persistence is best-effort; missing prefs must not block tracking.
    }
  }

  Future<void> persist(CheckInProximityNotifier notifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, jsonEncode(notifier.dumpLatched()));
    } catch (_) {}
  }
}
