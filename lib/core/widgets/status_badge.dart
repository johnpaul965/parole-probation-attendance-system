import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/shared/models/attendance_record.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AttendanceStatus status;

  Color get _color {
    switch (status) {
      case AttendanceStatus.checkedIn:
      case AttendanceStatus.confirmed:
        return AppColors.success;
      case AttendanceStatus.pending:
        return AppColors.warning;
      case AttendanceStatus.missed:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
