import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/activities/models/activity_attendance_record.dart';
import 'package:last/features/activities/widgets/participation_status_chip.dart';

class ActivityAttendancePanel extends StatelessWidget {
  const ActivityAttendancePanel({
    super.key,
    required this.records,
    required this.stats,
    required this.assignedParoleeIds,
    this.paroleeNames,
  });

  final List<ActivityAttendanceRecord> records;
  final ActivityAttendanceStats stats;
  final List<String> assignedParoleeIds;
  final Map<String, String>? paroleeNames;

  @override
  Widget build(BuildContext context) {
    final notPresentIds = assignedParoleeIds
        .where((id) => !records.any((r) => r.paroleeId == id && r.status.countsAsPresent))
        .toList();
    final absentCount = records.where((r) => r.status == ActivityParticipationStatus.absent).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _counter('Present', stats.present, AppColors.success),
            const SizedBox(width: 8),
            _counter('Late', stats.late, AppColors.warning),
            const SizedBox(width: 8),
            _counter('Absent', absentCount + notPresentIds.length, AppColors.error),
          ],
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          const Text(
            'No attendance scanned yet. Use QR scanner to mark parolees.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          )
        else
          ...records.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.officer.withValues(alpha: 0.1),
                  child: Text(
                    r.paroleeName.isNotEmpty ? r.paroleeName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                title: Text(r.paroleeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(
                  'Scanned ${r.scannedAt.toLocal().toString().substring(0, 16)}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: ParticipationStatusChip(status: r.status),
              ),
            ),
          ),
        if (notPresentIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Not yet present', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          ...notPresentIds.map(
            (id) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                paroleeNames?[id] ?? id,
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _counter(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}
