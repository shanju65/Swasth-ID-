import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/document_model.dart';

class PdfService {
  static Future<void> generateAndShareVisitPdf(VisitGroup visit) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMM yyyy').format(visit.visitDate);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Medical Visit Report',
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('Swasth ID Digital Health Record',
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('Visit ID: ${visit.visitId}',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 20),

              // Patient / Facility Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildInfoSection('Facility Information', [
                      'Facility: ${visit.facilityName ?? "N/A"}',
                      'Location: ${visit.district ?? ""}, ${visit.state ?? ""}',
                      'Department: ${visit.visitType ?? "Consultation"}',
                    ]),
                  ),
                  pw.Expanded(
                    child: _buildInfoSection('Provider Details', [
                      'Doctor: ${visit.doctorName != "-" ? visit.doctorName : "N/A"}',
                      'Specialization: ${visit.specialization ?? "General"}',
                    ]),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Clinical Vitals
              if (visit.temperature != null || visit.bp != null || visit.spo2 != null) ...[
                pw.Text('Clinical Vitals',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      if (visit.temperature != null) _buildVitalPdf('Temperature', '${visit.temperature}°C'),
                      if (visit.bp != null) _buildVitalPdf('Blood Pressure', visit.bp!),
                      if (visit.spo2 != null) _buildVitalPdf('SpO2', '${visit.spo2}%'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Medical Reason
              pw.Text('Visit Summary',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.SizedBox(height: 10),
              pw.Text('Chief Complaint:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(visit.diagnosis),
              pw.SizedBox(height: 10),
              if (visit.symptoms != null && visit.symptoms!.isNotEmpty) ...[
                pw.Text('Symptoms:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(visit.symptoms!),
                pw.SizedBox(height: 10),
              ],

              // Vaccination
              if (visit.vaccineGiven) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Vaccination Administered',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                      pw.Text('Vaccine: ${visit.vaccineName ?? "N/A"}'),
                      if (visit.nextDoseDate != null) pw.Text('Next Dose Due: ${visit.nextDoseDate}'),
                    ],
                  ),
                ),
              ],

              // Referral
              if (visit.referred) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.orange),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Referral Information',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                      pw.Text('Referred To: ${visit.referredTo ?? "N/A"}'),
                      pw.Text('Reason: ${visit.referralReason ?? "N/A"}'),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Generated by Swasth ID App on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              ),
            ],
          );
        },
      ),
    );

    final filename = 'swasth_visit_${dateStr.replaceAll(' ', '_')}.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  static pw.Widget _buildInfoSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 5),
        ...items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(item, style: const pw.TextStyle(fontSize: 10)),
            )),
      ],
    );
  }

  static pw.Widget _buildVitalPdf(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
