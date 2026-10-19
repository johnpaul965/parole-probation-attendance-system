import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/activities/models/activity_attendance_record.dart';

class ParticipationStatusChip extends StatelessWidget {
  const ParticipationStatusChip({super.key, required this.status});

  final ActivityParticipationStatus status;

  Color get _color {
    switch (status) {
      case ActivityParticipationStatus.present:
        return AppColors.success;
      case ActivityParticipationStatus.late:
        return AppColors.warning;
      case ActivityParticipationStatus.absent:
        return AppColors.error;
      case ActivityParticipationStatus.pending:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}
