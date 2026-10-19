import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/tracking_status.dart';

class TrackingAlertCard extends StatelessWidget {
  const TrackingAlertCard({
    super.key,
    required this.alertType,
    required this.paroleeName,
    this.detail,
    this.lastSeen,
  });

  final TrackingAlertType alertType;
  final String paroleeName;
  final String? detail;
  final DateTime? lastSeen;

  IconData get _icon => switch (alertType) {
        TrackingAlertType.trackerOffline => Icons.signal_wifi_off,
        TrackingAlertType.geofenceViolation => Icons.warning_amber_rounded,
        TrackingAlertType.lowBattery => Icons.battery_alert,
        TrackingAlertType.gpsFailure => Icons.gps_off,
        TrackingAlertType.checkInProximity => Icons.radar,
      };

  Color get _color => switch (alertType) {
        TrackingAlertType.trackerOffline => AppColors.warning,
        TrackingAlertType.geofenceViolation => AppColors.error,
        TrackingAlertType.lowBattery => AppColors.warning,
        TrackingAlertType.gpsFailure => AppColors.warning,
        TrackingAlertType.checkInProximity => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_icon, color: _color),
        title: Text(
          alertType.title.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color),
        ),
        subtitle: Text(
          detail ?? '$paroleeName — ${alertType.title}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: lastSeen != null,
        trailing: lastSeen != null
            ? Text(
                '${lastSeen!.hour.toString().padLeft(2, '0')}:${lastSeen!.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              )
            : null,
      ),
    );
  }
}
