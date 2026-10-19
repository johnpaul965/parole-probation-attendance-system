import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:last/core/constants/tracking_config.dart';

import 'package:last/core/theme/app_colors.dart';

import 'package:last/core/widgets/empty_state.dart';

import 'package:last/core/widgets/loading_shimmer.dart';

import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/services/tracker_admin_service.dart';
import 'package:last/features/tracking/services/tracking_status_service.dart';
import 'package:last/features/tracking/widgets/tracking_status_badge.dart';

import 'package:last/features/admin/providers/admin_provider.dart';

import 'package:last/features/auth/models/app_user.dart';

import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/providers/auth_provider.dart';



class UserManagementScreen extends StatefulWidget {

  const UserManagementScreen({super.key});



  @override

  State<UserManagementScreen> createState() => _UserManagementScreenState();

}



class _UserManagementScreenState extends State<UserManagementScreen> {

  UserRole? _filter;

  final _trackerService = createTrackerAdminService();

  final _statusService = TrackingStatusService();

  List<GpsTracker> _trackers = [];



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      context.read<AdminProvider>().startListening();

      _loadTrackers();

    });

  }



  Future<void> _loadTrackers() async {

    try {

      _trackers = await _trackerService.getAllTrackers();

      if (mounted) setState(() {});

    } catch (_) {}

  }



  GpsTracker? _trackerFor(AppUser parolee) {

    if (parolee.trackerId != null) {

      for (final t in _trackers) {

        if (t.id == parolee.trackerId) return t;

      }

    }

    return _trackers.where((t) => t.paroleeId == parolee.id).firstOrNull;

  }



  Future<void> _assignTracker(AppUser parolee) async {

    final available = _trackers.where((t) => !t.isAssigned || t.paroleeId == parolee.id).toList();

    if (available.isEmpty) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('No available trackers. Create one in GPS Tracker Management.')),

        );

      }

      return;

    }

    final selected = await showDialog<GpsTracker>(

      context: context,

      builder: (ctx) => SimpleDialog(

        title: Text('Assign Tracker to ${parolee.fullName}'),

        children: available

            .map((t) => SimpleDialogOption(

                  onPressed: () => Navigator.pop(ctx, t),

                  child: Text('${t.id}${t.isAssigned ? ' (reassign)' : ''}'),

                ))

            .toList(),

      ),

    );

    if (selected != null && mounted) {

      await _trackerService.assignTracker(

        trackerId: selected.id,

        paroleeId: parolee.id,

        paroleeName: parolee.fullName,

      );

      await _loadTrackers();

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Assigned ${selected.id} to ${parolee.fullName}')),

        );

      }

    }

  }



  Future<void> _unassignTracker(AppUser parolee) async {

    final tracker = _trackerFor(parolee);

    if (tracker == null) return;

    await _trackerService.unassignTracker(tracker.id);

    await _loadTrackers();

    if (mounted) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Unassigned tracker from ${parolee.fullName}')),

      );

    }

  }



  String? _officerName(AppUser parolee, List<AppUser> officers) {

    if (parolee.officerId == null) return null;

    for (final o in officers) {

      if (o.id == parolee.officerId) return o.fullName;

    }

    return null;

  }



  Future<void> _confirmRemove(AppUser user) async {
    final me = context.read<AuthProvider>().user;
    if (me != null && me.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot remove your own account.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove user'),
        content: Text(
          'Remove ${user.fullName} (${user.role.label}) from PPA-TAC?\n\n'
          'Their profile will be deleted. Their login email cannot be registered again until it is removed in Firebase Authentication.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await context.read<AdminProvider>().deleteUser(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '${user.fullName} was removed.' : 'Failed to remove user.')),
    );
    if (success) _loadTrackers();
  }

  Future<void> _assignOfficer(AppUser parolee, List<AppUser> officers) async {

    final selected = await showDialog<AppUser>(

      context: context,

      builder: (ctx) => SimpleDialog(

        title: const Text('Assign Officer'),

        children: officers

            .map((o) => SimpleDialogOption(

                  onPressed: () => Navigator.pop(ctx, o),

                  child: Text(o.fullName),

                ))

            .toList(),

      ),

    );

    if (selected != null && mounted) {

      await context.read<AdminProvider>().assignOfficer(parolee.id, selected.id);

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Assigned ${selected.fullName} to ${parolee.fullName}')),

        );

      }

    }

  }



  Future<void> _removeOfficer(AppUser parolee) async {

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: const Text('Remove Officer'),

        content: Text('Remove officer assignment from ${parolee.fullName}?'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),

          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),

        ],

      ),

    );

    if (confirmed == true && mounted) {

      await context.read<AdminProvider>().removeOfficer(parolee.id);

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Removed officer from ${parolee.fullName}')),

        );

      }

    }

  }



  Future<void> _assignGeofence(AppUser parolee) async {

    final nameController = TextEditingController(text: 'Monitoring Area');

    final latController = TextEditingController(text: TrackingConfig.mockBaseLatitude.toString());

    final lngController = TextEditingController(text: TrackingConfig.mockBaseLongitude.toString());

    final radiusController = TextEditingController(

      text: TrackingConfig.defaultGeofenceRadiusMeters.toStringAsFixed(0),

    );



    final confirmed = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: Text('Assign Geofence — ${parolee.fullName}'),

        content: SingleChildScrollView(

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Zone Name')),

              TextField(controller: latController, decoration: const InputDecoration(labelText: 'Center Latitude')),

              TextField(controller: lngController, decoration: const InputDecoration(labelText: 'Center Longitude')),

              TextField(controller: radiusController, decoration: const InputDecoration(labelText: 'Radius (meters)')),

            ],

          ),

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),

          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),

        ],

      ),

    );



    if (confirmed == true && mounted) {

      await _trackerService.assignGeofence(

        paroleeId: parolee.id,

        name: nameController.text.trim(),

        centerLat: double.tryParse(latController.text) ?? TrackingConfig.mockBaseLatitude,

        centerLng: double.tryParse(lngController.text) ?? TrackingConfig.mockBaseLongitude,

        radiusMeters: double.tryParse(radiusController.text) ?? TrackingConfig.defaultGeofenceRadiusMeters,

      );

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Geofence assigned to ${parolee.fullName}')),

        );

      }

    }



    nameController.dispose();

    latController.dispose();

    lngController.dispose();

    radiusController.dispose();

  }



  void _showParoleeActions(AppUser parolee, List<AppUser> officers) {

    showModalBottomSheet<void>(

      context: context,

      builder: (ctx) => SafeArea(

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            ListTile(

              leading: const Icon(Icons.person_add_alt_1),

              title: Text(parolee.officerId == null ? 'Assign Officer' : 'Change Officer'),

              onTap: () {

                Navigator.pop(ctx);

                _assignOfficer(parolee, officers);

              },

            ),

            if (parolee.officerId != null)

              ListTile(

                leading: const Icon(Icons.person_remove),

                title: const Text('Remove Officer'),

                onTap: () {

                  Navigator.pop(ctx);

                  _removeOfficer(parolee);

                },

              ),

            ListTile(

              leading: const Icon(Icons.gps_fixed),

              title: Text(parolee.trackerId == null ? 'Assign Tracker' : 'Change Tracker'),

              onTap: () {

                Navigator.pop(ctx);

                _assignTracker(parolee);

              },

            ),

            if (parolee.trackerId != null || _trackerFor(parolee) != null)

              ListTile(

                leading: const Icon(Icons.link_off),

                title: const Text('Unassign Tracker'),

                onTap: () {

                  Navigator.pop(ctx);

                  _unassignTracker(parolee);

                },

              ),

            ListTile(

              leading: const Icon(Icons.fence),

              title: const Text('Assign Geofence'),

              onTap: () {

                Navigator.pop(ctx);

                _assignGeofence(parolee);

              },

            ),

          ],

        ),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final admin = context.watch<AdminProvider>();

    var users = admin.users;

    if (_filter != null) users = users.where((u) => u.role == _filter).toList();



    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(

        title: const Text('User Management'),

        backgroundColor: AppColors.reports,

        foregroundColor: Colors.white,

      ),

      body: Column(

        children: [

          SingleChildScrollView(

            scrollDirection: Axis.horizontal,

            padding: const EdgeInsets.all(12),

            child: Row(

              children: [

                FilterChip(

                  label: const Text('All'),

                  selected: _filter == null,

                  onSelected: (_) => setState(() => _filter = null),

                ),

                ...UserRole.values.map(

                  (r) => Padding(

                    padding: const EdgeInsets.only(left: 8),

                    child: FilterChip(

                      label: Text(r.label),

                      selected: _filter == r,

                      onSelected: (_) => setState(() => _filter = r),

                    ),

                  ),

                ),

              ],

            ),

          ),

          Expanded(

            child: admin.isLoading

                ? const LoadingShimmer()

                : users.isEmpty

                    ? const EmptyState(icon: Icons.people_outline, title: 'No users')

                    : RefreshIndicator(

                        onRefresh: () async {

                          await context.read<AdminProvider>().loadUsers();

                          await _loadTrackers();

                        },

                        child: ListView.builder(

                          padding: const EdgeInsets.symmetric(horizontal: 16),

                          itemCount: users.length,

                          itemBuilder: (context, i) {

                            final u = users[i];

                            if (u.role == UserRole.parolee) {

                              return _ParoleeManagementCard(

                                parolee: u,

                                officerName: _officerName(u, admin.officers),

                                tracker: _trackerFor(u),

                                statusService: _statusService,

                                onManage: () => _showParoleeActions(u, admin.officers),

                                onToggleActive: (v) =>

                                    context.read<AdminProvider>().toggleActive(u.id, v),

                                onRemove: () => _confirmRemove(u),

                              );

                            }

                            return Card(

                              margin: const EdgeInsets.only(bottom: 8),

                              child: ListTile(

                                leading: CircleAvatar(

                                  child: Text(u.initials, style: const TextStyle(fontSize: 12)),

                                ),

                                title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),

                                subtitle: Text('${u.role.label} · ${u.email}'),

                                trailing: Row(

                                  mainAxisSize: MainAxisSize.min,

                                  children: [

                                    Switch(

                                      value: u.isActive,

                                      onChanged: (v) =>

                                          context.read<AdminProvider>().toggleActive(u.id, v),

                                    ),

                                    IconButton(

                                      tooltip: 'Remove',

                                      icon: const Icon(Icons.delete_outline),

                                      onPressed: () => _confirmRemove(u),

                                    ),

                                  ],

                                ),

                              ),

                            );

                          },

                        ),

                      ),

          ),

        ],

      ),

    );

  }

}



