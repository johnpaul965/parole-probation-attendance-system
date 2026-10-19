import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/gradient_header.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/officer/services/officer_service.dart';
import 'package:last/features/shared/widgets/supervision_period_card.dart';
import 'package:last/features/parolee/providers/attendance_provider.dart';
import 'package:last/features/parolee/providers/parolee_provider.dart';
import 'package:last/features/shared/models/attendance_record.dart';
import 'package:last/features/parolee/widgets/share_location_card.dart';

class ParoleeDashboardScreen extends StatefulWidget {
  const ParoleeDashboardScreen({super.key});

  @override
  State<ParoleeDashboardScreen> createState() => _ParoleeDashboardScreenState();
}

class _ParoleeDashboardScreenState extends State<ParoleeDashboardScreen> {
  final _officerService = createOfficerService();
  AppUser? _latestProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    context.read<AttendanceProvider>().watch(paroleeId: user.id);
    context.read<ParoleeProvider>().startListening(
      paroleeId: user.id,
      officerId: user.officerId,
      attendanceRecords: context.read<AttendanceProvider>().records,
    );
    try {
      final fresh = await _officerService.getUserById(user.id);
      if (mounted && fresh != null) {
        setState(() => _latestProfile = fresh);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user!;
    final user = _latestProfile ?? authUser;
    final attendance = context.watch<AttendanceProvider>();
    final parolee = context.watch<ParoleeProvider>();

    if (attendance.records.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ParoleeProvider>().updateCompliance(attendance.records);
      });
    }

    final lastRecord = attendance.records.isNotEmpty ? attendance.records.first : null;
    final nextSchedule = parolee.nextSchedule;
    final officer = parolee.assignedOfficer;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => _start(),
        child: ListView(
          children: [
            GradientHeader(
              color: AppColors.parolee,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome back,', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          Text(user.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                          if (user.caseNumber != null)
                            Text(user.caseNumber!, style: const TextStyle(fontSize: 11, color: Colors.white60)),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Text(user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (officer != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Officer: ${officer.fullName}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/parolee/check-in'),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Activity check-in QR'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.parolee,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SupervisionPeriodCard(
                    snapshot: user.supervision,
                    paroleeFacing: true,
                  ),
                  const SizedBox(height: 16),
                  const ShareLocationCard(),
                  const SizedBox(height: 16),
                  if (attendance.isLoading && lastRecord == null)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (attendance.error != null && lastRecord == null)
                    Card(
                      child: ListTile(
                        title: Text(attendance.error!),
                        trailing: TextButton(onPressed: _start, child: const Text('Retry')),
                      ),
                    )
                  else if (lastRecord != null) ...[
                    const Text('LAST CHECK-IN', style: _label),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.verified_user, color: AppColors.success),
                        title: Text(lastRecord.ticketId, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          lastRecord.checkInTime != null
                              ? DateFormat('MMM d, y · h:mm a').format(lastRecord.checkInTime!)
                              : 'Pending',
                        ),
                        trailing: Text(
                          lastRecord.verified ? 'Verified' : 'Awaiting',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: lastRecord.verified ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (nextSchedule != null) ...[
                    const Text('NEXT SCHEDULE', style: _label),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today, color: AppColors.parolee),
                        title: Text(nextSchedule.type, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${DateFormat('EEEE, MMM d').format(nextSchedule.scheduledAt)}\n${nextSchedule.location}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('ACTIVITIES', style: _label),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_available_outlined, color: AppColors.parolee),
                      title: const Text('My Activities', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('View assigned community service & counseling'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/parolee/activities'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('COMPLIANCE', style: _label),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up, color: AppColors.success, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${parolee.complianceRate.toStringAsFixed(0)}% Compliance',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                Text(
                                  attendance.records.isEmpty
                                      ? 'No attendance records yet'
                                      : '${attendance.records.where((r) => r.status != AttendanceStatus.missed).length} of ${attendance.records.length} check-ins on time',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _label = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8);
