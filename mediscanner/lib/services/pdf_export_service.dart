import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/medicine_analysis_result.dart';

class PdfExportService {
  /// Generate and present a beautifully styled, crystal-clear PDF report
  /// with complete Sinhala & English Unicode font support.
  static Future<void> exportMedicineReport({
    required MedicineAnalysisResult result,
    required bool isSinhala,
  }) async {
    final theme = await _buildTheme();
    final pdf = pw.Document(theme: theme);
    final data = isSinhala ? result.sinhala : result.english;
    final secondaryData = isSinhala ? result.english : result.sinhala;

    // Load scanned medicine image if available
    pw.MemoryImage? scannedImage;
    if (!kIsWeb && result.imagePath != null && result.imagePath!.isNotEmpty) {
      try {
        final file = File(result.imagePath!);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          scannedImage = pw.MemoryImage(bytes);
        }
      } catch (_) {}
    }

    // Format date string safely
    final dateStr =
        '${result.timestamp.day.toString().padLeft(2, '0')}/${result.timestamp.month.toString().padLeft(2, '0')}/${result.timestamp.year}';
    final reportId = result.id.length > 8
        ? result.id.substring(0, 8).toUpperCase()
        : result.id.toUpperCase();

    // Theme color palette
    final primaryColor = PdfColor.fromHex('00696B');
    final darkTextColor = PdfColor.fromHex('0F172A');
    final secondaryTextColor = PdfColor.fromHex('475569');
    final cardBgColor = PdfColor.fromHex('F8FAFC');
    final borderColor = PdfColor.fromHex('CBD5E1');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 14),
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            '+ Rx',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          isSinhala
                              ? 'MedScan AI • සායනික ඖෂධ වාර්තාව'
                              : 'MedScan AI • Clinical Insight Report',
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'AI-Assisted Medicine Identification & Pharmaceutical Analysis',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.teal50,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      dateStr,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'ID: #$reportId',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.teal50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MedScan AI Vision System • Confidential Medical Identification Assistance',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          // Display secondary brand name cleanly if different
          final hasSecondaryBrand = secondaryData.brandName.isNotEmpty &&
              secondaryData.brandName.toLowerCase() != data.brandName.toLowerCase() &&
              secondaryData.brandName.toLowerCase() != 'unknown';

          return [
            // Core Details Hero Card
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: cardBgColor,
                border: pw.Border.all(color: borderColor, width: 1),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: Medicine Information
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Badges Row (Formulation & Confidence)
                        pw.Row(
                          children: [
                            _buildPillBadge(
                              result.packageType,
                              bgColor: PdfColor.fromHex('E0F2FE'),
                              textColor: PdfColor.fromHex('0369A1'),
                            ),
                            pw.SizedBox(width: 6),
                            _buildPillBadge(
                              '${result.confidenceRating} Confidence',
                              bgColor: result.confidenceRating.toLowerCase() == 'high'
                                  ? PdfColor.fromHex('DCFCE7')
                                  : PdfColor.fromHex('FEF3C7'),
                              textColor: result.confidenceRating.toLowerCase() == 'high'
                                  ? PdfColor.fromHex('15803D')
                                  : PdfColor.fromHex('B45309'),
                            ),
                            if (result.remainingPills != null) ...[
                              pw.SizedBox(width: 6),
                              _buildPillBadge(
                                '${result.remainingPills} Units Left',
                                bgColor: PdfColor.fromHex('F3E8FF'),
                                textColor: PdfColor.fromHex('7E22CE'),
                              ),
                            ],
                          ],
                        ),
                        pw.SizedBox(height: 8),

                        // Brand Name
                        pw.Text(
                          data.brandName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: darkTextColor,
                          ),
                        ),
                        if (hasSecondaryBrand) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '(${secondaryData.brandName})',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 10),

                        // Key Specs Table Grid
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: _buildInfoItem(
                                isSinhala ? 'සක්‍රීය අමුද්‍රව්‍ය (Generic)' : 'ACTIVE INGREDIENT',
                                data.genericName,
                                isHighlighted: true,
                              ),
                            ),
                            pw.SizedBox(width: 10),
                            pw.Expanded(
                              child: _buildInfoItem(
                                isSinhala ? 'මාත්‍රාව සහ ශක්තිය' : 'STRENGTH / DOSAGE',
                                data.dosageStrength,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),

                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: _buildInfoItem(
                                isSinhala ? 'නිෂ්පාදකයා' : 'MANUFACTURER',
                                result.identifiedManufacturer,
                              ),
                            ),
                            pw.SizedBox(width: 10),
                            pw.Expanded(
                              child: pw.Row(
                                children: [
                                  if (result.batchNumber != null &&
                                      result.batchNumber!.isNotEmpty)
                                    pw.Expanded(
                                      child: _buildInfoItem(
                                        isSinhala ? 'කාණ්ඩ අංකය' : 'BATCH NO.',
                                        result.batchNumber!,
                                      ),
                                    ),
                                  if (result.expiryDate != null &&
                                      result.expiryDate!.isNotEmpty) ...[
                                    pw.SizedBox(width: 6),
                                    pw.Expanded(
                                      child: _buildInfoItem(
                                        isSinhala ? 'කල් ඉකුත් වීම' : 'EXPIRY DATE',
                                        result.expiryDate!,
                                        isDanger: true,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        // SPC Generic Alternative if available
                        if (data.spcGenericAlternative != null &&
                            data.spcGenericAlternative!.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('F0FDF4'),
                              border: pw.Border.all(color: PdfColor.fromHex('BBF7D0')),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              isSinhala
                                  ? 'රාජ්‍ය ඖෂධ නීතිගත සංස්ථාවේ (SPC) ආදේශකය: ${data.spcGenericAlternative}'
                                  : 'SPC Generic Equivalent: ${data.spcGenericAlternative}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('166534'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Right: Optional Scanned Image Thumbnail
                  if (scannedImage != null) ...[
                    pw.SizedBox(width: 12),
                    pw.Container(
                      width: 72,
                      height: 72,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 5,
                        verticalRadius: 5,
                        child: pw.Image(scannedImage, fit: pw.BoxFit.cover),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Section 1: Clinical Indications & Uses
            _buildSectionHeader(
              title: isSinhala
                  ? '1. සායනික භාවිතයන් සහ රෝග ලක්ෂණ (Clinical Indications)'
                  : '1. Clinical Uses & Indications',
              color: primaryColor,
            ),
            pw.SizedBox(height: 6),
            ...data.clinicalUses.map(
              (use) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 6, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 4, right: 6),
                      width: 5,
                      height: 5,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        use,
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          color: darkTextColor,
                          lineSpacing: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // Section 2: Dosage & Administration
            _buildSectionHeader(
              title: isSinhala
                  ? '2. භාවිතා කළ යුතු ආකාරය සහ මාත්‍රාව (Directions for Use)'
                  : '2. General Usage & Administration Instructions',
              color: primaryColor,
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F0FDFA'),
                border: pw.Border.all(color: PdfColor.fromHex('99F6E4')),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                data.usageInstructions,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  color: darkTextColor,
                  lineSpacing: 1.35,
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // Section 3: Precautions & Warnings
            _buildSectionHeader(
              title: isSinhala
                  ? '3. පූර්වාරක්ෂාව සහ විශේෂ අවවාද (Precautions & Warnings)'
                  : '3. Precautions & Safety Warnings',
              color: PdfColor.fromHex('C2410C'),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('FFFBEB'),
                border: pw.Border.all(color: PdfColor.fromHex('FDE68A')),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  ...data.precautions.map(
                    (pre) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '• ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('B45309'),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              pre,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: darkTextColor,
                                lineSpacing: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (data.dietaryWarnings.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    ...data.dietaryWarnings.map(
                      (diet) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text(
                          isSinhala ? 'ආහාරමය අනතුරු ඇඟවීම: $diet' : 'Dietary Note: $diet',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('B45309'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Section 4: Possible Side Effects (if any)
            if (data.sideEffects.isNotEmpty) ...[
              _buildSectionHeader(
                title: isSinhala
                    ? '4. විය හැකි අතුරු ආබාධ (Possible Side Effects)'
                    : '4. Possible Side Effects',
                color: PdfColor.fromHex('475569'),
              ),
              pw.SizedBox(height: 6),
              ...data.sideEffects.map(
                (se) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 6, bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 4, right: 6),
                        width: 4,
                        height: 4,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey700,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          se,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: darkTextColor,
                            lineSpacing: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            // Section 5: Storage Guidelines
            _buildSectionHeader(
              title: isSinhala
                  ? '5. ගබඩා කිරීම පිළිබඳ උපදෙස් (Storage Guidelines)'
                  : '5. Storage & Handling Guidelines',
              color: primaryColor,
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F1F5F9'),
                border: pw.Border.all(color: PdfColor.fromHex('E2E8F0')),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                data.storageGuidelines,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: darkTextColor,
                  lineSpacing: 1.3,
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            // Clinical Safety Disclaimer Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('FFFBEB'),
                border: pw.Border.all(color: PdfColor.fromHex('FCD34D')),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: const pw.EdgeInsets.only(right: 8, top: 1),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('F59E0B'),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      '!',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isSinhala
                              ? 'වෛද්‍යමය වගකීම් ප්‍රකාශය (Medical Disclaimer)'
                              : 'CLINICAL SAFETY DISCLAIMER',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('92400E'),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          isSinhala
                              ? 'මෙම ස්වයංක්‍රීය වාර්තාව MedScan AI මඟින් හඳුනාගැනීමේ සහාය පිණිස පමණක් සකස් කර ඇත. කිසිදු ඖෂධයක් භාවිතයට පෙර සෑමවිටම සුදුසුකම් ලත් වෛද්‍යවරයෙකුගේ හෝ ලියාපදිංචි ඖෂධවේදියෙකුගේ උපදෙස් ලබාගන්න.'
                              : 'This automated report is generated by MedScan AI vision intelligence for informational identification assistance only. Always consult a qualified medical doctor or registered pharmacist before consuming or changing medication dosages.',
                          style: pw.TextStyle(
                            fontSize: 7.8,
                            color: PdfColor.fromHex('78350F'),
                            lineSpacing: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Present native printing or PDF saving dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'MedScan_Report_${result.english.brandName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')}.pdf',
    );
  }

  /// Build a robust typography theme with Noto Sans Sinhala font fallback
  /// so that all Sinhala, Latin characters, and symbols render crisp and clear.
  static Future<pw.ThemeData> _buildTheme() async {
    pw.Font? sinhalaRegular;
    pw.Font? sinhalaBold;

    // 1. Try loading from bundled local assets first (instant, guaranteed offline)
    try {
      final regData = await rootBundle.load('assets/fonts/NotoSansSinhala-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSansSinhala-Bold.ttf');
      sinhalaRegular = pw.Font.ttf(regData.buffer.asByteData());
      sinhalaBold = pw.Font.ttf(boldData.buffer.asByteData());
    } catch (_) {
      // 2. Fallback to Google Fonts CDN if local asset bundle is unavailable
      try {
        sinhalaRegular = await PdfGoogleFonts.notoSansSinhalaRegular();
        sinhalaBold = await PdfGoogleFonts.notoSansSinhalaBold();
      } catch (_) {}
    }

    final fallbacks = <pw.Font>[];
    if (sinhalaRegular != null) fallbacks.add(sinhalaRegular);
    if (sinhalaBold != null) fallbacks.add(sinhalaBold);

    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      fontFallback: fallbacks,
    );
  }

  /// Section title banner with accent indicator
  static pw.Widget _buildSectionHeader({
    required String title,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('F1F5F9'),
        border: pw.Border(left: pw.BorderSide(color: color, width: 3.5)),
        borderRadius: const pw.BorderRadius.only(
          topRight: pw.Radius.circular(4),
          bottomRight: pw.Radius.circular(4),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Clean labeled information block with proper typography
  static pw.Widget _buildInfoItem(
    String label,
    String value, {
    bool isHighlighted = false,
    bool isDanger = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value.isEmpty ? 'N/A' : value,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: isDanger
                ? PdfColor.fromHex('B91C1C')
                : (isHighlighted ? PdfColor.fromHex('0F766E') : PdfColor.fromHex('1E293B')),
          ),
        ),
      ],
    );
  }

  /// Small rounded badge widget for status tags
  static pw.Widget _buildPillBadge(
    String text, {
    required PdfColor bgColor,
    required PdfColor textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
