import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/tracking_status.dart';

class TrackingStatusBadge extends StatelessWidget {
  const TrackingStatusBadge({super.key, required this.status, this.compact = false});

  final TrackingStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      TrackingStatus.active => (AppColors.success, Icons.circle),
      TrackingStatus.offline => (AppColors.error, Icons.cloud_off),
      TrackingStatus.gpsUnavailable => (AppColors.warning, Icons.gps_off),
      TrackingStatus.lowBattery => (AppColors.warning, Icons.battery_alert),
      TrackingStatus.noTracker => (AppColors.textMuted, Icons.gps_not_fixed),
      TrackingStatus.unknown => (AppColors.textMuted, Icons.help_outline),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 8 : 10, color: color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
