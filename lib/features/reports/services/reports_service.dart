import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/error_handler.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/core/utils/date_utils.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/reports/models/report_data.dart';
import 'package:last/features/shared/models/attendance_record.dart';

abstract class ReportsService {
  Future<ReportData> getReportData({String? officerId});
  Stream<ReportData> watchReportData({String? officerId});
}

class FirebaseReportsService implements ReportsService {
  FirebaseReportsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<ReportData> watchReportData({String? officerId}) {
    if (!FirebaseConfig.canUseFirestore) {
      return Stream.value(_emptyReport());
    }
    Query<Map<String, dynamic>> query = _db.collection(FirestoreCollections.attendance);
    if (officerId != null) {
      query = query.where('officerId', isEqualTo: officerId);
    }
    return query.snapshots().asyncMap((_) => getReportData(officerId: officerId));
  }

  ReportData _emptyReport() => ReportData(
        weeklyPoints: const [],
        monthlyPoints: const [],
        complianceRate: 0,
        attendancePercentage: 0,
        missedCount: 0,
        totalCheckIns: 0,
        pendingCount: 0,
        totalAttendance: 0,
        recentRecords: const [],
        officerPerformance: const [],
        generatedAt: DateTime.now(),
      );

  @override
  Future<ReportData> getReportData({String? officerId}) async {
    if (!FirebaseConfig.canUseFirestore) return _emptyReport();
    try {
    Query<Map<String, dynamic>> query = _db.collection(FirestoreCollections.attendance);
    if (officerId != null) {
      query = query.where('officerId', isEqualTo: officerId);
    }
    final attSnap = await query.get();
    var records = attSnap.docs
        .map((d) => AttendanceRecord.fromMap({...d.data(), 'id': d.id}))
        .toList();

    final usersSnap = await _db.collection(FirestoreCollections.users).get();
    final users = usersSnap.docs.map((d) => AppUser.fromMap({...d.data(), 'id': d.id})).toList();
    var parolees = users.where((u) => u.role == UserRole.parolee).toList();
    if (officerId != null) {
      parolees = parolees.where((p) => p.officerId == officerId).toList();
    }

    final checkedIn = records
        .where((r) =>
            r.status == AttendanceStatus.checkedIn ||
            r.status == AttendanceStatus.confirmed)
        .length;
    final missed = records.where((r) => r.status == AttendanceStatus.missed).length;
    final total = records.length;

    final todayCheckedParolees = records
        .where((r) => AppDateUtils.isToday(r.checkInTime))
        .map((r) => r.paroleeId)
        .toSet();
    final pending = parolees.where((p) => !todayCheckedParolees.contains(p.id)).length;

    final complianceRate = total == 0 ? 0.0 : ((total - missed) / total) * 100;
    final attendancePct =
        parolees.isEmpty ? 0.0 : (todayCheckedParolees.length / parolees.length) * 100;

    return ReportData(
      weeklyPoints: _buildWeeklyPoints(records),
      monthlyPoints: _buildMonthlyPoints(records),
      complianceRate: complianceRate,
      attendancePercentage: attendancePct,
      missedCount: missed,
      totalCheckIns: checkedIn,
      pendingCount: pending,
      totalAttendance: total,
      recentRecords: records.take(20).toList(),
      officerPerformance: await _buildOfficerPerformance(users, records),
      generatedAt: DateTime.now(),
    );
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to generate report');
    }
  }

  List<ChartPoint> _buildWeeklyPoints(List<AttendanceRecord> records) {
    final now = DateTime.now();
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final points = <ChartPoint>[];

    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final count = records.where((r) {
        final t = r.checkInTime;
        return t != null && AppDateUtils.isSameDay(t, day);
      }).length;
      points.add(ChartPoint(label: labels[day.weekday - 1], value: count.toDouble()));
    }
    return points;
  }

  List<ChartPoint> _buildMonthlyPoints(List<AttendanceRecord> records) {
    final now = DateTime.now();
    final fmt = DateFormat('MMM');
    final points = <ChartPoint>[];

    for (var i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final count = records.where((r) {
        final t = r.checkInTime ?? r.scheduledTime;
        return t != null && t.year == month.year && t.month == month.month;
      }).length;
      points.add(ChartPoint(label: fmt.format(month), value: count.toDouble()));
    }
    return points;
  }

  Future<List<OfficerPerformance>> _buildOfficerPerformance(
    List<AppUser> users,
    List<AttendanceRecord> records,
  ) async {
    final officers = users.where((u) => u.role == UserRole.officer).toList();
    final performance = <OfficerPerformance>[];

    for (final officer in officers) {
      final officerRecords = records.where((r) => r.officerId == officer.id).toList();
      final paroleeCount =
          users.where((u) => u.role == UserRole.parolee && u.officerId == officer.id).length;
      final checkIns = officerRecords
          .where((r) =>
              r.status == AttendanceStatus.checkedIn ||
              r.status == AttendanceStatus.confirmed)
          .length;
      final missed = officerRecords.where((r) => r.status == AttendanceStatus.missed).length;
      final total = officerRecords.length;
      final rate = total == 0 ? 0.0 : ((total - missed) / total) * 100;

      performance.add(OfficerPerformance(
        officerId: officer.id,
        officerName: officer.fullName,
        totalParolees: paroleeCount,
        checkIns: checkIns,
        missed: missed,
        complianceRate: rate,
      ));
    }
    return performance;
  }
}

ReportsService createReportsService() => FirebaseReportsService();