class _ParoleeManagementCard extends StatelessWidget {

  const _ParoleeManagementCard({

    required this.parolee,

    required this.officerName,

    required this.tracker,

    required this.statusService,

    required this.onManage,

    required this.onToggleActive,

    required this.onRemove,

  });



  final AppUser parolee;

  final String? officerName;

  final GpsTracker? tracker;

  final TrackingStatusService statusService;

  final VoidCallback onManage;

  final ValueChanged<bool> onToggleActive;

  final VoidCallback onRemove;



  @override

  Widget build(BuildContext context) {

    final trackingStatus = statusService.resolve(tracker: tracker, latestLocation: null);



    return Card(

      margin: const EdgeInsets.only(bottom: 10),

      child: Padding(

        padding: const EdgeInsets.all(14),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                CircleAvatar(

                  radius: 18,

                  child: Text(parolee.initials, style: const TextStyle(fontSize: 12)),

                ),

                const SizedBox(width: 10),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(parolee.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),

                      Text(parolee.caseNumber ?? 'No case #',

                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),

                    ],

                  ),

                ),

                Switch(value: parolee.isActive, onChanged: onToggleActive),

              ],

            ),

            const Divider(height: 20),

            _DetailRow(

              label: 'Assigned Officer',

              value: officerName ?? 'Not assigned',

              icon: Icons.badge_outlined,

            ),

            _DetailRow(

              label: 'Tracker',

              value: tracker?.id ?? 'Not assigned',

              icon: Icons.gps_fixed,

            ),

            _DetailRow(

              label: 'Supervision',

              value: parolee.supervision.hasMissingDates
                  ? parolee.supervision.label
                  : parolee.supervision.shortLabel,

              icon: Icons.date_range_outlined,

            ),

            if (parolee.phone != null && parolee.phone!.isNotEmpty)

              _DetailRow(

                label: 'Phone',

                value: parolee.phone!,

                icon: Icons.phone_outlined,

              ),

            const SizedBox(height: 8),

            Row(

              children: [

                const Text('Tracking Status', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),

                const SizedBox(width: 8),

                TrackingStatusBadge(status: trackingStatus, compact: true),

              ],

            ),

            const SizedBox(height: 12),

            SizedBox(

              width: double.infinity,

              child: OutlinedButton.icon(

                onPressed: onManage,

                icon: const Icon(Icons.settings, size: 18),

                label: const Text('MANAGE ASSIGNMENTS'),

              ),

            ),

            const SizedBox(height: 8),

            SizedBox(

              width: double.infinity,

              child: OutlinedButton.icon(

                onPressed: onRemove,

                icon: const Icon(Icons.delete_outline, size: 18),

                label: const Text('REMOVE'),

                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),

              ),

            ),

          ],

        ),

      ),

    );

  }

}



class _DetailRow extends StatelessWidget {

  const _DetailRow({required this.label, required this.value, required this.icon});



  final String label;

  final String value;

  final IconData icon;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 6),

      child: Row(

        children: [

          Icon(icon, size: 14, color: AppColors.textMuted),

          const SizedBox(width: 6),

          Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),

          Expanded(

            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),

          ),

        ],

      ),

    );

  }

}



extension _FirstOrNull<E> on Iterable<E> {

  E? get firstOrNull => isEmpty ? null : first;

}


