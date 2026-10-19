import 'package:flutter/foundation.dart';
import 'package:last/features/tracking/services/phone_location_service.dart';

class PhoneLocationProvider extends ChangeNotifier {
  PhoneLocationProvider() {
    _service.onUpdate = notifyListeners;
  }

  final PhoneLocationService _service = PhoneLocationService.instance;

  bool _busy = false;
  String? _error;

  bool get isSharing => _service.isSharing;
  bool get isBusy => _busy;
  String? get error => _error ?? _service.lastError;
  DateTime? get lastSentAt => _service.lastSentAt;

  Future<void> setSharing({required bool enabled, required String paroleeId}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if (enabled) {
        await _service.start(paroleeId);
      } else {
        _service.stop();
      }
    } catch (e) {
      _service.stop();
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void stop() {
    _service.stop();
    _error = null;
    notifyListeners();
  }
}
