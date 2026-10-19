import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/providers/activity_attendance_provider.dart';
import 'package:last/features/activities/providers/activity_provider.dart';
import 'package:last/features/activities/widgets/activity_attendance_panel.dart';
import 'package:last/features/activities/widgets/activity_status_chip.dart';
import 'package:last/features/activities/widgets/assign_parolee_dialog.dart';
import 'package:last/features/activities/widgets/parolee_activity_qr_card.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/officer/providers/dashboard_provider.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key, required this.activity});

  final ActivityModel activity;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _qrAutoRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListeners());
  }

  void _startListeners() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final activities = context.read<ActivityProvider>();
    if (user.role == UserRole.parolee) {
      activities.listenForParolee(user.id);
    }

    final attendance = context.read<ActivityAttendanceProvider>();
    if (user.role == UserRole.officer) {
      attendance.listenForActivity(widget.activity.id);
    } else if (user.role == UserRole.parolee) {
      attendance.listenForParolee(user.id);
      if (widget.activity.isAssignedTo(user.id)) {
        _loadQr();
      }
    } else {
      attendance.listenForActivity(widget.activity.id);
    }
  }

  Future<void> _loadQr({bool rotate = false}) async {
    final user = context.read<AuthProvider>().user!;
    final matches =
        context.read<ActivityProvider>().activities.where((a) => a.id == widget.activity.id);
    final live = matches.isNotEmpty ? matches.first : widget.activity;

    await context.read<ActivityAttendanceProvider>().loadParoleeQr(
          activity: live,
          parolee: user,
          officerIdOverride: live.assignedOfficerId.isNotEmpty
              ? live.assignedOfficerId
              : user.officerId,
          rotate: rotate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final matches =
        context.watch<ActivityProvider>().activities.where((a) => a.id == widget.activity.id);
    final live = matches.isNotEmpty ? matches.first : widget.activity;
    final attendance = context.watch<ActivityAttendanceProvider>();
    final activityRecords =
        attendance.records.where((r) => r.activityId == live.id).toList();
    final dateFmt = DateFormat('EEEE, MMMM d, yyyy · h:mm a');
    final isOfficer = user.role == UserRole.officer;
    final isParolee = user.role == UserRole.parolee;
    final myRecord = isParolee ? attendance.recordFor(live.id, user.id) : null;
    final qrPayload = attendance.qrForActivity(live.id) ?? attendance.currentQr;

    if (isParolee &&
        live.isAssignedTo(user.id) &&
        qrPayload == null &&
        !attendance.isQrLoading &&
        attendance.qrError == null &&
        !_qrAutoRequested) {
      _qrAutoRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadQr());
    }

    final paroleeNames = <String, String>{};
    if (isOfficer) {
      for (final p in context.read<DashboardProvider>().parolees) {
        paroleeNames[p.id] = p.fullName;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(live.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(live.type.label, style: const TextStyle(color: AppColors.textMuted)),
              ),
              ActivityStatusChip(status: live.status),
            ],
          ),
          const SizedBox(height: 16),
          _tile(Icons.description_outlined, 'Description', live.description),
          _tile(Icons.place_outlined, 'Location', live.location),
          _tile(Icons.schedule, 'Schedule', dateFmt.format(live.scheduleDate)),
          if (live.officerName != null)
            _tile(Icons.badge_outlined, 'Officer', live.officerName!),
          const SizedBox(height: 16),
          const Text('Participation', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: live.totalAssigned == 0 ? 0 : live.completionRate / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: AppColors.success,
          ),
          const SizedBox(height: 4),
          Text(
            '${live.totalCompleted} of ${live.totalAssigned} marked present (${live.completionRate.toStringAsFixed(0)}%)',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          if (isParolee && live.isAssignedTo(user.id)) ...[
            const SizedBox(height: 20),
            ParoleeActivityQrCard(
              activity: live,
              qr: qrPayload,
              loading: attendance.isQrLoading,
              error: attendance.qrError,
              onRetry: _loadQr,
              onRegenerate: () => _loadQr(rotate: true),
              attendanceStatus: myRecord?.status,
            ),
            if (myRecord != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user, color: AppColors.success),
                  title: const Text('Your attendance status'),
                  subtitle: Text(
                    'Recorded ${myRecord.scannedAt.toLocal().toString().substring(0, 16)} by officer',
                  ),
                  trailing: Text(
                    myRecord.status.label,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Attendance can only be marked when your officer scans your QR code.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ],
          if (isOfficer) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/officer/activities/${live.id}/scan', extra: live),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Activity Attendance'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.officer,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Attendance Roster', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ActivityAttendancePanel(
              records: activityRecords,
              stats: attendance.stats,
              assignedParoleeIds: live.assignedParoleeIds,
              paroleeNames: paroleeNames,
            ),
            const SizedBox(height: 24),
            const Text('Update Activity Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ActivityStatus.values.map((s) {
                return ChoiceChip(
                  label: Text(s.label),
                  selected: live.status == s,
                  onSelected: (_) async {
                    await context.read<ActivityProvider>().updateStatus(live.id, s);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Status updated to ${s.label}')),
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final parolees = context.read<DashboardProvider>().parolees;
                final ids = await showDialog<List<String>>(
                  context: context,
                  builder: (_) => AssignParoleeDialog(
                    parolees: parolees,
                    activity: live,
                  ),
                );
                if (ids != null && context.mounted) {
                  await context.read<ActivityProvider>().assignParolees(live.id, ids);
                }
              },
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Assign Parolees'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
