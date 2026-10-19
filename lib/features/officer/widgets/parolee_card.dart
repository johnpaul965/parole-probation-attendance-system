import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/status_badge.dart';
import 'package:last/features/officer/models/parolee_summary.dart';
import 'package:intl/intl.dart';

class ParoleeCard extends StatelessWidget {
  const ParoleeCard({super.key, required this.parolee, this.onTap});

  final ParoleeSummary parolee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initials = parolee.fullName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.officer.withValues(alpha: 0.12),
                foregroundColor: AppColors.officer,
                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parolee.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(parolee.caseNumber, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    if (parolee.lastCheckIn != null)
                      Text(
                        'Last: ${DateFormat('MMM d, h:mm a').format(parolee.lastCheckIn!)}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    if (parolee.supervisionDatesMissing)
                      const Text(
                        'Supervision dates missing or invalid',
                        style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600),
                      )
                    else if (parolee.supervisionShortLabel != null)
                      Text(
                        'Supervision: ${parolee.supervisionShortLabel}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              StatusBadge(status: parolee.status),
            ],
          ),
        ),
      ),
    );
  }
}
