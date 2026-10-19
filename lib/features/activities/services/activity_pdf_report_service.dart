import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:last/features/activities/models/activity_attendance_record.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/auth/models/app_user.dart';

class ActivityPdfReportService {
  Future<void> previewAndShare({
    required List<ActivityModel> activities,
    required List<AppUser> officers,
    required List<AppUser> parolees,
    List<ActivityAttendanceRecord> attendance = const [],
  }) async {
    final doc = await buildDocument(
      activities: activities,
      officers: officers,
      parolees: parolees,
      attendance: attendance,
    );
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  Future<pw.Document> buildDocument({
    required List<ActivityModel> activities,
    required List<AppUser> officers,
    required List<AppUser> parolees,
    List<ActivityAttendanceRecord> attendance = const [],
  }) async {
    final doc = pw.Document();
    final generated = DateFormat('MMMM d, yyyy · h:mm a').format(DateTime.now());
    final dateFmt = DateFormat('MMM d, yyyy · h:mm a');

    final total = activities.length;
    final ongoing = activities.where((a) => a.status == ActivityStatus.ongoing).length;
    final completed = activities.where((a) => a.status == ActivityStatus.completed).length;
    final missed = activities.where((a) => a.status == ActivityStatus.missed).length;
    final pending = activities.where((a) => a.status == ActivityStatus.pending).length;
    final present = attendance.where((r) => r.status == ActivityParticipationStatus.present).length;
    final late = attendance.where((r) => r.status == ActivityParticipationStatus.late).length;
    final absent = attendance.where((r) => r.status == ActivityParticipationStatus.absent).length;

    String officerName(String id) {
      final o = officers.where((u) => u.id == id).toList();
      if (o.isNotEmpty) return o.first.fullName;
      final act = activities.where((a) => a.assignedOfficerId == id).toList();
      return act.isNotEmpty ? (act.first.officerName ?? id) : id;
    }

    String paroleeNames(List<String> ids) {
      return ids
          .map((id) {
            final p = parolees.where((u) => u.id == id).toList();
            return p.isEmpty ? id : p.first.fullName;
          })
          .join(', ');
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'REPUBLIC OF THE PHILIPPINES',
                  style: pw.TextStyle(fontSize: 9, letterSpacing: 1),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'PAROLE AND PROBATION ADMINISTRATION',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Community Activity Monitoring Report',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text('Generated: $generated', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text('Analytics Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              _row(['Metric', 'Count'], header: true),
              _row(['Total Activities', '$total']),
              _row(['Ongoing', '$ongoing']),
              _row(['Completed', '$completed']),
              _row(['Missed', '$missed']),
              _row(['Pending', '$pending']),
              _row(['QR Present', '$present']),
              _row(['QR Late', '$late']),
              _row(['QR Absent', '$absent']),
            ],
          ),
          if (attendance.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Officer Attendance Logs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                _row(['Parolee', 'Activity', 'Status', 'Scanned'], header: true),
                ...attendance.take(50).map(
                      (r) => _row([
                        r.paroleeName,
                        r.activityTitle ?? r.activityId,
                        r.status.label,
                        dateFmt.format(r.scannedAt),
                      ]),
                    ),
              ],
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Text('Activity Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              _row(
                ['Title', 'Type', 'Officer', 'Status'],
                header: true,
              ),
              ...activities.map(
                (a) => _row([
                  a.title,
                  a.type.label,
                  officerName(a.assignedOfficerId),
                  a.status.label,
                ]),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          ...activities.map((a) {
            final missedIds = a.assignedParoleeIds
                .where((id) => !a.completedParoleeIds.contains(id))
                .toList();
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(a.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 4),
                pw.Text('Schedule: ${dateFmt.format(a.scheduleDate)}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Location: ${a.location}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Assigned Officer: ${officerName(a.assignedOfficerId)}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Parolees: ${paroleeNames(a.assignedParoleeIds)}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(
                  'Completion Rate: ${a.completionRate.toStringAsFixed(1)}% (${a.totalCompleted}/${a.totalAssigned})',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if (missedIds.isNotEmpty && a.status == ActivityStatus.missed)
                  pw.Text(
                    'Missed Participants: ${paroleeNames(missedIds)}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.red800),
                  ),
                pw.Divider(),
              ],
            );
          }),
          pw.SizedBox(height: 32),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 180, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Prepared By', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('Supervising Officer', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 180, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Approved By', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('PPA Regional Director', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return doc;
  }

  pw.TableRow _row(List<String> cells, {bool header = false}) {
    return pw.TableRow(
      decoration: header ? const pw.BoxDecoration(color: PdfColors.grey200) : null,
      children: cells
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                c,
                style: pw.TextStyle(
                  fontSize: header ? 9 : 8,
                  fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
