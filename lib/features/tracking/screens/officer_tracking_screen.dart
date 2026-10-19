import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/core/widgets/stat_card.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/core/constants/tracking_config.dart';
import 'package:last/features/tracking/widgets/parolee_tracking_card.dart';
import 'package:last/features/tracking/widgets/tracking_alert_card.dart';

class OfficerTrackingScreen extends StatefulWidget {
  const OfficerTrackingScreen({super.key});

  @override
  State<OfficerTrackingScreen> createState() => _OfficerTrackingScreenState();
}

class _OfficerTrackingScreenState extends State<OfficerTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<TrackingProvider>().startWatchingAssigned(
              requester: user,
              officerId: user.id,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<TrackingProvider>();
    final stats = tracking.dashboardStats;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: AppColors.officer,
        foregroundColor: Colors.white,
      ),
      body: tracking.isLoading && tracking.assignedParolees.isEmpty
          ? const LoadingShimmer()
          : tracking.error != null && tracking.assignedParolees.isEmpty
              ? EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Tracking unavailable',
                  subtitle: tracking.error,
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    final user = context.read<AuthProvider>().user;
                    if (user != null) {
                      context.read<TrackingProvider>().startWatchingAssigned(
                            requester: user,
                            officerId: user.id,
                          );
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'MY ASSIGNED PAROLEES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          StatCard(label: 'Assigned', value: '${stats.totalAssigned}'),
                          const SizedBox(width: 10),
                          StatCard(label: 'Active', value: '${stats.activeTrackers}'),
                          const SizedBox(width: 10),
                          StatCard(label: 'Offline', value: '${stats.offlineTrackers}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (tracking.recentProximityAlerts.isNotEmpty) ...[
                        const Text(
                          'CHECK-IN PROXIMITY ALERTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...tracking.recentProximityAlerts.take(5).map((a) {
                          final dist = a.distanceMeters.round();
                          final radius =
                              TrackingConfig.checkInProximityRadiusMeters.round();
                          return TrackingAlertCard(
                            alertType: TrackingAlertType.checkInProximity,
                            paroleeName: a.paroleeName,
                            detail:
                                'Parolee ${a.paroleeName} is within $radius meters of the assigned check-in location.\n'
                                'ID: ${a.paroleeId} · ${a.locationName} · ${dist}m',
                            lastSeen: a.timestamp,
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                      if (stats.offlineTrackers > 0) ...[
                        const Text(
                          'RECENT TRACKING ALERTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...tracking.assignedParolees
                            .where((p) =>
                                p.trackingStatus == TrackingStatus.offline ||
                                p.trackingStatus == TrackingStatus.lowBattery ||
                                p.geofenceStatus == GeofenceStatus.outside)
                            .map(
                              (p) => TrackingAlertCard(
                                alertType: p.trackingStatus == TrackingStatus.lowBattery
                                    ? TrackingAlertType.lowBattery
                                    : p.geofenceStatus == GeofenceStatus.outside
                                        ? TrackingAlertType.geofenceViolation
                                        : TrackingAlertType.trackerOffline,
                                paroleeName: p.fullName,
                                lastSeen: p.lastUpdated,
                              ),
                            ),
                        const SizedBox(height: 8),
                      ],
                      if (tracking.assignedParolees.isEmpty)
                        const EmptyState(
                          icon: Icons.people_outline,
                          title: 'No assigned parolees',
                          subtitle: 'Assign parolees from the Users tab',
                        )
                      else
                        ...tracking.assignedParolees.map(
                          (p) => ParoleeTrackingCard(
                            summary: p,
                            onTrack: () => context.push('/officer/parolees/${p.paroleeId}'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
