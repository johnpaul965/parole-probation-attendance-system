import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/status_badge.dart';
import 'package:last/features/officer/models/parolee_summary.dart';
import 'package:last/features/shared/models/attendance_record.dart';

class LiveAttendancePanel extends StatelessWidget {
  const LiveAttendancePanel({
    super.key,
    required this.totalCases,
    required this.checkedIn,
    required this.pending,
    required this.missed,
    required this.checkedInList,
    required this.pendingList,
    required this.missedList,
    this.lastUpdated,
    this.onFilterTap,
  });

  final int totalCases;
  final int checkedIn;
  final int pending;
  final int missed;
  final List<ParoleeSummary> checkedInList;
  final List<ParoleeSummary> pendingList;
  final List<ParoleeSummary> missedList;
  final DateTime? lastUpdated;
  final void Function(AttendanceStatus? status)? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'LIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            if (lastUpdated != null)
              Text(
                'Updated ${DateFormat('h:mm:ss a').format(lastUpdated!)}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _StatusSection(
          title: 'Checked in ($checkedIn)',
          color: AppColors.success,
          icon: Icons.check_circle_outline,
          parolees: checkedInList,
          onTap: () => onFilterTap?.call(AttendanceStatus.checkedIn),
        ),
        const SizedBox(height: 8),
        _StatusSection(
          title: 'Pending ($pending)',
          color: AppColors.warning,
          icon: Icons.schedule,
          parolees: pendingList,
          onTap: () => onFilterTap?.call(AttendanceStatus.pending),
        ),
        const SizedBox(height: 8),
        _StatusSection(
          title: 'Missed ($missed)',
          color: AppColors.error,
          icon: Icons.warning_amber_outlined,
          parolees: missedList,
          onTap: () => onFilterTap?.call(AttendanceStatus.missed),
        ),
        const SizedBox(height: 6),
        Text(
          'Total cases: $totalCases',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.officer,
          ),
        ),
      ],
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.title,
    required this.color,
    required this.icon,
    required this.parolees,
    this.onTap,
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<ParoleeSummary> parolees;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                ],
              ),
              const SizedBox(height: 8),
              if (parolees.isEmpty)
                Text(
                  'No one in this group',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.8)),
                )
              else
                ...parolees.take(5).map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.fullName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  Text(p.caseNumber, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            StatusBadge(status: p.status),
                          ],
                        ),
                      ),
                    ),
              if (parolees.length > 5)
                Text(
                  '+${parolees.length - 5} more',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
