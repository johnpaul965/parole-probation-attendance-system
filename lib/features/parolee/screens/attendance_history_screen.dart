import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/core/widgets/status_badge.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/parolee/providers/attendance_provider.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<AuthProvider>().user?.id;
      if (id != null) context.read<AttendanceProvider>().watch(paroleeId: id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: AppColors.parolee,
        foregroundColor: Colors.white,
      ),
      body: attendance.isLoading && attendance.records.isEmpty
          ? const LoadingShimmer()
          : attendance.error != null && attendance.records.isEmpty
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: attendance.error!,
                  actionLabel: 'Retry',
                  onAction: () {
                    final id = context.read<AuthProvider>().user!.id;
                    context.read<AttendanceProvider>().watch(paroleeId: id);
                  },
                )
              : attendance.records.isEmpty
                  ? const EmptyState(
                      icon: Icons.history,
                      title: 'No attendance records',
                      subtitle: 'Complete a check-in to see history',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: attendance.records.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final r = attendance.records[i];
                        return Card(
                          child: ListTile(
                            title: Text(r.ticketId, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              r.checkInTime != null
                                  ? DateFormat('MMM d, y · h:mm a').format(r.checkInTime!)
                                  : r.location ?? '',
                            ),
                            trailing: StatusBadge(status: r.status),
                          ),
                        );
                      },
                    ),
    );
  }
}
