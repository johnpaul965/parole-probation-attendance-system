import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/widgets/battery_indicator.dart';
import 'package:last/features/tracking/widgets/last_updated_widget.dart';
import 'package:last/features/tracking/widgets/location_status_badge.dart';

export 'tracker_device_info_card.dart' show TrackerDeviceInfoCard;

/// Spec alias: device status card for parolee profile / admin views.
class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({super.key, this.tracker, this.isOnline, this.showAdminDetails = false});

  final GpsTracker? tracker;
  final bool? isOnline;
  final bool showAdminDetails;

  @override
  Widget build(BuildContext context) {
    if (tracker == null || !tracker!.isAssigned) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No tracking device assigned.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ),
      );
    }

    final online = isOnline ??
        (tracker!.lastSeenAt != null &&
            DateTime.now().difference(tracker!.lastSeenAt!) <= const Duration(minutes: 2));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showAdminDetails ? 'DEVICE' : 'LIVE DEVICE TRACKING',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),
            Text('Device: ${tracker!.deviceId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            if (showAdminDetails && tracker!.deviceName != null) ...[
              const SizedBox(height: 4),
              Text('Name: ${tracker!.deviceName}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                LocationStatusBadge(isOnline: online),
                const SizedBox(width: 8),
                Text(tracker!.status.label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Battery: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                BatteryIndicator(level: tracker!.batteryLevel, compact: true),
              ],
            ),
            const SizedBox(height: 4),
            LastUpdatedWidget(timestamp: tracker!.lastSeenAt, label: 'Last Update'),
            if (tracker!.isAssigned) ...[
              const SizedBox(height: 4),
              Text('Parolee: ${tracker!.paroleeName ?? tracker!.paroleeId}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              if (tracker!.assignedAt != null)
                LastUpdatedWidget(timestamp: tracker!.assignedAt, label: 'Assigned'),
            ],
          ],
        ),
      ),
    );
  }
}
