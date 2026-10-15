import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanGuideSheet extends StatelessWidget {
  const ScanGuideSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ScanGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tips = [
      {
        'icon': Icons.wb_sunny_outlined,
        'title': 'Good Natural Lighting (හොඳ ආලෝකය)',
        'desc': 'Avoid strong shadows or excessive direct flash glare on glossy blister foils or glass bottles.',
      },
      {
        'icon': Icons.center_focus_strong_rounded,
        'title': 'Focus on Brand & Strengths (පැහැදිලි නාමය)',
        'desc': 'Frame the brand name (e.g., Amoxil, Panadol) and strength (e.g., 500mg) squarely inside the lens.',
      },
      {
        'icon': Icons.crop_free_rounded,
        'title': 'Embossed Tablets (මුද්‍රිත පෙති)',
        'desc': 'For loose pills, illuminate from the side so engraved letters and dosage numbers cast contrast.',
      },
      {
        'icon': Icons.autorenew_rounded,
        'title': 'Syrups & Ointments (සිරප් සහ ආලේපන)',
        'desc': 'Rotate the bottle or tube so the active composition table is clearly visible to the camera.',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C1C) : Colors.white,
        borderRadius: const verticalTopRadius(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374646) : const Color(0xFFCFDADA),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00696B).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tips_and_updates_outlined,
                  color: Color(0xFF00696B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Scanning Practices',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF191C1C),
                      ),
                    ),
                    Text(
                      'නිවැරදි තොරතුරු ලබා ගැනීමට උපදෙස්',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8C9E9E) : const Color(0xFF5F6E6E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1D2828) : const Color(0xFFF0F7F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tip['icon'] as IconData,
                      size: 20,
                      color: const Color(0xFF00696B),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF191C1C),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tip['desc'] as String,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: isDark ? const Color(0xFF9EAEAE) : const Color(0xFF566767),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00696B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it! (තේරුම් ගත්තා)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

BorderRadius verticalTopRadius(double r) => BorderRadius.vertical(top: Radius.circular(r));
