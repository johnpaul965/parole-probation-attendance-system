import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/auth/models/supervision_period.dart';

class SupervisionPeriodCard extends StatelessWidget {
  const SupervisionPeriodCard({
    super.key,
    required this.snapshot,
    this.onEdit,
    this.compact = false,
    this.paroleeFacing = false,
  });

  final SupervisionSnapshot snapshot;
  final VoidCallback? onEdit;
  final bool compact;
  final bool paroleeFacing;

  static final _fmt = DateFormat('MMMM d, yyyy');

  String _dateLabel(DateTime? value) {
    if (value == null) {
      return paroleeFacing ? 'Not yet assigned by your officer' : 'Not set';
    }
    return _fmt.format(value);
  }

  Color get _statusColor {
    switch (snapshot.status) {
      case SupervisionStatus.active:
        return AppColors.success;
      case SupervisionStatus.upcoming:
        return AppColors.officer;
      case SupervisionStatus.completed:
        return AppColors.textMuted;
      case SupervisionStatus.suspended:
      case SupervisionStatus.invalid:
        return AppColors.error;
      case SupervisionStatus.notSet:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _row('Supervision Start Date', _dateLabel(snapshot.start)),
      _row('Supervision End Date', _dateLabel(snapshot.end)),
      _row(
        'Status',
        snapshot.label,
        valueColor: _statusColor,
      ),
      if (snapshot.status == SupervisionStatus.active && snapshot.remainingDays != null)
        _row(
          'Remaining Days',
          snapshot.remainingDays == 0 ? '0 (ends today)' : '${snapshot.remainingDays}',
        ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'SUPERVISION PERIOD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
              ],
            ),
            if (snapshot.hasMissingDates) ...[
              const SizedBox(height: 4),
              Text(
                snapshot.status == SupervisionStatus.invalid
                    ? 'End date is earlier than the start date. Update the dates.'
                    : (paroleeFacing
                        ? 'Your officer has not set supervision dates yet.'
                        : 'Dates are missing. Set a start and end date.'),
                style: TextStyle(fontSize: 12, color: _statusColor),
              ),
            ],
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 100 : 110,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
