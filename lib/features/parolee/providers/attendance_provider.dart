import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/parolee/services/attendance_service.dart';
import 'package:last/features/shared/models/attendance_record.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider({AttendanceService? service})
      : _service = service ?? createAttendanceService();

  final AttendanceService _service;
  List<AttendanceRecord> _records = [];
  AttendanceRecord? _activeTicket;
  bool _loading = false;
  String? _error;
  StreamSubscription<List<AttendanceRecord>>? _sub;

  List<AttendanceRecord> get records => _records;
  AttendanceRecord? get activeTicket => _activeTicket;
  bool get isLoading => _loading;
  String? get error => _error;

  void watch({String? officerId, String? paroleeId}) {
    _sub?.cancel();
    _sub = _service.watchAttendance(officerId: officerId, paroleeId: paroleeId).listen(
      (data) {
        _records = data;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> load({String? officerId, String? paroleeId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _records = await _service.getAttendance(officerId: officerId, paroleeId: paroleeId);
    } catch (e) {
      _error = 'Failed to load attendance';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AttendanceRecord?> checkIn(AppUser parolee, {String? location}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _activeTicket = await _service.createCheckIn(parolee, location: location);
      return _activeTicket;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AttendanceRecord?> verifyQr(String payload, AppUser officer) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.verifyQr(payload, officer);
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
