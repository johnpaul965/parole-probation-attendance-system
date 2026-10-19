import 'package:flutter/material.dart';
import 'package:last/features/auth/models/supervision_period.dart';

class SupervisionPeriodCard extends StatelessWidget {
  const SupervisionPeriodCard({
    super.key,
    required this.snapshot,
    this.paroleeFacing = false,
    this.compact = false,
    this.onEdit,
  });

  final SupervisionSnapshot snapshot;
  final bool paroleeFacing;
  final bool compact;
  final VoidCallback? onEdit;

  Color _statusColor(BuildContext context) {
    switch (snapshot.status) {
      case SupervisionStatus.active:
        return Colors.green;
      case SupervisionStatus.completed:
        return Colors.blue;
      case SupervisionStatus.suspended:
        return Colors.red;
      case SupervisionStatus.upcoming:
        return Colors.orange;
      case SupervisionStatus.notSet:
      case SupervisionStatus.invalid:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    final startStr = snapshot.start != null
        ? SupervisionPeriod.formatIso(snapshot.start!)
        : 'Not set';
    final endStr = snapshot.end != null
        ? SupervisionPeriod.formatIso(snapshot.end!)
        : 'Not set';

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              'Supervision: ${snapshot.shortLabel}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 20, color: color),
                    const SizedBox(width: 8),
                    const Text(
                      'Supervision Period',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                    tooltip: 'Edit dates',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                snapshot.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Date',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        startStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Date',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        endStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (snapshot.remainingDays != null && snapshot.remainingDays! >= 0) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: snapshot.start != null && snapshot.end != null
                    ? (DateTime.now().difference(snapshot.start!).inDays /
                            (snapshot.end!.difference(snapshot.start!).inDays <= 0
                                ? 1
                                : snapshot.end!.difference(snapshot.start!).inDays))
                        .clamp(0.0, 1.0)
                    : null,
                color: color,
                backgroundColor: color.withOpacity(0.2),
              ),
              const SizedBox(height: 4),
              Text(
                '${snapshot.remainingDays} days remaining',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
