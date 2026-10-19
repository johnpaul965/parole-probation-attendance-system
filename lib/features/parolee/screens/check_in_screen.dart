import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/providers/activity_attendance_provider.dart';
import 'package:last/features/activities/providers/activity_provider.dart';
import 'package:last/features/activities/widgets/activity_card.dart';
import 'package:last/features/activities/widgets/parolee_activity_qr_card.dart';
import 'package:last/features/auth/providers/auth_provider.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String? _qrRequestedForId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    context.read<ActivityProvider>().listenForParolee(user.id);
    context.read<ActivityAttendanceProvider>().listenForParolee(user.id);
  }

  List<ActivityModel> _upcoming(List<ActivityModel> all, String paroleeId) {
    final list = all
        .where(
          (a) =>
              a.isAssignedTo(paroleeId) &&
              (a.status == ActivityStatus.pending || a.status == ActivityStatus.ongoing),
        )
        .toList()
      ..sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));
    return list;
  }

  Future<void> _loadQr(ActivityModel activity, {bool rotate = false}) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    await context.read<ActivityAttendanceProvider>().loadParoleeQr(
          activity: activity,
          parolee: user,
          officerIdOverride: activity.assignedOfficerId.isNotEmpty
              ? activity.assignedOfficerId
              : user.officerId,
          rotate: rotate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final activities = context.watch<ActivityProvider>();
    final attendance = context.watch<ActivityAttendanceProvider>();
    final upcoming = _upcoming(activities.activities, user.id);
    final next = upcoming.isNotEmpty ? upcoming.first : null;
    final rest = upcoming.length > 1 ? upcoming.sublist(1) : const <ActivityModel>[];

    if (next != null &&
        attendance.qrForActivity(next.id) == null &&
        !attendance.isQrLoading &&
        _qrRequestedForId != next.id) {
      _qrRequestedForId = next.id;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadQr(next));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance Check-in'),
        backgroundColor: AppColors.parolee,
        foregroundColor: Colors.white,
      ),
      body: activities.isLoading && activities.activities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : upcoming.isEmpty
              ? const EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No activities assigned',
                  subtitle:
                      'Your officer will assign community or counseling activities here. Check-in QR codes appear on those assignments.',
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Show this QR at the activity your officer assigned. Scanning is done from that activity.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    ParoleeActivityQrCard(
                      activity: next!,
                      qr: attendance.qrForActivity(next.id) ?? attendance.currentQr,
                      loading: attendance.isQrLoading &&
                          (attendance.qrForActivity(next.id) == null),
                      error: attendance.qrError,
                      onRetry: () => _loadQr(next),
                      onRegenerate: () => _loadQr(next, rotate: true),
                      attendanceStatus: attendance.recordFor(next.id, user.id)?.status,
                    ),
                    if (rest.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Other assigned activities',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...rest.map(
                        (a) => ActivityCard(
                          activity: a,
                          subtitle: 'Show QR to officer',
                          onTap: () => context.push('/parolee/activities/${a.id}', extra: a),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
