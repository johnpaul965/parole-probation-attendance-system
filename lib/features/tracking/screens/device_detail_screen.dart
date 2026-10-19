import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/features/admin/providers/admin_provider.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/services/tracker_admin_service.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/features/tracking/widgets/battery_indicator.dart';
import 'package:last/features/tracking/widgets/check_in_proximity_badge.dart';
import 'package:last/features/tracking/widgets/device_status_card.dart';
import 'package:last/features/tracking/widgets/last_updated_widget.dart';

/// Officer screen: device details, status management, assignment, location logs.
class DeviceDetailScreen extends StatefulWidget {
  const DeviceDetailScreen({super.key, required this.trackerId});

  final String trackerId;

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  final _adminService = createTrackerAdminService();

  GpsTracker? _tracker;
  List<LocationRecord> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tracker = await _adminService.getTrackerById(widget.trackerId);
      final logs = await _adminService.getDeviceLocationLogs(widget.trackerId);
      if (mounted) {
        setState(() {
          _tracker = tracker;
          _logs = logs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load device';
          _loading = false;
        });
      }
    }
  }

  Future<void> _rotateToken() async {
    final token = await _adminService.rotateDeviceToken(widget.trackerId);
    if (mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New Device Token'),
          content: SelectableText(
            'Copy this token into firmware API_TOKEN now. It is not stored in plaintext.\n\n$token',
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _linkIngestUid() async {
    final controller = TextEditingController(text: _tracker?.ingestAuthUid ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Device Auth UID'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create an Email/Password user in Firebase Authentication '
                '(no Firestore users profile). Paste that Auth UID here so the ESP32 can write GPS on Spark.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Firebase Auth UID',
                  hintText: 'Paste UID from Authentication',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    final uid = controller.text;
    controller.dispose();
    if (saved != true) return;
    try {
      await _adminService.setIngestAuthUid(widget.trackerId, uid);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device Auth UID linked.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _setStatus(TrackerDeviceStatus status) async {
    await _adminService.updateTrackerStatus(widget.trackerId, status);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${status.label}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final tracking = context.watch<TrackingProvider>();
    final tracker = _tracker;
    final proximity = tracking.summaryForTracker(widget.trackerId)?.checkInProximity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tracker?.deviceId ?? 'Device Details'),
        backgroundColor: AppColors.reports,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const LoadingShimmer()
          : _error != null
              ? EmptyState(icon: Icons.error_outline, title: _error!, actionLabel: 'Retry', onAction: _load)
              : tracker == null
                  ? const EmptyState(icon: Icons.gps_off, title: 'Device not found')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          DeviceStatusCard(tracker: tracker, showAdminDetails: true),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ESP32 SPARK LOGIN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    tracker.ingestAuthUid == null || tracker.ingestAuthUid!.isEmpty
                                        ? 'No device Auth UID linked. The ESP32 cannot write location yet.'
                                        : 'Linked UID: ${tracker.ingestAuthUid}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: _linkIngestUid,
                                    icon: const Icon(Icons.badge_outlined, size: 18),
                                    label: Text(
                                      tracker.ingestAuthUid == null || tracker.ingestAuthUid!.isEmpty
                                          ? 'Link Auth UID'
                                          : 'Update Auth UID',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (proximity != null) ...[
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CHECK-IN PROXIMITY',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    CheckInProximityBadge(result: proximity),
                                    if (proximity.locationName != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        proximity.locationName!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    const Text(
                                      'GPS proximity does not prove who is carrying the device.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (!tracker.isAssigned)
                                        FilledButton.icon(
                                          onPressed: () => _showAssignDialog(admin.parolees),
                                          icon: const Icon(Icons.link, size: 18),
                                          label: const Text('Assign'),
                                        ),
                                      if (tracker.isAssigned)
                                        OutlinedButton.icon(
                                          onPressed: () => _adminService.unassignTracker(widget.trackerId),
                                          icon: const Icon(Icons.link_off, size: 18),
                                          label: const Text('Unassign'),
                                        ),
                                      OutlinedButton.icon(
                                        onPressed: () => _setStatus(TrackerDeviceStatus.maintenance),
                                        icon: const Icon(Icons.build, size: 18),
                                        label: const Text('Maintenance'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _setStatus(TrackerDeviceStatus.inactive),
                                        icon: const Icon(Icons.block, size: 18),
                                        label: const Text('Deactivate'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _rotateToken,
                                        icon: const Icon(Icons.vpn_key, size: 18),
                                        label: const Text('Rotate unused Blaze token'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LOCATION LOGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                                  const SizedBox(height: 12),
                                  if (_logs.isEmpty)
                                    const Text('No location records yet.', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                                  else
                                    ..._logs.take(20).map((r) => ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text('${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}'),
                                          subtitle: LastUpdatedWidget(timestamp: r.recordedAt),
                                          trailing: r.batteryLevel != null
                                              ? BatteryIndicator(level: r.batteryLevel, compact: true)
                                              : null,
                                        )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Future<void> _showAssignDialog(List<dynamic> parolees) async {
    final selected = await showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Assign Device'),
        children: parolees
            .map<Widget>((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, p),
                  child: Text(p.fullName),
                ))
            .toList(),
      ),
    );
    if (selected != null) {
      await _adminService.assignTracker(
        trackerId: widget.trackerId,
        paroleeId: selected.id,
        paroleeName: selected.fullName,
      );
      await _load();
    }
  }
}
