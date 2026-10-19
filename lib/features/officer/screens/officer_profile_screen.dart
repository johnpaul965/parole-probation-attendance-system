import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/core/constants/tracking_config.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/core/widgets/stat_card.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/tracking/models/parolee_tracking_summary.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/features/tracking/widgets/parolee_tracking_card.dart';
import 'package:last/features/tracking/widgets/tracking_alert_card.dart';

/// Officer profile with account settings and live GPS tracking for assigned parolees.
class OfficerProfileScreen extends StatefulWidget {
  const OfficerProfileScreen({super.key});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.fullName ?? '';
    _phoneController.text = user?.phone ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final officer = context.read<AuthProvider>().user;
      if (officer != null) {
        context.read<TrackingProvider>().startWatchingAssigned(
              requester: officer,
              officerId: officer.id,
            );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    final auth = context.read<AuthProvider>();
    final user = auth.user!;
    auth.updateProfile(user.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Officer Profile'),
        backgroundColor: AppColors.officer,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AccountSection(
            user: user,
            nameController: _nameController,
            phoneController: _phoneController,
            onSave: _save,
            onLogout: _logout,
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Live Tracking'),
          const SizedBox(height: 4),
          Text(
            'Tap a parolee to open their profile with live GPS map.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 12),
          const _OfficerLiveTrackingSection(),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.user,
    required this.nameController,
    required this.phoneController,
    required this.onSave,
    required this.onLogout,
  });

  final AppUser user;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onSave;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.officer.withValues(alpha: 0.12),
                foregroundColor: AppColors.officer,
                child: Text(
                  user.initials,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                user.role.label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: user.email,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            if (user.department != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: user.department,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(backgroundColor: AppColors.officer),
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live tracking list — isolated rebuild via Selector.
class _OfficerLiveTrackingSection extends StatelessWidget {
  const _OfficerLiveTrackingSection();

  @override
  Widget build(BuildContext context) {
    return Selector<TrackingProvider, _TrackingListData>(
      selector: (_, p) => _TrackingListData(
        loading: p.isLoading,
        error: p.error,
        parolees: p.assignedParolees,
        stats: p.dashboardStats,
        proximityAlerts: p.recentProximityAlerts,
      ),
      builder: (context, data, _) {
        if (data.loading && data.parolees.isEmpty) {
          return const LoadingShimmer();
        }
        if (data.error != null && data.parolees.isEmpty) {
          return EmptyState(
            icon: Icons.cloud_off,
            title: 'Tracking unavailable',
            subtitle: data.error,
            actionLabel: 'Retry',
            onAction: () {
              final user = context.read<AuthProvider>().user;
              if (user != null) {
                context.read<TrackingProvider>().startWatchingAssigned(
                      requester: user,
                      officerId: user.id,
                    );
              }
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatCard(label: 'Assigned', value: '${data.stats.totalAssigned}'),
                const SizedBox(width: 10),
                StatCard(label: 'Active', value: '${data.stats.activeTrackers}'),
                const SizedBox(width: 10),
                StatCard(label: 'Offline', value: '${data.stats.offlineTrackers}'),
              ],
            ),
            const SizedBox(height: 12),
            if (data.proximityAlerts.isNotEmpty)
              ...data.proximityAlerts.take(3).map(
                    (a) => TrackingAlertCard(
                      alertType: TrackingAlertType.checkInProximity,
                      paroleeName: a.paroleeName,
                      detail:
                          'Parolee ${a.paroleeName} is within ${TrackingConfig.checkInProximityRadiusMeters.round()} meters of the assigned check-in location.\n'
                          '${a.locationName} · ${a.distanceMeters.round()}m',
                      lastSeen: a.timestamp,
                    ),
                  ),
            if (data.stats.offlineTrackers > 0)
              ...data.parolees
                  .where((p) =>
                      p.trackingStatus == TrackingStatus.offline ||
                      p.trackingStatus == TrackingStatus.lowBattery ||
                      p.geofenceStatus == GeofenceStatus.outside)
                  .take(3)
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
            if (data.parolees.isEmpty)
              const EmptyState(
                icon: Icons.people_outline,
                title: 'No assigned parolees',
                subtitle: 'Assign parolees from the Users tab',
              )
            else
              ...data.parolees.map(
                (p) => ParoleeTrackingCard(
                  summary: p,
                  onTrack: () => context.push('/officer/parolees/${p.paroleeId}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TrackingListData {
  const _TrackingListData({
    required this.loading,
    required this.error,
    required this.parolees,
    required this.stats,
    this.proximityAlerts = const [],
  });

  final bool loading;
  final String? error;
  final List<ParoleeTrackingSummary> parolees;
  final TrackingDashboardStats stats;
  final List<ProximityAlertEvent> proximityAlerts;

  @override
  bool operator ==(Object other) {
    if (other is! _TrackingListData) return false;
    if (loading != other.loading || error != other.error) return false;
    if (parolees.length != other.parolees.length) return false;
    if (proximityAlerts.length != other.proximityAlerts.length) return false;
    for (var i = 0; i < parolees.length; i++) {
      final a = parolees[i];
      final b = other.parolees[i];
      if (a.paroleeId != b.paroleeId ||
          a.trackingStatus != b.trackingStatus ||
          a.checkInProximity.status != b.checkInProximity.status ||
          a.checkInProximity.distanceMeters != b.checkInProximity.distanceMeters ||
          a.latestLocation?.latitude != b.latestLocation?.latitude ||
          a.latestLocation?.longitude != b.latestLocation?.longitude ||
          a.latestLocation?.recordedAt != b.latestLocation?.recordedAt) {
        return false;
      }
    }
    return stats.totalAssigned == other.stats.totalAssigned &&
        stats.activeTrackers == other.stats.activeTrackers &&
        stats.offlineTrackers == other.stats.offlineTrackers;
  }

  @override
  int get hashCode => Object.hash(
        loading,
        error,
        parolees.length,
        stats.activeTrackers,
        proximityAlerts.length,
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}
