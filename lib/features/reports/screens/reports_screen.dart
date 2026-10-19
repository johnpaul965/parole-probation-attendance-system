import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/core/widgets/empty_state.dart';
import 'package:last/core/widgets/loading_shimmer.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/reports/providers/reports_provider.dart';
import 'package:last/features/reports/services/pdf_report_service.dart';
import 'package:last/features/reports/widgets/attendance_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.officerId});

  final String? officerId;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _pdfService = PdfReportService();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    final auth = context.read<AuthProvider>();
    final officerId = widget.officerId ??
        (auth.user?.role == UserRole.officer ? auth.user?.id : null);
    context.read<ReportsProvider>().startListening(officerId: officerId);
  }

  Future<void> _exportPdf() async {
    final data = context.read<ReportsProvider>().data;
    if (data == null) return;
    setState(() => _exporting = true);
    try {
      await _pdfService.previewAndShare(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _sharePdf() async {
    final data = context.read<ReportsProvider>().data;
    if (data == null) return;
    setState(() => _exporting = true);
    try {
      await _pdfService.share(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportsProvider>();
    final data = reports.data;
    final isOfficer = context.watch<AuthProvider>().user?.role == UserRole.officer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: AppColors.reports,
        foregroundColor: Colors.white,
        actions: [
          if (isOfficer) ...[
            if (_exporting)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Preview PDF',
                onPressed: data == null ? null : _exportPdf,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share PDF',
                onPressed: data == null ? null : _sharePdf,
              ),
            ],
          ],
        ],
      ),
      body: reports.isLoading && data == null
          ? const LoadingShimmer()
          : reports.error != null && data == null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: reports.error!,
                  actionLabel: 'Retry',
                  onAction: _start,
                )
              : data == null
                  ? const EmptyState(icon: Icons.bar_chart, title: 'No report data')
                  : RefreshIndicator(
                      onRefresh: () async => _start(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (isOfficer)
                            Card(
                              color: AppColors.reports.withValues(alpha: 0.08),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf, color: AppColors.reports),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Export official attendance report as PDF',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: _exporting ? null : _exportPdf,
                                      style: FilledButton.styleFrom(backgroundColor: AppColors.reports),
                                      child: const Text('Export'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (isOfficer) const SizedBox(height: 12),
                          Row(
                            children: [
                              _MetricCard(
                                label: 'Compliance',
                                value: '${data.complianceRate.toStringAsFixed(1)}%',
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              _MetricCard(
                                label: 'Attendance',
                                value: '${data.attendancePercentage.toStringAsFixed(0)}%',
                                color: AppColors.officer,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _MetricCard(
                                label: 'Check-ins',
                                value: '${data.totalCheckIns}',
                                color: AppColors.reports,
                              ),
                              const SizedBox(width: 8),
                              _MetricCard(
                                label: 'Missed',
                                value: '${data.missedCount}',
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              _MetricCard(
                                label: 'Pending',
                                value: '${data.pendingCount}',
                                color: AppColors.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AttendanceChart(
                            points: data.weeklyPoints,
                            title: 'Weekly Attendance',
                          ),
                          const SizedBox(height: 12),
                          AttendanceChart(
                            points: data.monthlyPoints,
                            title: 'Monthly Overview',
                            barColor: AppColors.officer,
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
