import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:last/features/reports/models/report_data.dart';

class PdfReportService {
  Future<void> previewAndShare(ReportData data) async {
    final doc = await buildDocument(data);
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  Future<void> share(ReportData data) async {
    final doc = await buildDocument(data);
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'ppa_attendance_report_${DateFormat('yyyyMMdd').format(data.generatedAt)}.pdf',
    );
  }

  Future<pw.Document> buildDocument(ReportData data) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('MMMM d, yyyy · h:mm a');
    final generated = dateFmt.format(data.generatedAt);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
          _header(generated),
          pw.SizedBox(height: 20),
          _sectionTitle('Attendance Summary'),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              _tableRow(['Metric', 'Value'], header: true),
              _tableRow(['Total Attendance Records', '${data.totalAttendance}']),
              _tableRow(['Total Check-ins', '${data.totalCheckIns}']),
              _tableRow(['Missed Attendance', '${data.missedCount}']),
              _tableRow(['Pending Today', '${data.pendingCount}']),
              _tableRow(['Compliance Rate', '${data.complianceRate.toStringAsFixed(1)}%']),
              _tableRow(['Attendance Rate', '${data.attendancePercentage.toStringAsFixed(1)}%']),
            ],
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Weekly Attendance'),
          pw.SizedBox(height: 8),
          _chartTable(data.weeklyPoints),
          pw.SizedBox(height: 20),
          _sectionTitle('Monthly Overview'),
          pw.SizedBox(height: 8),
          _chartTable(data.monthlyPoints),
          if (data.officerPerformance.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionTitle('Officer Performance'),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                _tableRow(
                  ['Officer', 'Parolees', 'Check-ins', 'Missed', 'Compliance'],
                  header: true,
                ),
                ...data.officerPerformance.map(
                  (o) => _tableRow([
                    o.officerName,
                    '${o.totalParolees}',
                    '${o.checkIns}',
                    '${o.missed}',
                    '${o.complianceRate.toStringAsFixed(1)}%',
                  ]),
                ),
              ],
            ),
          ],
          if (data.recentRecords.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionTitle('Recent Attendance Records'),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                _tableRow(
                  ['Ticket', 'Parolee', 'Status', 'Date'],
                  header: true,
                ),
                ...data.recentRecords.take(15).map((r) {
                  final date = r.checkInTime != null
                      ? DateFormat('MMM d, y').format(r.checkInTime!)
                      : '—';
                  return _tableRow([r.ticketId, r.paroleeName, r.status.label, date]);
                }),
              ],
            ),
          ],
          pw.SizedBox(height: 32),
          _signatorySection(),
        ],
      ),
    );

    return doc;
  }

  pw.Widget _header(String generated) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('1565C0'),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Parole and Probation Attendance Monitoring System',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Official Attendance & Compliance Report',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 11),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Generated: $generated', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.Text(
          'Republic of the Philippines — Parole & Probation Administration',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('00695C'),
        letterSpacing: 1,
      ),
    );
  }

  pw.TableRow _tableRow(List<String> cells, {bool header = false}) {
    return pw.TableRow(
      decoration: header
          ? pw.BoxDecoration(color: PdfColor.fromHex('EAEEF4'))
          : null,
      children: cells
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                c,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _chartTable(List<ChartPoint> points) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        _tableRow(['Period', 'Count'], header: true),
        ...points.map((p) => _tableRow([p.label, '${p.value.toInt()}'])),
      ],
    );
  }

  pw.Widget _signatorySection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(width: 180, height: 1, color: PdfColors.grey600),
            pw.SizedBox(height: 4),
            pw.Text('Prepared by:', style: pw.TextStyle(fontSize: 9)),
            pw.Text('PPA Supervising Officer', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(width: 180, height: 1, color: PdfColors.grey600),
            pw.SizedBox(height: 4),
            pw.Text('Approved by:', style: pw.TextStyle(fontSize: 9)),
            pw.Text('Chief Probation Officer', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
