import 'package:last/features/shared/models/attendance_record.dart';

class ParoleeSummary {
  const ParoleeSummary({
    required this.id,
    required this.fullName,
    required this.caseNumber,
    required this.status,
    required this.officerId,
    this.lastCheckIn,
    this.supervisionDatesMissing = false,
    this.supervisionShortLabel,
  });

  final String id;
  final String fullName;
  final String caseNumber;
  final AttendanceStatus status;
  final String officerId;
  final DateTime? lastCheckIn;
  final bool supervisionDatesMissing;
  final String? supervisionShortLabel;
}
