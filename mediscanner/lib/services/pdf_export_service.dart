import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/medicine_analysis_result.dart';

class PdfExportService {
  /// Generate and present PDF report for printing or sharing
  static Future<void> exportMedicineReport({
    required MedicineAnalysisResult result,
    required bool isSinhala,
  }) async {
    final pdf = pw.Document();
    final data = isSinhala ? result.sinhala : result.english;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('00696B'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MedScan AI — Clinical Insight Report',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'AI-Assisted Medicine Identification & Analysis',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      '${result.timestamp.day}/${result.timestamp.month}/${result.timestamp.year}',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Core Details Card
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfField('Brand Name', data.brandName),
                        ),
                        pw.Expanded(
                          child: _buildPdfField('Formulation Type', result.packageType),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfField('Active Ingredients', data.genericName),
                        ),
                        pw.Expanded(
                          child: _buildPdfField('Strength', data.dosageStrength),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    _buildPdfField('Manufacturer', result.identifiedManufacturer),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Clinical Indications
              _buildSectionTitle('1. Clinical Uses & Indications'),
              pw.SizedBox(height: 4),
              ...data.clinicalUses.map(
                (use) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                  child: pw.Text('• $use', style: const pw.TextStyle(fontSize: 10.5)),
                ),
              ),
              pw.SizedBox(height: 10),

              // Usage Instructions
              _buildSectionTitle('2. General Usage & Administration Instructions'),
              pw.SizedBox(height: 4),
              pw.Text(
                data.usageInstructions,
                style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 1.3),
              ),
              pw.SizedBox(height: 10),

              // Precautions
              _buildSectionTitle('3. Precautions & Warnings'),
              pw.SizedBox(height: 4),
              ...data.precautions.map(
                (pre) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                  child: pw.Text('• $pre', style: const pw.TextStyle(fontSize: 10)),
                ),
              ),
              pw.SizedBox(height: 10),

              // Side Effects & Storage
              _buildSectionTitle('4. Storage Guidelines'),
              pw.SizedBox(height: 4),
              pw.Text(data.storageGuidelines, style: const pw.TextStyle(fontSize: 10)),
              pw.Spacer(),

              // Medical Disclaimer Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'MEDICAL DISCLAIMER: This automated document is for informational identification assistance only. Always consult a qualified medical doctor or registered pharmacist before consuming any medication.',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber900,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Present native printing / saving dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'MedScan_Report_${result.english.brandName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
      ),
    );
  }

  static pw.Widget _buildPdfField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}
