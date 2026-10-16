import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalTermsOnboardingModal extends StatelessWidget {
  final VoidCallback onAccepted;

  const MedicalTermsOnboardingModal({
    super.key,
    required this.onAccepted,
  });

  static const String _acceptedPrefKey = 'has_accepted_medical_disclaimer_v1';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_acceptedPrefKey) ?? false;
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    final accepted = await hasAccepted();
    if (!accepted && context.mounted) {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MedicalTermsOnboardingModal(
          onAccepted: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_acceptedPrefKey, true);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C1C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  color: const Color(0xFF00696B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF00696B), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to MedScan AI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF191C1C),
                      ),
                    ),
                    Text(
                      'වෛද්‍යමය භාවිත නියමයන් සහ වගකීම් ප්‍රකාශය',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 11.5,
                        color: const Color(0xFF00696B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D2828) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF3B4848) : const Color(0xFFFFE082),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_rounded, color: Color(0xFFE65100), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Important Clinical Notice',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. MedScan AI is an educational tool powered by multimodal computer vision to assist in identifying physical medicines.\n'
                  '2. It does NOT provide professional medical advice, diagnosis, or prescription.\n'
                  '3. Never alter, start, or stop medication without direct consultation with a licensed doctor or registered pharmacist.\n'
                  '4. In case of accidental overdose, immediately call 1990 or the National Poisons Centre.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00696B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onAccepted,
              child: const Text(
                'I Understand & Accept (එකඟ වෙමි)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
