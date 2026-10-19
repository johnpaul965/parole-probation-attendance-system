import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/app_logger.dart';
import 'package:last/core/utils/date_utils.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/officer/models/dashboard_stats.dart';
import 'package:last/features/officer/models/parolee_summary.dart';
import 'package:last/features/shared/models/attendance_record.dart';
import 'package:last/features/shared/models/schedule_model.dart';
import 'package:last/core/services/live_stats_service.dart';
import 'package:last/core/utils/validators.dart';
import 'package:last/features/auth/models/supervision_period.dart';
import 'package:last/features/tracking/services/tracking_audit_service.dart';

class OfficerService {
  OfficerService({
    FirebaseFirestore? firestore,
    LiveStatsService? liveStatsService,
    TrackingAuditService? auditService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _liveStats = liveStatsService ?? LiveStatsService(),
        _audit = auditService ?? TrackingAuditService();

  final FirebaseFirestore _db;
  final LiveStatsService _liveStats;
  final TrackingAuditService _audit;

  Stream<DashboardSnapshot> watchDashboard(
    String officerId, {
    String? query,
    AttendanceStatus? filter,
  }) {
    if (!FirebaseConfig.canUseFirestore) {
      AppLogger.d('OfficerService', 'Firestore unavailable — empty dashboard');
      return Stream.value(const DashboardSnapshot(
        stats: DashboardStats(totalCases: 0, checkedIn: 0, pending: 0, missed: 0),
        parolees: [],
        schedules: [],
      ));
    }

    if (officerId.isEmpty) {
      return Stream.error(Exception('Officer ID is missing. Sign out and sign in again.'));
    }

    final controller = StreamController<DashboardSnapshot>();
    final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    Timer? debounce;
    var building = false;

    Future<void> emit() async {
      if (controller.isClosed || building) return;
      building = true;
      try {
        final snapshot = await _buildDashboard(
          officerId,
          query: query,
          filter: filter,
        );
        if (!controller.isClosed) {
          controller.add(snapshot);
        }
      } catch (e, st) {
        AppLogger.e('OfficerService', 'Dashboard build failed', e, st);
        if (!controller.isClosed) {
          controller.addError(_mapError(e));
        }
      } finally {
        building = false;
      }
    }

    void scheduleEmit() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 250), emit);
    }

    void attachListener(Stream<QuerySnapshot<Map<String, dynamic>>> stream) {
      subscriptions.add(
        stream.listen(
          (_) => scheduleEmit(),
          onError: (Object e, StackTrace st) {
            AppLogger.e('OfficerService', 'Firestore listener error', e, st);
            if (!controller.isClosed) controller.addError(_mapError(e));
          },
        ),
      );
    }

    attachListener(
      _db.collection(FirestoreCollections.users).where('officerId', isEqualTo: officerId).snapshots(),
    );
    attachListener(
      _db
          .collection(FirestoreCollections.users)
          .where('assignedOfficerId', isEqualTo: officerId)
          .snapshots(),
    );
    attachListener(
      _db.collection(FirestoreCollections.attendance).where('officerId', isEqualTo: officerId).snapshots(),
    );
    attachListener(
      _db.collection(FirestoreCollections.schedules).where('officerId', isEqualTo: officerId).snapshots(),
    );

    scheduleEmit();

