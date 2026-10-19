import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/features/tracking/widgets/battery_indicator.dart';
import 'package:last/features/tracking/widgets/gps_accuracy_indicator.dart';
import 'package:last/features/tracking/widgets/tracking_status_badge.dart';

class LocationInfoCard extends StatelessWidget {
  const LocationInfoCard({
    super.key,
    required this.fullName,
    required this.status,
    this.location,
    this.geofenceStatus = GeofenceStatus.noGeofence,
  });

  final String fullName;
  final TrackingStatus status;
  final LocationRecord? location;
  final GeofenceStatus geofenceStatus;

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                TrackingStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            if (location != null && status.isLive) ...[
              _InfoRow(label: 'Latitude', value: location!.latitude.toStringAsFixed(6)),
              _InfoRow(label: 'Longitude', value: location!.longitude.toStringAsFixed(6)),
              _InfoRow(
                label: 'Accuracy',
                value: '',
                trailing: GpsAccuracyIndicator(accuracy: location!.accuracy),
              ),
              _InfoRow(
                label: 'Battery',
                value: '',
                trailing: BatteryIndicator(level: location!.batteryLevel),
              ),
              if (location!.speed != null)
                _InfoRow(label: 'Speed', value: '${location!.speed!.toStringAsFixed(1)} km/h'),
              _InfoRow(label: 'Last Updated', value: _timeAgo(location!.recordedAt)),
            ] else if (status == TrackingStatus.noTracker)
              const Text('No GPS tracker is assigned to this parolee.', style: TextStyle(color: AppColors.textMuted))
            else if (status == TrackingStatus.offline) ...[
              Text(
                'Last known location: ${_timeAgo(location?.recordedAt)}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              if (location != null) ...[
                const SizedBox(height: 8),
                _InfoRow(label: 'Latitude', value: location!.latitude.toStringAsFixed(6)),
                _InfoRow(label: 'Longitude', value: location!.longitude.toStringAsFixed(6)),
              ],
            ] else
              const Text('Location is currently unavailable.', style: TextStyle(color: AppColors.textMuted)),
            if (geofenceStatus == GeofenceStatus.inside || geofenceStatus == GeofenceStatus.outside) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    geofenceStatus == GeofenceStatus.inside ? Icons.check_circle : Icons.warning_amber,
                    size: 16,
                    color: geofenceStatus == GeofenceStatus.inside ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    geofenceStatus.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: geofenceStatus == GeofenceStatus.inside ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: trailing ??
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
