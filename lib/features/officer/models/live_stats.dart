import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/features/officer/models/dashboard_stats.dart';
import 'package:last/features/officer/models/parolee_summary.dart';
import 'package:last/features/shared/models/attendance_record.dart';

class LiveStats {
  const LiveStats({
    required this.stats,
    required this.checkedIn,
    required this.pending,
    required this.missed,
    required this.updatedAt,
  });

  final DashboardStats stats;
  final List<ParoleeSummary> checkedIn;
  final List<ParoleeSummary> pending;
  final List<ParoleeSummary> missed;
  final DateTime? updatedAt;

  factory LiveStats.fromDashboard(List<ParoleeSummary> all, {DateTime? updatedAt}) {
    final checkedIn = all
        .where((p) =>
            p.status == AttendanceStatus.checkedIn ||
            p.status == AttendanceStatus.confirmed)
        .toList();
    final pending = all.where((p) => p.status == AttendanceStatus.pending).toList();
    final missed = all.where((p) => p.status == AttendanceStatus.missed).toList();
    return LiveStats(
      stats: DashboardStats(
        totalCases: all.length,
        checkedIn: checkedIn.length,
        pending: pending.length,
        missed: missed.length,
      ),
      checkedIn: checkedIn,
      pending: pending,
      missed: missed,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory LiveStats.fromMap(Map<String, dynamic> map) {
    List<ParoleeSummary> parseList(String key) {
      final raw = map[key] as List<dynamic>? ?? [];
      return raw.map((e) {
        final m = e as Map<String, dynamic>;
        return ParoleeSummary(
          id: m['id'] as String? ?? '',
          fullName: m['fullName'] as String? ?? '',
          caseNumber: m['caseNumber'] as String? ?? '',
          status: AttendanceStatus.fromString(m['status'] as String? ?? 'pending'),
          officerId: m['officerId'] as String? ?? '',
        );
      }).toList();
    }

    return LiveStats(
      stats: DashboardStats(
        totalCases: map['totalCases'] as int? ?? 0,
        checkedIn: map['checkedIn'] as int? ?? 0,
        pending: map['pending'] as int? ?? 0,
        missed: map['missed'] as int? ?? 0,
      ),
      checkedIn: parseList('checkedInList'),
      pending: parseList('pendingList'),
      missed: parseList('missedList'),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'totalCases': stats.totalCases,
        'checkedIn': stats.checkedIn,
        'pending': stats.pending,
        'missed': stats.missed,
        'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
        'checkedInList': _serialize(checkedIn),
        'pendingList': _serialize(pending),
        'missedList': _serialize(missed),
      };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static List<Map<String, dynamic>> _serialize(List<ParoleeSummary> list) {
    return list
        .map((p) => {
              'id': p.id,
              'fullName': p.fullName,
              'caseNumber': p.caseNumber,
              'status': p.status.name,
              'officerId': p.officerId,
            })
        .toList();
  }
}
