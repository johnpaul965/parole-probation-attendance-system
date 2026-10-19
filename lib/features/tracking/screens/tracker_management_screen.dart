import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/core/constants/tracking_config.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/features/admin/providers/admin_provider.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/features/tracking/services/tracker_admin_service.dart';
import 'package:last/features/tracking/widgets/tracker_status_card.dart';
import 'package:last/features/tracking/widgets/tracking_alert_card.dart';

class TrackerManagementScreen extends StatefulWidget {
  const TrackerManagementScreen({super.key});

  @override
  State<TrackerManagementScreen> createState() => _TrackerManagementScreenState();
}

class _TrackerManagementScreenState extends State<TrackerManagementScreen> {
  final _adminService = createTrackerAdminService();
  List<GpsTracker> _trackers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrackers();
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

  Future<void> _loadTrackers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _trackers = await _adminService.getAllTrackers();
    } catch (_) {
      _error = 'Failed to load trackers';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTracker() async {
    final idController = TextEditingController();
    final deviceController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create GPS Tracker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: 'Tracker ID (e.g. TRK-001)'),
            ),
            TextField(
              controller: deviceController,
              decoration: const InputDecoration(labelText: 'Device Identifier'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (created == true && idController.text.isNotEmpty) {
      final result = await _adminService.createTracker(
        trackerId: idController.text.trim(),
        deviceIdentifier: deviceController.text.trim().isEmpty
            ? 'dev-${idController.text.trim()}'
            : deviceController.text.trim(),
      );
      await _loadTrackers();
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tracker Created'),
            content: SelectableText(
              'Tracker ID (TRACKER_ID in firmware):\n${result.tracker.id}\n\n'
              'Suggested device email:\n${result.tracker.id.toLowerCase()}@pptac-attendance-capstone.web.app\n\n'
              'Spark (no Cloud Functions):\n'
              '1. Firebase Console → Authentication → Email/Password → Add user with that email.\n'
              '2. Copy the Auth UID.\n'
              '3. Open this tracker → paste the UID as Device Auth UID.\n'
              '4. Put TRACKER_ID, DEVICE_EMAIL, and DEVICE_PASSWORD in firmware. Do not use API_TOKEN.',
            ),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    }
    idController.dispose();
    deviceController.dispose();
  }

  Future<void> _assignTracker(GpsTracker tracker, List<AppUser> parolees) async {
    final selected = await showDialog<AppUser>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Assign ${tracker.id}'),
        children: parolees
            .map((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, p),
                  child: Text(p.fullName),
                ))
            .toList(),
      ),
    );
    if (selected != null) {
      await _adminService.assignTracker(
        trackerId: tracker.id,
        paroleeId: selected.id,
        paroleeName: selected.fullName,
      );
      await _loadTrackers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assigned ${tracker.id} to ${selected.fullName}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final tracking = context.watch<TrackingProvider>();
    final parolees = admin.parolees;
    final proximityAlerts = tracking.recentProximityAlerts;
    final assignedTrackers = tracking.assignedParolees
        .where((p) => p.tracker != null)
        .map((p) => p.tracker!)
        .toList();
    final visibleTrackers = _trackers.isNotEmpty ? _trackers : assignedTrackers;
    final usingSimulatedGps = tracking.assignedParolees.any(
      (p) => p.checkInProximity.isSimulated,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('GPS Tracker Management'),
        backgroundColor: AppColors.reports,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTracker,
        icon: const Icon(Icons.add),
        label: const Text('New Tracker'),
        backgroundColor: AppColors.reports,
      ),
      body: _loading && visibleTrackers.isEmpty
          ? const LoadingShimmer()
          : _error != null && visibleTrackers.isEmpty
              ? EmptyState(icon: Icons.error_outline, title: _error!, actionLabel: 'Retry', onAction: _loadTrackers)
              : visibleTrackers.isEmpty
                  ? const EmptyState(
                      icon: Icons.gps_fixed,
                      title: 'No trackers yet',
                      subtitle: 'Create a GPS tracker to assign to parolees',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTrackers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: visibleTrackers.length +
                            (usingSimulatedGps ? 1 : 0) +
                            (proximityAlerts.isEmpty ? 0 : proximityAlerts.length + 1),
                        itemBuilder: (context, i) {
                          var index = i;
                          if (usingSimulatedGps) {
                            if (index == 0) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    'Simulated GPS readings — no live ESP32 is connected. '
                                    'Officers are notified only when a parolee enters the 50 m check-in radius. '
                                    'Being outside 50 m does not mark the parolee absent. '
                                    'GPS does not prove who is carrying the device.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ),
                              );
                            }
                            index -= 1;
                          }
                          if (proximityAlerts.isNotEmpty) {
                            if (index == 0) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'CHECK-IN PROXIMITY ALERTS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              );
                            }
                            if (index <= proximityAlerts.length) {
                              final alert = proximityAlerts[index - 1];
                              final dist = alert.distanceMeters.round();
                              final radius =
                                  TrackingConfig.checkInProximityRadiusMeters.round();
                              return TrackingAlertCard(
                                alertType: TrackingAlertType.checkInProximity,
                                paroleeName: alert.paroleeName,
                                detail:
                                    'Parolee ${alert.paroleeName} is within $radius meters of the assigned check-in location.\n'
                                    'ID: ${alert.paroleeId} · ${alert.locationName} · ${dist}m'
                                    '${alert.isSimulated ? ' · Simulated GPS' : ''}',
                                lastSeen: alert.timestamp,
                              );
                            }
                            index -= proximityAlerts.length + 1;
                          }

                          final t = visibleTrackers[index];
                          final summary = tracking.summaryForTracker(t.id) ??
                              (t.paroleeId != null
                                  ? tracking.summaryForParolee(t.paroleeId!)
                                  : null);
                          return InkWell(
                            onTap: () => context.push('/officer/trackers/${t.id}'),
                            child: Stack(
                              children: [
                                TrackerStatusCard(
                                  tracker: t,
                                  latestLocation: summary?.latestLocation,
                                  checkInProximity: summary?.checkInProximity,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'assign') {
                                        await _assignTracker(t, parolees);
                                      } else if (v == 'unassign' && t.isAssigned) {
                                        await _adminService.unassignTracker(t.id);
                                        await _loadTrackers();
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'assign', child: Text('Assign to parolee')),
                                      if (t.isAssigned)
                                        const PopupMenuItem(value: 'unassign', child: Text('Unassign')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
