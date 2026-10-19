import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/parolee_tracking_summary.dart';
import 'package:last/features/tracking/widgets/battery_indicator.dart';
import 'package:last/features/tracking/widgets/check_in_proximity_badge.dart';
import 'package:last/features/tracking/widgets/gps_accuracy_indicator.dart';
import 'package:last/features/tracking/widgets/tracking_status_badge.dart';

class ParoleeTrackingCard extends StatelessWidget {
  const ParoleeTrackingCard({
    super.key,
    required this.summary,
    this.onTrack,
  });

  final ParoleeTrackingSummary summary;
  final VoidCallback? onTrack;

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'No updates';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds} seconds ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(summary.caseNumber, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                TrackingStatusBadge(status: summary.trackingStatus),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Last update: ${_timeAgo(summary.lastUpdated)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                BatteryIndicator(level: summary.batteryLevel, compact: true),
                const SizedBox(width: 16),
                GpsAccuracyIndicator(accuracy: summary.accuracy, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            CheckInProximityBadge(result: summary.checkInProximity, compact: true),
            if (summary.trackerId != null) ...[
              const SizedBox(height: 6),
              Text('Tracker: ${summary.trackerId}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTrack,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('VIEW PROFILE'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.officer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
