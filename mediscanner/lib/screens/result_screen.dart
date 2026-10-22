import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/medicine_analysis_result.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/pdf_export_service.dart';
import '../services/tts_service.dart';
import '../widgets/medical_disclaimer_banner.dart';
import '../widgets/medicine_detail_card.dart';
import '../widgets/reminder_dialog.dart';

class ResultScreen extends StatefulWidget {
  final MedicineAnalysisResult result;

  const ResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TtsService _ttsService = TtsService();
  late MedicineAnalysisResult _currentResult;
  late int _pillCount;

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;
    _pillCount = _currentResult.remainingPills ?? 10;
    _tabController = TabController(length: 2, vsync: this);
    _ttsService.init();
    _ttsService.onStateChanged = () {
      if (mounted) setState(() {});
    };
    NotificationService().scheduleExpiryAlerts(_currentResult);
  }

  Future<void> _updatePillCount(int newCount) async {
    final count = newCount < 0 ? 0 : newCount;
    setState(() {
      _pillCount = count;
      _currentResult = _currentResult.copyWith(remainingPills: count);
    });
    await DatabaseService.updateRemainingPills(_currentResult.id, count);

    if (count <= 2) {
      await NotificationService().showRefillAlert(
        medicineName: _currentResult.english.brandName,
        remainingPills: count,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    count == 0 
                      ? 'ඖෂධ අවසන්! කරුණාකර ෆාමසියකින් ලබා ගන්න.'
                      : 'අවධානයයි: ඉතිරිව ඇත්තේ පෙති $count පමණි. Refill එකක් ලබා ගන්න.',
                    style: GoogleFonts.notoSansSinhala(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _showSetPillCountDialog() async {
    final controller = TextEditingController(text: _pillCount.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFF00696B)),
            const SizedBox(width: 8),
            Text(
              'Set Pill Count / පෙති ගණන',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter total number of tablets/capsules in this pack:',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Remaining Pills (ඉතිරි පෙති)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.medication_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00696B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null && parsed >= 0) {
                Navigator.pop(context, parsed);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updatePillCount(result);
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    _tabController.dispose();
    super.dispose();
  }

  void _shareResult() {
    final res = widget.result;
    final isSinhalaTab = _tabController.index == 0;
    final data = isSinhalaTab ? res.sinhala : res.english;

    final buffer = StringBuffer();
    buffer.writeln('📋 MedScan AI - Medicine Analysis Report');
    buffer.writeln('=======================================');
    buffer.writeln('🏷️ Brand Name: ${data.brandName}');
    buffer.writeln('🧪 Generic/Active: ${data.genericName}');
    buffer.writeln('⚖️ Strength: ${data.dosageStrength}');
    buffer.writeln('📦 Package Type: ${res.packageType}');
    buffer.writeln('🏭 Manufacturer: ${res.identifiedManufacturer}');
    buffer.writeln('\n🩺 Clinical Uses / භාවිත:');
    for (final use in data.clinicalUses) {
      buffer.writeln(' • $use');
    }
    buffer.writeln('\n💊 Usage Instructions / උපදෙස්:');
    buffer.writeln(data.usageInstructions);
    buffer.writeln('\n⚠️ Side Effects / අතුරු ආබාධ:');
    for (final se in data.sideEffects) {
      buffer.writeln(' • $se');
    }
    buffer.writeln('\n🛡️ Precautions / පූර්වාරක්ෂාවන්:');
    for (final pre in data.precautions) {
      buffer.writeln(' • $pre');
    }
    buffer.writeln('\n🌡️ Storage / ගබඩා කිරීම:');
    buffer.writeln(data.storageGuidelines);

    if (data.unreadableNotice != null && data.unreadableNotice!.isNotEmpty) {
      buffer.writeln('\n🔍 OCR Note:');
      buffer.writeln(data.unreadableNotice);
    }

    buffer.writeln('\n---------------------------------------');
    buffer.writeln('⚠️ Medical Disclaimer: Always consult a licensed doctor or pharmacist before taking any medication.');

    Share.share(buffer.toString(), subject: 'MedScan AI Report - ${data.brandName}');
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return const Color(0xFF2E7D32); // Green
      case 'moderate':
        return const Color(0xFF0288D1); // Blue
      case 'low':
        return const Color(0xFFE65100); // Orange
      default:
        return const Color(0xFFC62828); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final res = widget.result;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analysis Results',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_add_rounded),
            tooltip: 'Set Dose Reminder (මාත්‍රා මතක් කිරීම්)',
            onPressed: () {
              ReminderDialog.show(
                context,
                medicineName: res.english.brandName,
                isSinhala: _tabController.index == 0,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF Report',
            onPressed: () {
              PdfExportService.exportMedicineReport(
                result: res,
                isSinhala: _tabController.index == 0,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Report',
            onPressed: _shareResult,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Done',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Overview Card
                    _buildOverviewHeader(isDark),
                    const SizedBox(height: 14),

                    // Uncertainty Warning if not recognized or blurry
                    if (!res.isMedicine || res.confidenceRating.toLowerCase() == 'uncertain')
                      _buildUncertaintyNotice(isDark),

                    // Material 3 TabBar Container
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2828) : const Color(0xFFE8F2F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelPadding: EdgeInsets.zero,
                        indicator: BoxDecoration(
                          color: isDark ? const Color(0xFF00696B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: isDark ? Colors.white : const Color(0xFF00696B),
                        unselectedLabelColor: isDark ? const Color(0xFF8C9E9E) : const Color(0xFF5A6B6B),
                        tabs: [
                          Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.language_rounded, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'සිංහල (Sinhala)',
                                      style: GoogleFonts.notoSansSinhala(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.translate_rounded, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'English',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Sinhala
            _buildLanguageContent(
              data: res.sinhala,
              isSinhala: true,
              isDark: isDark,
            ),
            // Tab 2: English
            _buildLanguageContent(
              data: res.english,
              isSinhala: false,
              isDark: isDark,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00696B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text(
              'Scan Another Medicine',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewHeader(bool isDark) {
    final res = widget.result;
    final confColor = _getConfidenceColor(res.confidenceRating);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F20) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF283636) : const Color(0xFFE2EDED),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image thumbnail or placeholder icon
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: res.imagePath != null && File(res.imagePath!).existsSync()
                ? Image.file(
                    File(res.imagePath!),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFF00696B).withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.medication_liquid_rounded,
                      color: Color(0xFF00696B),
                      size: 36,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          // Metadata tags & Package type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: confColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_outlined, size: 13, color: confColor),
                          const SizedBox(width: 4),
                          Text(
                            'Confidence: ${res.confidenceRating}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: confColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0288D1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          res.packageType,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0288D1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  res.english.brandName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF191C1C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mfr: ${res.identifiedManufacturer}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF90A1A1) : const Color(0xFF5A6A6A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUncertaintyNotice(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Label text appears partially blurry or obscured. The AI has provided best-effort identification, but please inspect the physical package and consult a pharmacist.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFFBF360C),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageContent({
    required MedicineLanguageData data,
    required bool isSinhala,
    required bool isDark,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Prominent Medical Disclaimer Banner
        MedicalDisclaimerBanner(isSinhala: isSinhala),

        // 2. Voice Reader (Text-to-Speech) Audio Bar
        _buildVoiceReaderBar(data: data, isSinhala: isSinhala, isDark: isDark),

        // 3. Unreadable / OCR Notice Card (if any text was blurry or obscured)
        if (data.unreadableNotice != null && data.unreadableNotice!.trim().isNotEmpty)
          MedicineDetailCard(
            title: isSinhala ? 'ලේබල කියවීමේ සටහන (OCR Clarification)' : 'Label Readability Notice',
            icon: Icons.visibility_off_outlined,
            accentColor: const Color(0xFFE65100),
            isSinhala: isSinhala,
            contentText: data.unreadableNotice,
            badgeText: isSinhala ? 'අවධානය' : 'Notice',
          ),

        // 3. Brand & Active Ingredients Card
        MedicineDetailCard(
          title: isSinhala ? 'වෙළඳ නාමය සහ ක්‍රියාකාරී ද්‍රව්‍ය' : 'Brand & Active Ingredients',
          icon: Icons.medication_rounded,
          accentColor: const Color(0xFF00696B),
          isSinhala: isSinhala,
          badgeText: isSinhala ? 'මූලික තොරතුරු' : 'Core Details',
          customContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                label: isSinhala ? 'වෙළඳ නාමය (Brand):' : 'Brand Name:',
                value: data.brandName,
                isHighlight: true,
                isSinhala: isSinhala,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                label: isSinhala ? 'ක්‍රියාකාරී රසායනික (Active):' : 'Active Generic:',
                value: data.genericName,
                isSinhala: isSinhala,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                label: isSinhala ? 'මාත්‍රාව සහ ප්‍රබලතාව (Strength):' : 'Dosage Strength:',
                value: data.dosageStrength,
                isSinhala: isSinhala,
                isDark: isDark,
              ),
            ],
          ),
        ),

        // 4. Clinical Uses / Indications
        MedicineDetailCard(
          title: isSinhala ? 'භාවිතය සඳහා රෝග තත්ත්ව (Clinical Uses)' : 'Clinical Indications & Uses',
          icon: Icons.healing_rounded,
          accentColor: const Color(0xFF0288D1),
          isSinhala: isSinhala,
          bulletPoints: data.clinicalUses,
        ),

        // 5. Usage Instructions
        MedicineDetailCard(
          title: isSinhala ? 'භාවිතය සඳහා උපදෙස් (Usage Instructions)' : 'General Usage Instructions',
          icon: Icons.schedule_rounded,
          accentColor: const Color(0xFF00796B),
          isSinhala: isSinhala,
          contentText: data.usageInstructions,
        ),

        // 6. Side Effects
        MedicineDetailCard(
          title: isSinhala ? 'හැකියාවක් ඇති අතුරු ආබාධ (Side Effects)' : 'Potential Side Effects',
          icon: Icons.error_outline_rounded,
          accentColor: const Color(0xFFE65100),
          isSinhala: isSinhala,
          bulletPoints: data.sideEffects,
        ),

        // 7. Precautions & Warnings
        MedicineDetailCard(
          title: isSinhala ? 'පූර්වාරක්ෂාවන් සහ අනතුරු ඇඟවීම් (Precautions)' : 'Precautions & Warnings',
          icon: Icons.shield_outlined,
          accentColor: const Color(0xFFC62828),
          isSinhala: isSinhala,
          bulletPoints: data.precautions,
        ),

        // 8. Storage Guidelines
        MedicineDetailCard(
          title: isSinhala ? 'ගබඩා කිරීමේ උපදෙස් (Storage Guidelines)' : 'Proper Storage Guidelines',
          icon: Icons.thermostat_outlined,
          accentColor: const Color(0xFF5E35B1),
          isSinhala: isSinhala,
          contentText: data.storageGuidelines,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isSinhala,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF8C9E9E) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: (isSinhala
                  ? GoogleFonts.notoSansSinhala(
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                    )
                  : GoogleFonts.plusJakartaSans(
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                    ))
              .copyWith(
            fontSize: isHighlight ? 16 : 14,
            color: isHighlight
                ? (isDark ? const Color(0xFF80DEEA) : const Color(0xFF00696B))
                : (isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceReaderBar({
    required MedicineLanguageData data,
    required bool isSinhala,
    required bool isDark,
  }) {
    final isPlaying = _ttsService.state == TtsState.playing;

    final speechBuffer = StringBuffer();
    if (isSinhala) {
      speechBuffer.write('ඖෂධයේ නම: ${data.brandName}. ');
      speechBuffer.write('ක්‍රියාකාරී රසායනික ද්‍රව්‍ය: ${data.genericName}. ');
      speechBuffer.write('මාත්‍රාව: ${data.dosageStrength}. ');
      speechBuffer.write('භාවිතය සඳහා උපදෙස්: ${data.usageInstructions}. ');
      if (data.precautions.isNotEmpty) {
        speechBuffer.write('පූර්වාරක්ෂාවන්: ${data.precautions.join(", ")}. ');
      }
    } else {
      speechBuffer.write('Medicine: ${data.brandName}. ');
      speechBuffer.write('Active generic: ${data.genericName}, ${data.dosageStrength}. ');
      speechBuffer.write('Instructions: ${data.usageInstructions}. ');
      if (data.precautions.isNotEmpty) {
        speechBuffer.write('Precautions: ${data.precautions.join(", ")}. ');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF142424) : const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF00696B) : const Color(0xFF80CBC4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF00696B),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: 20,
                color: Colors.white,
              ),
              onPressed: () {
                if (isPlaying) {
                  _ttsService.stop();
                } else {
                  _ttsService.speak(
                    text: speechBuffer.toString(),
                    isSinhala: isSinhala,
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlaying
                      ? (isSinhala ? 'හඬින් කියවමින් පවතී...' : 'Reading aloud...')
                      : (isSinhala ? 'හඬින් අසන්න (Audio Voice Reader)' : 'Audio Voice Reader'),
                  style: (isSinhala
                          ? GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold)
                          : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))
                      .copyWith(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF004D40),
                  ),
                ),
                Text(
                  isPlaying
                      ? (isSinhala ? 'නැවැත්වීමට Stop ඔබන්න' : 'Tap stop to pause')
                      : (isSinhala ? 'විස්තරය ශ්‍රවණය කිරීමට Play ඔබන්න' : 'Listen to instructions aloud'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF80CBC4) : const Color(0xFF00696B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
