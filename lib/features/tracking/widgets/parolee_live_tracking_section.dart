import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/parolee_tracking_summary.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/features/tracking/widgets/battery_indicator.dart';
import 'package:last/features/tracking/widgets/check_in_proximity_badge.dart';
import 'package:last/features/tracking/widgets/gps_accuracy_indicator.dart';
import 'package:last/features/tracking/widgets/live_tracking_map.dart';
import 'package:last/features/tracking/widgets/tracking_alert_card.dart';
import 'package:last/features/tracking/widgets/tracking_status_badge.dart';

/// Live GPS tracker embedded in the parolee profile.
/// Uses [Selector] so GPS updates rebuild only this section, not the full profile.
class ParoleeLiveTrackingSection extends StatefulWidget {
  const ParoleeLiveTrackingSection({
    super.key,
    required this.paroleeId,
    this.onStartedWatching,
  });

  final String paroleeId;
  final VoidCallback? onStartedWatching;

  @override
  State<ParoleeLiveTrackingSection> createState() => _ParoleeLiveTrackingSectionState();
}

class _ParoleeLiveTrackingSectionState extends State<ParoleeLiveTrackingSection> {
  final _mapKey = GlobalKey<LiveTrackingMapState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<TrackingProvider>().startWatchingParolee(
              requester: user,
              paroleeId: widget.paroleeId,
            );
        widget.onStartedWatching?.call();
      }
    });
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return DateFormat('h:mm a').format(dt);
  }

  TrackingAlertType? _alertForStatus(TrackingStatus status, GeofenceStatus geofence) {
    if (status == TrackingStatus.lowBattery) return TrackingAlertType.lowBattery;
    if (status == TrackingStatus.offline) return TrackingAlertType.trackerOffline;
    if (status == TrackingStatus.gpsUnavailable) return TrackingAlertType.gpsFailure;
    if (geofence == GeofenceStatus.outside) return TrackingAlertType.geofenceViolation;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;

    return Selector<TrackingProvider, _LiveTrackingViewData>(
      selector: (_, p) => _LiveTrackingViewData(
        loading: p.isParoleeLoading,
        error: p.paroleeError,
        summary: p.activeTracking?.paroleeId == widget.paroleeId ? p.activeTracking : null,
      ),
      builder: (context, data, _) {
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text(
              'LIVE DEVICE TRACKING',
              style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                if (data.loading && data.summary == null)
                  _LoadingState()
                else if (data.error != null && data.summary == null)
                  _ErrorState(
                    message: data.error!,
                    onRetry: () {
                      context.read<TrackingProvider>().startWatchingParolee(
                            requester: user,
                            paroleeId: widget.paroleeId,
                          );
                    },
                  )
                else if (data.summary == null)
                  const _EmptyState(message: 'No tracking data available.')
                else
                  _ActiveTrackerContent(
                    mapKey: _mapKey,
                    summary: data.summary!,
                    paroleeId: widget.paroleeId,
                    user: user,
                    timeAgo: _timeAgo,
                    alertType: _alertForStatus(
                      data.summary!.trackingStatus,
                      data.summary!.geofenceStatus,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveTrackingViewData {
  const _LiveTrackingViewData({
    required this.loading,
    required this.error,
    required this.summary,
  });

  final bool loading;
  final String? error;
  final ParoleeTrackingSummary? summary;

  @override
  bool operator ==(Object other) =>
      other is _LiveTrackingViewData &&
      loading == other.loading &&
      error == other.error &&
      summary?.paroleeId == other.summary?.paroleeId &&
      summary?.trackingStatus == other.summary?.trackingStatus &&
      summary?.latestLocation?.latitude == other.summary?.latestLocation?.latitude &&
      summary?.latestLocation?.longitude == other.summary?.latestLocation?.longitude &&
      summary?.latestLocation?.recordedAt == other.summary?.latestLocation?.recordedAt &&
      summary?.batteryLevel == other.summary?.batteryLevel &&
      summary?.geofenceStatus == other.summary?.geofenceStatus;

  @override
  int get hashCode => Object.hash(
        loading,
        error,
        summary?.paroleeId,
        summary?.trackingStatus,
        summary?.latestLocation?.latitude,
        summary?.latestLocation?.longitude,
        summary?.latestLocation?.recordedAt,
      );
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loading current location...',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.9)),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: const SizedBox(height: 200, child: LoadingShimmer()),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, size: 18, color: AppColors.error.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('TRY AGAIN'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textMuted));
  }
}

class _ActiveTrackerContent extends StatelessWidget {
  const _ActiveTrackerContent({
    required this.mapKey,
    required this.summary,
    required this.paroleeId,
    required this.user,
    required this.timeAgo,
    this.alertType,
  });

  final GlobalKey<LiveTrackingMapState> mapKey;
  final ParoleeTrackingSummary summary;
  final String paroleeId;
  final AppUser user;
  final String Function(DateTime?) timeAgo;
  final TrackingAlertType? alertType;

  @override
  Widget build(BuildContext context) {
    final status = summary.trackingStatus;
    final location = summary.latestLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TrackingStatusBadge(status: status),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusSubtitle(status, timeAgo(summary.lastUpdated)),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CheckInProximityBadge(result: summary.checkInProximity, compact: true),
        if (alertType != null &&
            (status != TrackingStatus.active || alertType == TrackingAlertType.geofenceViolation)) ...[
          const SizedBox(height: 10),
          TrackingAlertCard(
            alertType: alertType!,
            paroleeName: summary.fullName,
            lastSeen: summary.lastUpdated,
          ),
        ],
        const SizedBox(height: 12),
        LiveTrackingMap(
          key: mapKey,
          location: location,
          geofences: summary.geofences,
          height: 220,
        ),
        const SizedBox(height: 12),
        if (status == TrackingStatus.noTracker)
          const Text(
            'No tracker assigned to this parolee.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          )
        else if (status == TrackingStatus.offline) ...[
          Text(
            'Last known location: ${timeAgo(location?.recordedAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          if (location != null) ...[
            const SizedBox(height: 6),
            Text(
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ] else if (status.isLive && location != null) ...[
          _MetricRow(label: 'Last Updated', value: timeAgo(location.recordedAt)),
          _MetricRow(
            label: 'GPS Accuracy',
            trailing: GpsAccuracyIndicator(accuracy: location.accuracy, compact: true),
          ),
          _MetricRow(
            label: 'Battery',
            trailing: BatteryIndicator(level: location.batteryLevel ?? summary.batteryLevel, compact: true),
          ),
          if (location.speed != null)
            _MetricRow(label: 'Speed', value: '${location.speed!.toStringAsFixed(1)} km/h'),
        ] else
          const Text(
            'No GPS location is currently available.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        if (summary.geofenceStatus == GeofenceStatus.inside ||
            summary.geofenceStatus == GeofenceStatus.outside) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                summary.geofenceStatus == GeofenceStatus.inside
                    ? Icons.check_circle
                    : Icons.warning_amber,
                size: 16,
                color: summary.geofenceStatus == GeofenceStatus.inside
                    ? AppColors.success
                    : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                summary.geofenceStatus.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: summary.geofenceStatus == GeofenceStatus.inside
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: location != null && location.hasValidCoordinates
                    ? () => mapKey.currentState?.centerOnParolee()
                    : null,
                icon: const Icon(Icons.center_focus_strong, size: 18),
                label: const Text('CENTER LOCATION'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.push('/officer/parolees/$paroleeId/live'),
                icon: const Icon(Icons.map, size: 18),
                label: const Text('VIEW LIVE LOCATION'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.officer),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/officer/parolees/$paroleeId/history'),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('LOCATION HISTORY'),
          ),
        ),
      ],
    );
  }

  String _statusSubtitle(TrackingStatus status, String lastUpdate) {
    return switch (status) {
      TrackingStatus.active => 'Location updated $lastUpdate',
      TrackingStatus.offline => 'Last seen $lastUpdate',
      TrackingStatus.gpsUnavailable => 'Location unavailable',
      TrackingStatus.lowBattery => 'Battery low — check device',
      TrackingStatus.noTracker => 'No GPS device or phone sharing',
      TrackingStatus.unknown => 'Status unknown',
    };
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, this.value, this.trailing});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
          Expanded(
            child: trailing ??
                Text(value ?? '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
