import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/activities/models/activity_attendance_record.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/models/activity_qr_payload.dart';
import 'package:last/features/activities/widgets/participation_status_chip.dart';

class ParoleeActivityQrCard extends StatelessWidget {
  const ParoleeActivityQrCard({
    super.key,
    required this.activity,
    required this.qr,
    required this.loading,
    required this.onRetry,
    required this.onRegenerate,
    this.error,
    this.attendanceStatus,
  });

  final ActivityModel activity;
  final ActivityQrPayload? qr;
  final bool loading;
  final VoidCallback onRetry;
  final VoidCallback onRegenerate;
  final String? error;
  final ActivityParticipationStatus? attendanceStatus;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d, yyyy · h:mm a');
    final qrData = qr?.encode();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.parolee.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Activity QR', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      SizedBox(height: 4),
                      Text(
                        'Present this QR code to an authorized officer when verification is required.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (attendanceStatus != null) ParticipationStatusChip(status: attendanceStatus!),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.event, activity.title),
            _detailRow(Icons.schedule, dateFmt.format(activity.scheduleDate)),
            _detailRow(Icons.place_outlined, activity.location),
            if (activity.officerName != null)
              _detailRow(Icons.badge_outlined, activity.officerName!),
            const SizedBox(height: 16),
            _statusChip(
              loading
                  ? 'Loading'
                  : (qrData != null && qrData.isNotEmpty)
                      ? 'Available'
                      : 'Not yet generated',
            ),
            const SizedBox(height: 16),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null && error!.isNotEmpty)
              _errorState(error!)
            else if (qrData == null || qrData.isEmpty)
              _emptyState()
            else
              _qrDisplay(qrData, qr!),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    final available = label == 'Available';
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        visualDensity: VisualDensity.compact,
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: available
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.textMuted.withValues(alpha: 0.12),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.parolee),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Column(
      children: [
        const Icon(Icons.qr_code_2, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 8),
        const Text('Not yet generated', style: TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.qr_code),
          label: const Text('Generate QR'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.parolee),
        ),
      ],
    );
  }

  Widget _qrDisplay(String qrData, ActivityQrPayload payload) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              gapless: true,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(payload.paroleeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        Text(
          payload.activityTitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          'This code stays the same until you regenerate it. It does not include your password or personal details.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.9)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRegenerate,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Regenerate QR'),
        ),
      ],
    );
  }
}
