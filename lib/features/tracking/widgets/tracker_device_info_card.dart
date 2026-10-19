import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/features/tracking/services/tracking_status_service.dart';
import 'package:last/features/tracking/widgets/battery_indicator.dart';
import 'package:last/features/tracking/widgets/tracking_status_badge.dart';

class TrackerDeviceInfoCard extends StatelessWidget {
  const TrackerDeviceInfoCard({
    super.key,
    this.tracker,
    this.trackingStatus,
  });

  final GpsTracker? tracker;
  final TrackingStatus? trackingStatus;

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final status = trackingStatus ??
        TrackingStatusService().resolve(tracker: tracker, latestLocation: null);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TRACKER DEVICE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            if (tracker == null || !tracker!.isAssigned) ...[
              const Text(
                'No GPS tracker assigned.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ] else ...[
              _Row(label: 'Device ID', value: tracker!.deviceId),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Status', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 12),
                  TrackingStatusBadge(status: status, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Battery', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 12),
                  BatteryIndicator(level: tracker!.batteryLevel, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              _Row(label: 'Last Seen', value: _timeAgo(tracker!.lastSeenAt)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
