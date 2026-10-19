import 'package:last/features/shared/models/attendance_record.dart';

class ChartPoint {
  const ChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class OfficerPerformance {
  const OfficerPerformance({
    required this.officerId,
    required this.officerName,
    required this.totalParolees,
    required this.checkIns,
    required this.missed,
    required this.complianceRate,
  });

  final String officerId;
  final String officerName;
  final int totalParolees;
  final int checkIns;
  final int missed;
  final double complianceRate;
}

class ReportData {
  const ReportData({
    required this.weeklyPoints,
    required this.monthlyPoints,
    required this.complianceRate,
    required this.attendancePercentage,
    required this.missedCount,
    required this.totalCheckIns,
    required this.pendingCount,
    required this.totalAttendance,
    required this.recentRecords,
    required this.officerPerformance,
    required this.generatedAt,
  });

  final List<ChartPoint> weeklyPoints;
  final List<ChartPoint> monthlyPoints;
  final double complianceRate;
  final double attendancePercentage;
  final int missedCount;
  final int totalCheckIns;
  final int pendingCount;
  final int totalAttendance;
  final List<AttendanceRecord> recentRecords;
  final List<OfficerPerformance> officerPerformance;
  final DateTime generatedAt;
}
