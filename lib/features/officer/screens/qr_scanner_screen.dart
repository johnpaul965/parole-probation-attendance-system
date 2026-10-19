import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/officer/providers/dashboard_provider.dart';
import 'package:last/features/parolee/providers/attendance_provider.dart';
import 'package:last/features/tracking/providers/tracking_provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<AuthProvider>().user?.id;
      if (id != null) context.read<AttendanceProvider>().watch(officerId: id);
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null) return;
    setState(() => _processing = true);
    final officer = context.read<AuthProvider>().user!;
    final result = await context.read<AttendanceProvider>().verifyQr(raw, officer);
    if (!mounted) return;
    setState(() => _processing = false);
    if (result != null) {
      context.read<TrackingProvider>().beginCheckInSession(
            paroleeId: result.paroleeId,
            sessionId: result.ticketId,
          );
      await context.read<DashboardProvider>().refresh(officer.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.paroleeName} is now confirmed on your dashboard.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _controller.stop();
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          title: const Text('Verified'),
          content: Text('Ticket ${result.ticketId} confirmed for ${result.paroleeName}.'),
          actions: [
            TextButton(onPressed: () {
              Navigator.pop(ctx);
              _controller.start();
            }, child: const Text('Scan Another')),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<AttendanceProvider>().error ?? 'Verification failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppColors.officer,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
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
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
              child: Text(
                _processing ? 'Verifying...' : 'Align parolee QR code within frame',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
