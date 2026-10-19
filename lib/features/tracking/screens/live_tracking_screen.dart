import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/features/tracking/widgets/live_tracking_map.dart';
import 'package:last/features/tracking/widgets/location_info_card.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, required this.paroleeId});

  final String paroleeId;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
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
      }
    });
  }

  @override
  void dispose() {
    context.read<TrackingProvider>().stopWatchingParolee();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final tracking = context.watch<TrackingProvider>();
    final summary = tracking.activeTracking;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(summary?.fullName ?? 'Live Tracking'),
        backgroundColor: AppColors.officer,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Location History',
            onPressed: () => context.push('/officer/parolees/${widget.paroleeId}/history'),
          ),
        ],
      ),
      body: tracking.isParoleeLoading && summary == null
          ? const LoadingShimmer()
          : tracking.paroleeError != null && summary == null
              ? EmptyState(
                  icon: Icons.lock_outline,
                  title: 'Tracking unavailable',
                  subtitle: tracking.paroleeError,
                )
              : summary == null
                  ? const EmptyState(icon: Icons.gps_off, title: 'No tracking data')
                  : RefreshIndicator(
                      onRefresh: () => tracking.refreshLocation(
                        requester: user,
                        paroleeId: widget.paroleeId,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          LiveTrackingMap(
                            key: _mapKey,
                            location: summary.latestLocation,
                            geofences: summary.geofences,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _mapKey.currentState?.centerOnParolee(),
                                  icon: const Icon(Icons.center_focus_strong, size: 18),
                                  label: const Text('CENTER ON PAROLEE'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => tracking.refreshLocation(
                                    requester: user,
                                    paroleeId: widget.paroleeId,
                                  ),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('REFRESH'),
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.officer),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LocationInfoCard(
                            fullName: summary.fullName,
                            status: summary.trackingStatus,
                            location: summary.latestLocation,
                            geofenceStatus: summary.geofenceStatus,
                          ),
                        ],
                      ),
                    ),
    );
  }
}