    controller.onCancel = () async {
      debounce?.cancel();
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  Exception _mapError(Object e) {
    final msg = e.toString();
    if (msg.contains('permission-denied')) {
      return Exception(
        'Firestore permission denied. Deploy firestore.rules and ensure your user document has role: officer.',
      );
    }
    if (msg.contains('failed-precondition') || msg.contains('requires an index')) {
      return Exception(
        'Firestore index required. Open the link in the debug console or create composite indexes in Firebase Console.',
      );
    }
    if (msg.contains('unavailable')) {
      return Exception('Firestore is unavailable. Check your internet connection.');
    }
    return Exception(msg.replaceFirst('Exception: ', ''));
  }

  Future<DashboardSnapshot> _buildDashboard(
    String officerId, {
    String? query,
    AttendanceStatus? filter,
  }) async {
    final parolees = await getParolees(officerId, query: query, filter: filter);
    final schedules = await getSchedules(officerId);

    try {
      await _liveStats.publish(officerId, parolees);
    } catch (e, st) {
      AppLogger.e('OfficerService', 'live_stats publish failed (dashboard still loads)', e, st);
    }

    return DashboardSnapshot(
      stats: DashboardStats(
        totalCases: parolees.length,
        checkedIn: parolees
            .where((p) =>
                p.status == AttendanceStatus.checkedIn ||
                p.status == AttendanceStatus.confirmed)
            .length,
        pending: parolees.where((p) => p.status == AttendanceStatus.pending).length,
        missed: parolees.where((p) => p.status == AttendanceStatus.missed).length,
      ),
      parolees: parolees,
      schedules: schedules,
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchParoleeUserDocs(
    String officerId,
  ) async {
    final results = await Future.wait([
      _db.collection(FirestoreCollections.users).where('officerId', isEqualTo: officerId).get(),
      _db
          .collection(FirestoreCollections.users)
          .where('assignedOfficerId', isEqualTo: officerId)
          .get(),
    ]);

    final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snap in results) {
      for (final doc in snap.docs) {
        merged[doc.id] = doc;
      }
    }
    return merged.values.where((doc) {
      final role = doc.data()['role'] as String? ?? '';
      return role == 'parolee';
    }).toList();
  }

  Future<List<ParoleeSummary>> getParolees(
    String officerId, {
    String? query,
    AttendanceStatus? filter,
  }) async {
    final userDocs = await _fetchParoleeUserDocs(officerId);

    final attSnap = await _db
        .collection(FirestoreCollections.attendance)
        .where('officerId', isEqualTo: officerId)
        .get();

    final schSnap = await _db
        .collection(FirestoreCollections.schedules)
        .where('officerId', isEqualTo: officerId)
        .get();

    final allAttendance = <AttendanceRecord>[];
    for (final doc in attSnap.docs) {
      try {
        final data = doc.data();
        if (data['recordType'] == 'activity') continue;
        allAttendance.add(AttendanceRecord.fromMap({...data, 'id': doc.id}));
      } catch (e) {
        AppLogger.e('OfficerService', 'Skip invalid attendance doc ${doc.id}', e);
      }
    }

    final now = DateTime.now();
    final overdueSchedules = <ScheduleModel>[];
    for (final doc in schSnap.docs) {
      try {
        final s = ScheduleModel.fromMap({...doc.data(), 'id': doc.id});
        if (s.scheduledAt.isBefore(now)) overdueSchedules.add(s);
      } catch (e) {
        AppLogger.e('OfficerService', 'Skip invalid schedule doc ${doc.id}', e);
      }
    }

    var list = userDocs.map((d) {
      final data = d.data();
      final paroleeId = d.id;
      final status = _resolveStatus(paroleeId, allAttendance, overdueSchedules);
      final todayRecord = allAttendance
          .where((a) => a.paroleeId == paroleeId && AppDateUtils.isToday(a.checkInTime))
          .toList()
        ..sort((a, b) =>
            (b.checkInTime ?? DateTime(2000)).compareTo(a.checkInTime ?? DateTime(2000)));

      final supervision = SupervisionPeriod.compute(
        startRaw: data['supervisionStartDate'],
        endRaw: data['supervisionEndDate'],
        isSuspended: data['supervisionIsSuspended'] as bool? ?? false,
      );

      return ParoleeSummary(
        id: paroleeId,
        fullName: data['fullName'] as String? ?? 'Unknown',
        caseNumber: data['caseNumber'] as String? ?? 'N/A',
        status: status,
        officerId: officerId,
        lastCheckIn: todayRecord.isNotEmpty ? todayRecord.first.checkInTime : null,
        supervisionDatesMissing: supervision.hasMissingDates,
        supervisionShortLabel: supervision.shortLabel,
      );
    }).toList();

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where(
            (p) =>
                p.fullName.toLowerCase().contains(q) ||
                p.caseNumber.toLowerCase().contains(q),
          )
          .toList();
    }
    if (filter != null) {
      list = list.where((p) => p.status == filter).toList();
    }
    return list;
  }

  AttendanceStatus _resolveStatus(
    String paroleeId,
    List<AttendanceRecord> allAttendance,
    List<ScheduleModel> overdueSchedules,
  ) {
    final todayRecords = allAttendance.where(
      (a) => a.paroleeId == paroleeId && AppDateUtils.isToday(a.checkInTime),
    );
    if (todayRecords.any((r) =>
        r.status == AttendanceStatus.checkedIn ||
        r.status == AttendanceStatus.confirmed)) {
      return AttendanceStatus.checkedIn;
    }

    final missedSchedule = overdueSchedules.any((s) {
      if (s.paroleeId != paroleeId) return false;
      final hasCheckIn = allAttendance.any(
        (a) =>
            a.paroleeId == paroleeId &&
            AppDateUtils.isSameDay(a.checkInTime, s.scheduledAt),
      );
      return !hasCheckIn;
    });
    if (missedSchedule) return AttendanceStatus.missed;

    return AttendanceStatus.pending;
  }

  Future<List<ScheduleModel>> getSchedules(String officerId) async {
    try {
      final snap = await _db
          .collection(FirestoreCollections.schedules)
          .where('officerId', isEqualTo: officerId)
          .get();
      final list = <ScheduleModel>[];
      for (final doc in snap.docs) {
        try {
          list.add(ScheduleModel.fromMap({...doc.data(), 'id': doc.id}));
        } catch (e) {
          AppLogger.e('OfficerService', 'Skip invalid schedule ${doc.id}', e);
        }
      }
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return list.where((s) => s.scheduledAt.isAfter(DateTime.now())).toList();
    } catch (e, st) {
      AppLogger.e('OfficerService', 'getSchedules failed', e, st);
      return [];
    }
  }

  Future<AppUser?> getUserById(String id) async {
    final doc = await _db.collection(FirestoreCollections.users).doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromMap({...doc.data()!, 'id': doc.id});
  }

  Future<void> updateSupervisionPeriod({
    required String paroleeId,
    required DateTime start,
    required DateTime end,
    required bool isSuspended,
    required String actorId,
    required String actorRole,
  }) async {
    final rangeError = Validators.supervisionRange(start, end);
    if (rangeError != null) {
      throw Exception(rangeError);
    }

    final existing = await getUserById(paroleeId);
    if (existing == null) {
      throw Exception('Parolee not found.');
    }

    final startIso = SupervisionPeriod.formatIso(start);
    final endIso = SupervisionPeriod.formatIso(end);

    try {
      await _db.collection(FirestoreCollections.users).doc(paroleeId).update({
        'supervisionStartDate': startIso,
        'supervisionEndDate': endIso,
        'supervisionIsSuspended': isSuspended,
      });
    } catch (e) {
      throw Exception('Failed to save supervision dates: $e');
    }

    try {
      await _audit.logSupervisionPeriodUpdated(
        paroleeId: paroleeId,
        actorId: actorId,
        actorRole: actorRole,
        metadata: {
          'previousStart': existing.supervisionStartDate,
          'previousEnd': existing.supervisionEndDate,
          'previousSuspended': existing.supervisionIsSuspended,
          'start': startIso,
          'end': endIso,
          'suspended': isSuspended,
        },
      );
    } catch (e, st) {
      AppLogger.e('OfficerService', 'Supervision audit log failed', e, st);
    }
  }
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.stats,
    required this.parolees,
    required this.schedules,
  });

  final DashboardStats stats;
  final List<ParoleeSummary> parolees;
  final List<ScheduleModel> schedules;
}

OfficerService createOfficerService() => OfficerService();
