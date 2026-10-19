import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/core/widgets/status_badge.dart';
import 'package:last/core/utils/phone_contact.dart';
import 'package:last/core/utils/validators.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/supervision_period.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/shared/widgets/supervision_period_card.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/officer/models/parolee_summary.dart';
import 'package:last/features/officer/services/officer_service.dart';
import 'package:last/features/shared/models/attendance_record.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';
import 'package:last/features/tracking/services/tracking_authorization_service.dart';
import 'package:last/features/tracking/widgets/parolee_live_tracking_section.dart';
import 'package:last/features/tracking/widgets/tracker_device_info_card.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/tracking_status.dart';

/// Officer-facing parolee profile with embedded live GPS tracker.
class ParoleeProfileScreen extends StatefulWidget {
  const ParoleeProfileScreen({
    super.key,
    required this.paroleeId,
    this.paroleeSummary,
  });

  final String paroleeId;
  final ParoleeSummary? paroleeSummary;

  @override
  State<ParoleeProfileScreen> createState() => _ParoleeProfileScreenState();
}

class _ParoleeProfileScreenState extends State<ParoleeProfileScreen> {
  final _officerService = createOfficerService();
  final _authService = TrackingAuthorizationService();

  AppUser? _parolee;
  AppUser? _assignedOfficer;
  bool _profileLoading = true;
  String? _profileError;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    context.read<TrackingProvider>().stopWatchingParolee();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _profileLoading = true;
      _profileError = null;
      _authError = null;
    });

    try {
      final requester = context.read<AuthProvider>().user;
      if (requester == null) return;

      final parolee = await _officerService.getUserById(widget.paroleeId);
      if (parolee == null) {
        setState(() {
          _profileError = 'Parolee not found.';
          _profileLoading = false;
        });
        return;
      }

      if (requester.role == UserRole.officer && !_authService.canTrack(requester, parolee)) {
        setState(() {
          _authError =
              "You are not authorized to view this parolee's tracking information.";
          _parolee = parolee;
          _profileLoading = false;
        });
        return;
      }

      AppUser? officer;
      if (parolee.officerId != null && parolee.officerId!.isNotEmpty) {
        officer = await _officerService.getUserById(parolee.officerId!);
      }

      if (mounted) {
        setState(() {
          _parolee = parolee;
          _assignedOfficer = officer;
          _profileLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profileError = 'Unable to load parolee profile.';
          _profileLoading = false;
        });
      }
    }
  }

  AttendanceStatus? get _attendanceStatus => widget.paroleeSummary?.status;

  bool get requesterIsOfficer =>
      context.read<AuthProvider>().user?.role == UserRole.officer;

  Future<void> _editSupervision(AppUser parolee) async {
    final actor = context.read<AuthProvider>().user;
    if (actor == null || actor.role != UserRole.officer) return;

    DateTime? start = parolee.supervision.start ?? DateTime.now();
    DateTime? end = parolee.supervision.end ?? DateTime.now().add(const Duration(days: 365));
    var suspended = parolee.supervisionIsSuspended;
    String? error;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> pick({required bool isStart}) async {
              final initial = isStart ? start! : end!;
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              setLocal(() {
                if (isStart) {
                  start = picked;
                } else {
                  end = picked;
                }
                error = Validators.supervisionRange(start, end);
              });
            }

            return AlertDialog(
              title: const Text('Supervision period'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start date'),
                      subtitle: Text(SupervisionPeriod.formatIso(start!)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () => pick(isStart: true),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End date'),
                      subtitle: Text(SupervisionPeriod.formatIso(end!)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () => pick(isStart: false),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Suspended'),
                      subtitle: const Text('Preserved until an officer clears it'),
                      value: suspended,
                      onChanged: (v) => setLocal(() => suspended = v),
                    ),
                    if (error != null)
                      Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final range = Validators.supervisionRange(start, end);
                    if (range != null) {
                      setLocal(() => error = range);
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) return;
    try {
      await _officerService.updateSupervisionPeriod(
        paroleeId: parolee.id,
        start: start!,
        end: end!,
        isSuspended: suspended,
        actorId: actor.id,
        actorRole: actor.role.name,
      );
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supervision period updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parolee = _parolee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parolee Profile'),
        backgroundColor: AppColors.officer,
        foregroundColor: Colors.white,
      ),
      body: _profileLoading
          ? const LoadingShimmer()
          : _profileError != null
              ? EmptyState(
                  icon: Icons.person_off,
                  title: 'Profile unavailable',
                  subtitle: _profileError,
                  actionLabel: 'Go Back',
                  onAction: () => context.pop(),
                )
              : parolee == null
                  ? const EmptyState(icon: Icons.person_off, title: 'Parolee not found')
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _ProfileHeader(
                            parolee: parolee,
                            attendanceStatus: _attendanceStatus,
                          ),
                          const SizedBox(height: 16),
                          if (_authError != null)
                            Card(
                              color: AppColors.error.withValues(alpha: 0.06),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_outline, color: AppColors.error.withValues(alpha: 0.8)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _authError!,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ParoleeLiveTrackingSection(paroleeId: widget.paroleeId),
                          const SizedBox(height: 12),
                          Selector<TrackingProvider, _TrackerDeviceData>(
                            selector: (_, p) {
                              final s = p.activeTracking?.paroleeId == widget.paroleeId
                                  ? p.activeTracking
                                  : null;
                              return _TrackerDeviceData(
                                tracker: s?.tracker,
                                status: s?.trackingStatus,
                              );
                            },
                            builder: (_, data, child) => TrackerDeviceInfoCard(
                              tracker: data.tracker,
                              trackingStatus: data.status,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoSection(
                            title: 'Personal Information',
                            rows: [
                              _InfoRow('Full Name', parolee.fullName),
                              _InfoRow('Email', parolee.email),
                              if (parolee.phone != null && parolee.phone!.isNotEmpty)
                                _InfoRow('Phone', parolee.phone!),
                            ],
                          ),
                          if (parolee.phone != null && parolee.phone!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => PhoneContact.call(parolee.phone),
                                    icon: const Icon(Icons.call_outlined, size: 18),
                                    label: const Text('Call'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => PhoneContact.sms(parolee.phone),
                                    icon: const Icon(Icons.sms_outlined, size: 18),
                                    label: const Text('SMS'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          SupervisionPeriodCard(
                            snapshot: parolee.supervision,
                            onEdit: requesterIsOfficer ? () => _editSupervision(parolee) : null,
                          ),
                          const SizedBox(height: 12),
                          _InfoSection(
                            title: 'Case Information',
                            rows: [
                              _InfoRow('Case Number', parolee.caseNumber ?? 'N/A'),
                              _InfoRow('Parolee ID', parolee.id),
                              _InfoRow('Status', parolee.isActive ? 'Active' : 'Inactive'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoSection(
                            title: 'Assigned Officer',
                            rows: [
                              _InfoRow(
                                'Officer',
                                _assignedOfficer?.fullName ?? 'Not assigned',
                              ),
                              if (_assignedOfficer?.email != null)
                                _InfoRow('Email', _assignedOfficer!.email),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _TrackerDeviceData {
  const _TrackerDeviceData({this.tracker, this.status});

  final GpsTracker? tracker;
  final TrackingStatus? status;

  @override
  bool operator ==(Object other) =>
      other is _TrackerDeviceData &&
      tracker?.id == other.tracker?.id &&
      tracker?.batteryLevel == other.tracker?.batteryLevel &&
      tracker?.lastSeenAt == other.tracker?.lastSeenAt &&
      status == other.status;

  @override
  int get hashCode => Object.hash(
        tracker?.id,
        tracker?.batteryLevel,
        tracker?.lastSeenAt,
        status,
      );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.parolee, this.attendanceStatus});

  final AppUser parolee;
  final AttendanceStatus? attendanceStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.officer.withValues(alpha: 0.12),
              foregroundColor: AppColors.officer,
              child: Text(
                parolee.initials,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              parolee.fullName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              parolee.caseNumber ?? 'No case number',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            if (attendanceStatus != null) ...[
              const SizedBox(height: 10),
              StatusBadge(status: attendanceStatus!),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(r.label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ),
                    Expanded(
                      child: Text(r.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}
