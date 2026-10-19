import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:last/core/utils/app_logger.dart';
import 'package:last/features/activities/models/activity_attendance_record.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/models/activity_qr_payload.dart';
import 'package:last/features/activities/services/activity_attendance_service.dart';
import 'package:last/features/activities/services/activity_qr_service.dart';
import 'package:last/features/auth/models/app_user.dart';

class ActivityAttendanceProvider extends ChangeNotifier {
  ActivityAttendanceProvider({
    ActivityAttendanceService? attendanceService,
    ActivityQrService? qrService,
  })  : _attendanceService = attendanceService ?? ActivityAttendanceService(),
        _qrService = qrService ?? ActivityQrService();

  final ActivityAttendanceService _attendanceService;
  final ActivityQrService _qrService;

  List<ActivityAttendanceRecord> _records = [];
  ActivityAttendanceStats _stats = const ActivityAttendanceStats(
    present: 0,
    absent: 0,
    late: 0,
    pending: 0,
    total: 0,
  );
  final Map<String, ActivityQrPayload> _qrByActivity = {};
  String? _qrActivityId;
  bool _loading = false;
  bool _qrLoading = false;
  String? _error;
  String? _qrError;
  StreamSubscription<List<ActivityAttendanceRecord>>? _activitySub;
  StreamSubscription<List<ActivityAttendanceRecord>>? _paroleeSub;
  StreamSubscription<List<ActivityAttendanceRecord>>? _allSub;

  List<ActivityAttendanceRecord> get records => _records;
  ActivityAttendanceStats get stats => _stats;
  ActivityQrPayload? get currentQr =>
      _qrActivityId != null ? _qrByActivity[_qrActivityId] : null;
  bool get isLoading => _loading;
  bool get isQrLoading => _qrLoading;
  String? get error => _error;
  String? get qrError => _qrError;

  ActivityQrPayload? qrForActivity(String activityId) => _qrByActivity[activityId];

  ActivityAttendanceRecord? recordFor(String activityId, String paroleeId) {
    try {
      return _records.firstWhere(
        (r) => r.activityId == activityId && r.paroleeId == paroleeId,
      );
    } catch (_) {
      return null;
    }
  }

  void _cancelSubs() {
    _activitySub?.cancel();
    _paroleeSub?.cancel();
    _allSub?.cancel();
  }

  void listenForActivity(String activityId) {
    _cancelSubs();
    _activitySub = _attendanceService.watchForActivity(activityId).listen(
      (data) {
        _records = data;
        _stats = _computeStats(data);
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load attendance';
        notifyListeners();
      },
    );
  }

  void listenForParolee(String paroleeId) {
    _cancelSubs();
    _paroleeSub = _attendanceService.watchForParolee(paroleeId).listen(
      (data) {
        _records = data;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load attendance';
        notifyListeners();
      },
    );
  }

  void listenAll() {
    _cancelSubs();
    _allSub = _attendanceService.watchAll().listen(
      (data) {
        _records = data;
        _stats = _computeStats(data);
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load attendance';
        notifyListeners();
      },
    );
  }

  ActivityAttendanceStats _computeStats(List<ActivityAttendanceRecord> list) {
    return ActivityAttendanceStats(
      present: list.where((r) => r.status == ActivityParticipationStatus.present).length,
      absent: list.where((r) => r.status == ActivityParticipationStatus.absent).length,
      late: list.where((r) => r.status == ActivityParticipationStatus.late).length,
      pending: list.where((r) => r.status == ActivityParticipationStatus.pending).length,
      total: list.length,
    );
  }

  Future<ActivityQrPayload?> loadParoleeQr({
    required ActivityModel activity,
    required AppUser parolee,
    String? officerIdOverride,
    bool rotate = false,
  }) async {
    _qrActivityId = activity.id;
    _qrLoading = true;
    _qrError = null;
    notifyListeners();

    AppLogger.d('ActivityAttendanceProvider', 'loadParoleeQr', activity.id);

    try {
      final officerId = officerIdOverride ??
          (activity.assignedOfficerId.isNotEmpty
              ? activity.assignedOfficerId
              : parolee.officerId);

      final payload = await _qrService.generateForActivity(
        activity: activity,
        paroleeId: parolee.id,
        paroleeName: parolee.fullName,
        officerIdOverride: officerId,
        rotate: rotate,
      );

      _qrByActivity[activity.id] = payload;
      _qrError = null;
      AppLogger.d('ActivityAttendanceProvider', 'QR ready', payload.encode().length);
      return payload;
    } catch (e, st) {
      AppLogger.e('ActivityAttendanceProvider', 'loadParoleeQr failed', e, st);
      _qrError = e.toString().replaceFirst('ActivityQrException: ', '');
      _qrByActivity.remove(activity.id);
      return null;
    } finally {
      _qrLoading = false;
      notifyListeners();
    }
  }

  Future<ActivityScanResult> scanQr({
    required String rawQr,
    required AppUser officer,
    required ActivityModel activity,
    required ActivityParticipationStatus status,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _attendanceService.scanAndMark(
        rawQr: rawQr,
        officer: officer,
        expectedActivityId: activity.id,
        status: status,
        activity: activity,
      );
      if (!result.isSuccess) {
        _error = result.error;
      }
      return result;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelSubs();
    super.dispose();
  }
}
