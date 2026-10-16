import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_key_service.dart';
import '../services/gemini_service.dart';

class InteractionCheckerScreen extends StatefulWidget {
  const InteractionCheckerScreen({super.key});

  @override
  State<InteractionCheckerScreen> createState() => _InteractionCheckerScreenState();
}

class _InteractionCheckerScreenState extends State<InteractionCheckerScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageA;
  XFile? _imageB;
  bool _isChecking = false;
  String? _analysisResult;
  String? _riskLevel; // 'Low / Safe', 'Moderate Caution', 'High Danger'

  Future<void> _pickImage(int medicineSlot, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          if (medicineSlot == 1) {
            _imageA = picked;
          } else {
            _imageB = picked;
          }
          _analysisResult = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _analyzeInteraction() async {
    if (_imageA == null || _imageB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please photograph or select both medicines to check interaction.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final hasApiKey = await ApiKeyService.hasApiKey();
    if (!hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure your Gemini API Key in Settings first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isChecking = true);

    try {
      final bytesA = await _imageA!.readAsBytes();
      final bytesB = await _imageB!.readAsBytes();

      final text = await GeminiService.checkDrugInteraction(
        bytesA: bytesA,
        bytesB: bytesB,
      );

      // Determine approximate risk level
      String risk = 'Moderate Caution';
      if (text.toLowerCase().contains('severe danger') || text.toLowerCase().contains('ඉතා අනතුරුදායකයි')) {
        risk = 'Severe Danger';
      } else if (text.toLowerCase().contains('safe') || text.toLowerCase().contains('ආරක්ෂිතයි')) {
        risk = 'Safe / Low Risk';
      }

      setState(() {
        _analysisResult = text;
        _riskLevel = risk;
        _isChecking = false;
      });
    } catch (e) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Interaction check error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _loadSampleData() {
    setState(() {
      _riskLevel = 'Moderate Caution';
      _analysisResult = '''
🔍 ඖෂධ අන්තර්ක්‍රියා විශ්ලේෂණය (Drug Interaction Analysis)
============================================================

1. සිංහලෙන් (Sinhala):
• ඖෂධ 1: Paracetamol 500mg
• ඖෂධ 2: Ibuprofen 400mg
• අවදානම් මට්ටම: ප්‍රවේශම් වන්න (Moderate Caution)
• වෛද්‍ය පැහැදිලි කිරීම: පැරසිටමෝල් සහ අයිබියුප්‍රොෆෙන් කෙටි කාලීන උණ සහ දැඩි වේදනා පාලනය සඳහා වෛද්‍ය උපදෙස් මත මාරුවෙන් මාරුවට ලබා ගත හැකි වුවත්, එකවර හෝ දිගු කාලීනව අධික මාත්‍රාවෙන් ගැනීම ආමාශයේ තුවාල (Gastritis/Ulcers) සහ වකුගඩු වලට ආතතියක් ඇති කළ හැක.
• නිර්දේශය: හිස්බඩ නොගන්න. වතුර වීදුරුවක් සමඟ ආහාර ගැනීමෙන් පසු ලබා ගන්න. දින 3කට වඩා වේදනාව පවතී නම් වෛද්‍යවරයකු හමුවන්න.

2. In English:
• Medicine 1: Paracetamol (Acetaminophen) 500mg
• Medicine 2: Ibuprofen (NSAID) 400mg
• Risk Level: Moderate Caution
• Clinical Mechanism: Concurrent use does not cause direct chemical antagonism, but additive renal strain and GI mucosal irritation can occur with prolonged or unmonitored high doses.
• Recommendation: Stagger administration if advised by a physician. Never exceed maximum daily paracetamol limits (4000mg/day).

⚠️ Medical Disclaimer: Always consult a doctor before combining prescription drugs.
''';
    });
  }

  Color _getRiskColor() {
    if (_riskLevel == null) return Colors.grey;
    if (_riskLevel!.contains('Danger') || _riskLevel!.contains('අනතුරුදායකයි')) {
      return const Color(0xFFC62828);
    }
    if (_riskLevel!.contains('Safe') || _riskLevel!.contains('ආරක්ෂිතයි')) {
      return const Color(0xFF2E7D32);
    }
    return const Color(0xFFE65100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Drug Interaction Checker',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _loadSampleData,
            child: const Text('Sample', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2323) : const Color(0xFFE8F4F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C3C3C) : const Color(0xFFC7E2E2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, color: Color(0xFF00696B), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dual Medicine Safety Scan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF003737),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'බෙහෙත් වර්ග දෙකක් එකවර ගැනීම ආරක්ෂිතදැයි පරික්ෂා කරන්න.',
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF90A1A1) : const Color(0xFF4A5E5E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Two slots for medicines
            Row(
              children: [
                Expanded(child: _buildMedicinePickerCard(1, _imageA, 'Medicine A (1 වන බෙහෙත)', isDark)),
                const SizedBox(width: 12),
                Expanded(child: _buildMedicinePickerCard(2, _imageB, 'Medicine B (2 වන බෙහෙත)', isDark)),
              ],
            ),
            const SizedBox(height: 20),

            // Check Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00696B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isChecking ? null : _analyzeInteraction,
                icon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.security_rounded),
                label: Text(
                  _isChecking ? 'Checking Interactions...' : 'Check Interaction (පරීක්ෂා කරන්න)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results Section
            if (_analysisResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161F20) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _getRiskColor(), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _getRiskColor().withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Risk Tag
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRiskColor().withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Risk Level: ${_riskLevel ?? "Analyzed"}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getRiskColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _analysisResult!,
                      style: (isDark ? GoogleFonts.notoSansSinhala(color: Colors.white) : GoogleFonts.notoSansSinhala(color: const Color(0xFF1E293B)))
                          .copyWith(fontSize: 13.5, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinePickerCard(int slot, XFile? file, String label, bool isDark) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C1C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF283636) : const Color(0xFFD2E0E0),
        ),
      ),
      child: file != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(file.path), fit: BoxFit.cover),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 14, color: Colors.white),
                      onPressed: () => setState(() {
                        if (slot == 1) _imageA = null;
                        if (slot == 2) _imageB = null;
                      }),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication_rounded, size: 36, color: const Color(0xFF00696B).withValues(alpha: 0.7)),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFBAC8C8) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, size: 20),
                      color: const Color(0xFF00696B),
                      onPressed: () => _pickImage(slot, ImageSource.camera),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined, size: 20),
                      color: const Color(0xFF00696B),
                      onPressed: () => _pickImage(slot, ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
