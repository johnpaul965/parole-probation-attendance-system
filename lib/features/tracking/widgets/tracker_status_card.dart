import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/check_in_proximity.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/services/tracking_status_service.dart';
import 'package:last/features/tracking/widgets/battery_indicator.dart';
import 'package:last/features/tracking/widgets/check_in_proximity_badge.dart';
import 'package:last/features/tracking/widgets/tracking_status_badge.dart';

class TrackerStatusCard extends StatelessWidget {
  const TrackerStatusCard({
    super.key,
    required this.tracker,
    this.latestLocation,
    this.checkInProximity,
  });

  final GpsTracker tracker;
  final LocationRecord? latestLocation;
  final CheckInProximityResult? checkInProximity;

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final status = TrackingStatusService().resolve(
      tracker: tracker,
      latestLocation: latestLocation,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gps_fixed, color: AppColors.reports, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tracker.id,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                TrackingStatusBadge(status: status, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tracker.isAssigned ? tracker.paroleeName ?? 'Assigned' : 'Unassigned',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                BatteryIndicator(level: tracker.batteryLevel, compact: true),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Last seen: ${_timeAgo(tracker.lastSeenAt)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            if (checkInProximity != null) ...[
              const SizedBox(height: 10),
              CheckInProximityBadge(result: checkInProximity!, compact: true),
              if (checkInProximity!.locationName != null) ...[
                const SizedBox(height: 4),
                Text(
                  checkInProximity!.locationName!,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
