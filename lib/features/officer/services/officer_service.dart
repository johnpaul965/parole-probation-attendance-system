import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/app_logger.dart';
import 'package:last/core/utils/date_utils.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/core/utils/supabase_config.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
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
  })  : _db = firestore ?? _safeInitFirestore(),
        _liveStats = liveStatsService ?? LiveStatsService(),
        _audit = auditService ?? TrackingAuditService();

  static FirebaseFirestore? _safeInitFirestore() {
    if (!FirebaseConfig.canUseFirestore) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final FirebaseFirestore? _db;
  final LiveStatsService _liveStats;
  final TrackingAuditService _audit;

  bool get _hasFirestore => _db != null && FirebaseConfig.canUseFirestore;

  Stream<DashboardSnapshot> watchDashboard(
    String officerId, {
    String? query,
    AttendanceStatus? filter,
  }) {
    if (officerId.isEmpty) {
      return Stream.error(Exception('Officer ID is missing. Sign out and sign in again.'));
    }

    final db = _db;
    if (db == null || !_hasFirestore) {
      AppLogger.d('OfficerService', 'Firestore unavailable – building dashboard from Supabase/offline');
      final controller = StreamController<DashboardSnapshot>();
      Future<void> emitOffline() async {
        try {
          final snapshot = await _buildDashboard(
            officerId,
            query: query,
            filter: filter,
          );
          if (!controller.isClosed) controller.add(snapshot);
        } catch (e, st) {
          AppLogger.e('OfficerService', 'Offline dashboard build failed', e, st);
          if (!controller.isClosed) {
            controller.add(_buildDemoSnapshot(officerId, query: query, filter: filter));
          }
        }
      }
      emitOffline();
      return controller.stream;
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
      db.collection(FirestoreCollections.users).where('officerId', isEqualTo: officerId).snapshots(),
    );
    attachListener(
      db.collection(FirestoreCollections.users).where('assignedOfficerId', isEqualTo: officerId).snapshots(),
    );
    attachListener(
      db.collection(FirestoreCollections.attendance).where('officerId', isEqualTo: officerId).snapshots(),
    );
    attachListener(
      db.collection(FirestoreCollections.schedules).where('officerId', isEqualTo: officerId).snapshots(),
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
    final db = _db;
    if (db == null || !_hasFirestore) return [];
    try {
      final results = await Future.wait([
        db.collection(FirestoreCollections.users).where('officerId', isEqualTo: officerId).get(),
        db.collection(FirestoreCollections.users).where('assignedOfficerId', isEqualTo: officerId).get(),
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
    } catch (e, st) {
      AppLogger.e('OfficerService', '_fetchParoleeUserDocs error', e, st);
      return [];
    }
  }

  Future<List<ParoleeSummary>> getParolees(
    String officerId, {
    String? query,
    AttendanceStatus? filter,
  }) async {
    final db = _db;
    if (db != null && _hasFirestore) {
      try {
        final userDocs = await _fetchParoleeUserDocs(officerId);
        final attSnap = await db
            .collection(FirestoreCollections.attendance)
            .where('officerId', isEqualTo: officerId)
            .get();
        final schSnap = await db
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

        final list = userDocs.map((d) {
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

        return _filterParolees(list, query: query, filter: filter);
      } catch (e, st) {
        AppLogger.e('OfficerService', 'Firestore getParolees failed, falling back to Supabase/demo', e, st);
      }
    }

    // Supabase fallback
    if (SupabaseConfig.isConfigured) {
      try {
        final client = SupabaseConfig.client;
        final rows = await client.from('users').select().eq('role', 'parolee');
        if (rows is List && rows.isNotEmpty) {
          final list = rows.map((r) {
            final id = r['id']?.toString() ?? '';
            final statusStr = r['status']?.toString() ?? 'pending';
            final status = AttendanceStatus.fromString(statusStr);
            return ParoleeSummary(
              id: id,
              fullName: r['full_name']?.toString() ?? r['fullName']?.toString() ?? 'Parolee',
              caseNumber: r['case_number']?.toString() ?? r['caseNumber']?.toString() ?? 'PP-2024-0000',
              status: status,
              officerId: officerId,
              lastCheckIn: r['last_check_in'] != null ? DateTime.tryParse(r['last_check_in'].toString()) : null,
              supervisionDatesMissing: false,
              supervisionShortLabel: 'Supervised',
            );
          }).toList();
          return _filterParolees(list, query: query, filter: filter);
        }
      } catch (_) {}
    }

    // Default offline/demo roster
    final demoList = _getDemoParolees(officerId);
    return _filterParolees(demoList, query: query, filter: filter);
  }

  List<ParoleeSummary> _getDemoParolees(String officerId) {
    return [
      ParoleeSummary(
        id: 'demo-parolee',
        fullName: 'Juan Dela Cruz',
        caseNumber: 'PP-2024-1847',
        status: AttendanceStatus.checkedIn,
        officerId: officerId,
        lastCheckIn: DateTime.now().subtract(const Duration(minutes: 35)),
        supervisionDatesMissing: false,
        supervisionShortLabel: 'Active • Good Standing',
      ),
      ParoleeSummary(
        id: 'parolee-2',
        fullName: 'Carlos Mendoza',
        caseNumber: 'PP-2024-2103',
        status: AttendanceStatus.pending,
        officerId: officerId,
        lastCheckIn: DateTime.now().subtract(const Duration(days: 2)),
        supervisionDatesMissing: false,
        supervisionShortLabel: 'Active • Report Due Today',
      ),
      ParoleeSummary(
        id: 'parolee-3',
        fullName: 'Roberto Santos',
        caseNumber: 'PP-2024-1922',
        status: AttendanceStatus.missed,
        officerId: officerId,
        lastCheckIn: DateTime.now().subtract(const Duration(days: 5)),
        supervisionDatesMissing: false,
        supervisionShortLabel: 'Overdue • Violation Notice',
      ),
      ParoleeSummary(
        id: 'parolee-4',
        fullName: 'Maria Elena Cruz',
        caseNumber: 'PP-2024-2451',
        status: AttendanceStatus.checkedIn,
        officerId: officerId,
        lastCheckIn: DateTime.now().subtract(const Duration(hours: 3)),
        supervisionDatesMissing: false,
        supervisionShortLabel: 'Active • Good Standing',
      ),
    ];
  }

  List<ParoleeSummary> _filterParolees(
    List<ParoleeSummary> input, {
    String? query,
    AttendanceStatus? filter,
  }) {
    var list = input;
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

  DashboardSnapshot _buildDemoSnapshot(
    String officerId, {
    String? query,
    AttendanceStatus? filter,
  }) {
    final parolees = _filterParolees(_getDemoParolees(officerId), query: query, filter: filter);
    final schedules = [
      ScheduleModel(
        id: 'sch-1',
        paroleeId: 'demo-parolee',
        paroleeName: 'Juan Dela Cruz',
        officerId: officerId,
        scheduledAt: DateTime.now().add(const Duration(hours: 4)),
        type: 'Mandatory Check-in',
        notes: 'Monthly compliance interview',
        location: 'Tacloban City PPO',
      ),
      ScheduleModel(
        id: 'sch-2',
        paroleeId: 'parolee-2',
        paroleeName: 'Maria Santos',
        officerId: officerId,
        scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
        type: 'Community Service Review',
        notes: 'Tacloban City Hall beautification check',
        location: 'Tacloban City Hall',
      ),
    ];
    return DashboardSnapshot(
      stats: DashboardStats(
        totalCases: parolees.length,
        checkedIn: parolees.where((p) => p.status == AttendanceStatus.checkedIn || p.status == AttendanceStatus.confirmed).length,
        pending: parolees.where((p) => p.status == AttendanceStatus.pending).length,
        missed: parolees.where((p) => p.status == AttendanceStatus.missed).length,
      ),
      parolees: parolees,
      schedules: schedules,
    );
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
    final db = _db;
    if (db == null || !_hasFirestore) {
      return [
        ScheduleModel(
          id: 'sch-1',
          paroleeId: 'demo-parolee',
          paroleeName: 'Juan Dela Cruz',
          officerId: officerId,
          scheduledAt: DateTime.now().add(const Duration(hours: 4)),
          type: 'Mandatory Check-in',
          notes: 'Monthly compliance interview',
          location: 'Tacloban City PPO',
        ),
        ScheduleModel(
          id: 'sch-2',
          paroleeId: 'parolee-2',
          paroleeName: 'Maria Santos',
          officerId: officerId,
          scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
          type: 'Community Service Review',
          notes: 'Tacloban City Hall beautification check',
          location: 'Tacloban City Hall',
        ),
      ];
    }
    try {
      final snap = await db
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
    final db = _db;
    if (db != null && _hasFirestore) {
      try {
        final doc = await db.collection(FirestoreCollections.users).doc(id).get();
        if (doc.exists && doc.data() != null) {
          return AppUser.fromMap({...doc.data()!, 'id': doc.id});
        }
      } catch (e) {
        AppLogger.e('OfficerService', 'getUserById firestore error', e);
      }
    }

    if (SupabaseConfig.isConfigured) {
      try {
        final res = await SupabaseConfig.client.from('users').select().eq('id', id).maybeSingle();
        if (res != null) {
          return AppUser(
            id: res['id']?.toString() ?? id,
            email: res['email']?.toString() ?? '',
            fullName: res['full_name']?.toString() ?? res['name']?.toString() ?? 'User',
            role: UserRole.fromString(res['role']?.toString() ?? 'parolee'),
            caseNumber: res['case_number']?.toString(),
            officerId: res['officer_id']?.toString(),
            department: res['department']?.toString(),
          );
        }
      } catch (_) {}
    }

    if (id == 'demo-officer') {
      return AppUser(
        id: 'demo-officer',
        email: 'officer@ppa.gov.ph',
        fullName: 'Maria Santos',
        role: UserRole.officer,
        department: 'District 4 - Tacloban',
      );
    }
    if (id == 'demo-parolee') {
      return AppUser(
        id: 'demo-parolee',
        email: 'parolee@ppa.gov.ph',
        fullName: 'Juan Dela Cruz',
        role: UserRole.parolee,
        caseNumber: 'PP-2024-1847',
        officerId: 'demo-officer',
      );
    }
    return null;
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

    final db = _db;
    if (db != null && _hasFirestore) {
      try {
        await db.collection(FirestoreCollections.users).doc(paroleeId).update({
          'supervisionStartDate': startIso,
          'supervisionEndDate': endIso,
          'supervisionIsSuspended': isSuspended,
        });
      } catch (e) {
        throw Exception('Failed to save supervision dates: $e');
      }
    } else if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client.from('users').update({
          'supervision_start_date': startIso,
          'supervision_end_date': endIso,
          'supervision_is_suspended': isSuspended,
        }).eq('id', paroleeId);
      } catch (_) {}
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
