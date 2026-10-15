import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicalDisclaimerBanner extends StatelessWidget {
  final bool isSinhala;

  const MedicalDisclaimerBanner({
    super.key,
    required this.isSinhala,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = isSinhala
        ? 'වෛද්‍යමය වගකීම් ප්‍රකාශය (Medical Disclaimer)'
        : 'Important Medical Disclaimer';

    final message = isSinhala
        ? 'මෙම AI විශ්ලේෂණය තොරතුරු සහ හඳුනාගැනීමේ සහාය සඳහා පමණි. ඖෂධ ලබා ගැනීමට හෝ ප්‍රතිකාර වෙනස් කිරීමට පෙර කරුණාකර අනිවාර්යයෙන්ම ලියාපදිංචි වෛද්‍යවරයකු හෝ ඖෂධවේදියකු (Pharmacist) හමුවී උපදෙස් ලබා ගන්න.'
        : 'This AI analysis is provided for informational and identification assistance only. Never self-prescribe or alter treatment without consulting a licensed physician or registered pharmacist.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1C0E) : const Color(0xFFFFF7EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF6B4515) : const Color(0xFFFFD199),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Color(0xFFE65100),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: (isSinhala
                          ? GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold)
                          : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))
                      .copyWith(
                    color: isDark ? const Color(0xFFFFCC80) : const Color(0xFFBF360C),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: (isSinhala
                          ? GoogleFonts.notoSansSinhala()
                          : GoogleFonts.plusJakartaSans())
                      .copyWith(
                    color: isDark ? const Color(0xFFFFE0B2) : const Color(0xFF4E342E),
                    fontSize: 12.5,
                    height: 1.4,
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
