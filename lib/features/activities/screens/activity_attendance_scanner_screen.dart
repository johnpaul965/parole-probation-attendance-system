import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/activities/models/activity_attendance_record.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/providers/activity_attendance_provider.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/officer/services/officer_service.dart';
import 'package:last/features/shared/widgets/supervision_period_card.dart';

class ActivityAttendanceScannerScreen extends StatefulWidget {
  const ActivityAttendanceScannerScreen({super.key, required this.activity});

  final ActivityModel activity;

  @override
  State<ActivityAttendanceScannerScreen> createState() =>
      _ActivityAttendanceScannerScreenState();
}

class _ActivityAttendanceScannerScreenState extends State<ActivityAttendanceScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.role != UserRole.officer) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only officers can scan activity attendance')),
        );
        return;
      }
      context.read<ActivityAttendanceProvider>().listenForActivity(widget.activity.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    setState(() => _processing = true);
    final status = await _showStatusDialog();
    if (!mounted) return;
    if (status == null) {
      setState(() => _processing = false);
      return;
    }

    final officer = context.read<AuthProvider>().user!;
    final result = await context.read<ActivityAttendanceProvider>().scanQr(
          rawQr: raw,
          officer: officer,
          activity: widget.activity,
          status: status,
        );

    if (!mounted) return;
    setState(() => _processing = false);

    if (result.isSuccess) {
      await _controller.stop();
      if (!mounted) return;
      final scannedUser =
          await createOfficerService().getUserById(result.record!.paroleeId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.success, size: 52),
          title: const Text('Attendance Recorded'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.record!.paroleeName} marked as ${result.record!.status.label} for ${widget.activity.title}.',
              ),
              if (scannedUser != null) ...[
                const SizedBox(height: 12),
                SupervisionPeriodCard(
                  snapshot: scannedUser.supervision,
                  compact: true,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _controller.start();
              },
              child: const Text('Scan Another'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.record!.paroleeName} — ${result.record!.status.label}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Scan failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<ActivityParticipationStatus?> _showStatusDialog() async {
    ActivityParticipationStatus selected = ActivityParticipationStatus.present;
    return showDialog<ActivityParticipationStatus>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirm Attendance Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<ActivityParticipationStatus>(
                groupValue: selected,
                onChanged: (v) {
                  if (v != null) setState(() => selected = v);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ActivityParticipationStatus.values
                      .where((s) => s != ActivityParticipationStatus.pending)
                      .map(
                        (s) => RadioListTile<ActivityParticipationStatus>(
                          value: s,
                          title: Text(s.label),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<ActivityAttendanceProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.officer,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity QR Scanner', style: TextStyle(fontSize: 16)),
            Text(
              widget.activity.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.officer.withValues(alpha: 0.08),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Present', attendance.stats.present),
                _stat('Late', attendance.stats.late),
                _stat('Absent', attendance.stats.absent),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                      ),
                    ),
                    child: Text(
                      _processing
                          ? 'Validating QR...'
                          : 'Scan parolee activity QR — only officers can mark attendance',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
                if (_processing)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Column(
      children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
