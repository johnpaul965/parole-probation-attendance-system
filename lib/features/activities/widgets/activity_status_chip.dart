import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/activities/models/activity_model.dart';

class ActivityStatusChip extends StatelessWidget {
  const ActivityStatusChip({super.key, required this.status});

  final ActivityStatus status;

  Color get _color {
    switch (status) {
      case ActivityStatus.pending:
        return AppColors.warning;
      case ActivityStatus.ongoing:
        return AppColors.officer;
      case ActivityStatus.completed:
        return AppColors.success;
      case ActivityStatus.missed:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}
