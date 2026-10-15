import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medicine_analysis_result.dart';
import '../services/api_key_service.dart';
import '../services/gemini_service.dart';
import '../services/history_service.dart';
import '../widgets/api_key_modal.dart';
import '../widgets/scan_guide_sheet.dart';
import 'history_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _hasApiKey = false;
  bool _isAnalyzing = false;
  String _analysisStatus = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await ApiKeyService.hasApiKey();
    setState(() => _hasApiKey = hasKey);
  }

  /// Capture image from Camera or Gallery with automatic optimization
  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    // If no API key configured, prompt the user first
    if (!_hasApiKey) {
      final proceed = await _showApiKeyRequiredPrompt();
      if (!proceed) return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600, // Optimized for Gemini Multimodal OCR clarity & payload speed
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) return; // User cancelled

      setState(() {
        _isAnalyzing = true;
        _analysisStatus = 'Preparing medicine photograph...';
      });

      final bytes = await pickedFile.readAsBytes();
      final mimeType = pickedFile.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

      setState(() {
        _analysisStatus = 'Extracting label text with Gemini Vision...';
      });

      // Analyze with Gemini Multimodal Vision API
      final result = await GeminiService.analyzeMedicineImage(
        imageBytes: bytes,
        mimeType: mimeType,
        localImagePath: pickedFile.path,
      );

      setState(() {
        _analysisStatus = 'Formatting bilingual insights (Sinhala & English)...';
      });

      // Persist to local history
      await HistoryService.saveResult(result);

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      // Open Result Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<bool> _showApiKeyRequiredPrompt() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: Color(0xFF00696B)),
            SizedBox(width: 8),
            Text('API Key Needed'),
          ],
        ),
        content: const Text(
          'To scan medicine labels using the Google Gemini Vision API (gemini-1.5-flash), please provide your free API key from Google AI Studio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00696B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context, true);
              ApiKeyModal.show(context, onKeySaved: _checkApiKey);
            },
            child: const Text('Set Up Key'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Scan Notice'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          if (message.contains('API key'))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ApiKeyModal.show(context, onKeySaved: _checkApiKey);
              },
              child: const Text('Configure API Key'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Launch Demo Sample to inspect the full Dual-Tab Sinhala/English UI instantly
  void _openSampleDemo() {
    final sample = MedicineAnalysisResult.createSample();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(result: sample),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF00696B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MedScan AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                Text(
                  'ඖෂධ හඳුනාගැනීම (Bilingual)',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 10.5,
                    color: const Color(0xFF00696B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // API Key status button
          IconButton(
            tooltip: _hasApiKey ? 'Gemini API Key Configured' : 'Set Gemini API Key',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.vpn_key_rounded),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _hasApiKey ? const Color(0xFF2E7D32) : Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => ApiKeyModal.show(context, onKeySaved: _checkApiKey),
          ),
          // Best practices guide button
          IconButton(
            tooltip: 'Scanning Tips',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => ScanGuideSheet.show(context),
          ),
          // History button
          IconButton(
            tooltip: 'Scan History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Welcome / Mode Header
                _buildHeroBanner(isDark),
                const SizedBox(height: 20),

                // Viewfinder / Interactive Camera Area
                _buildScanTargetVisual(isDark),
                const SizedBox(height: 24),

                // Main Capture Action Buttons
                _buildCaptureButtons(isDark),
                const SizedBox(height: 24),

                // Supported Medicine Types Section
                _buildSupportedTypesCard(isDark),
                const SizedBox(height: 16),

                // Quick Demo Sample Button
                _buildDemoButton(isDark),
                const SizedBox(height: 28),
              ],
            ),
          ),

          // Loading Overlay during Vision Analysis
          if (_isAnalyzing) _buildAnalyzingOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF003737), const Color(0xFF004D40)]
              : [const Color(0xFFE0F2F1), const Color(0xFFE8F5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF00696B) : const Color(0xFFB2DFDB),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00696B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'MULTIMODAL VISION AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Photograph & Decipher Any Medicine',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF003737),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'පෙති, බිබිලි තීරු, සිරප් බෝතල් හෝ ආලේපන සිංහලෙන් සහ ඉංග්‍රීසියෙන් ක්ෂණිකව හඳුනාගන්න.',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFB2DFDB) : const Color(0xFF004D40),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF004D40) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF00696B),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTargetVisual(bool isDark) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141C1C) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF233232) : const Color(0xFFE2EBEB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00696B).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Viewfinder Corner Brackets
            Positioned(
              top: 16,
              left: 16,
              child: _buildCornerBracket(isTop: true, isLeft: true),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _buildCornerBracket(isTop: true, isLeft: false),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildCornerBracket(isTop: false, isLeft: true),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildCornerBracket(isTop: false, isLeft: false),
            ),

            // Center Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00696B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 44,
                    color: Color(0xFF00696B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Align Medicine Package Here',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF191C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'පැහැදිලි ආලෝකය යටතේ ඡායාරූපගත කරන්න',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF8C9E9E) : const Color(0xFF6C7C7C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    const double size = 22;
    const double thickness = 3.5;
    const Color color = Color(0xFF00696B);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          left: isLeft ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCaptureButtons(bool isDark) {
    return Row(
      children: [
        // Camera Button
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00696B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            onPressed: () => _pickAndAnalyzeImage(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_rounded, size: 22),
            label: const Text(
              'Camera Scan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Gallery Button
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00696B),
              side: const BorderSide(color: Color(0xFF00696B), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _pickAndAnalyzeImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text(
              'Gallery',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportedTypesCard(bool isDark) {
    final types = [
      {'icon': Icons.medical_services_outlined, 'name': 'Tablets & Pills\n(පෙති වර්ග)'},
      {'icon': Icons.view_column_rounded, 'name': 'Blister Strips\n(බිබිලි තීරු)'},
      {'icon': Icons.vaccines_outlined, 'name': 'Syrup Bottles\n(සිරප් වර්ග)'},
      {'icon': Icons.healing_outlined, 'name': 'Ointment Tubes\n(ආලේපන)'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F20) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF283636) : const Color(0xFFE2EDED),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supported Formats (හඳුනාගත හැකි වර්ග)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: types.map((item) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00696B).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: const Color(0xFF00696B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['name'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: isDark ? const Color(0xFF8C9E9E) : const Color(0xFF5A6B6B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButton(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182222) : const Color(0xFFF1F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3838) : const Color(0xFFD4E5E5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: Color(0xFF0288D1),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore Sample Analysis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Preview dual-tab Sinhala & English results instantly',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF8C9E9E) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openSampleDemo,
            child: const Text('Try Demo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingOverlay(bool isDark) {
    return Container(
      color: Colors.black.withOpacity(0.65),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2424) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00696B)),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Analyzing Medicine Label',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _analysisStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF8C9E9E) : const Color(0xFF5A6A6A),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00696B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Powered by Google Gemini Multimodal Vision',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00696B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
