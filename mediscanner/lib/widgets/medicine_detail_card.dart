import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicineDetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final bool isSinhala;
  final String? contentText;
  final List<String>? bulletPoints;
  final Widget? customContent;
  final String? badgeText;

  const MedicineDetailCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.isSinhala,
    this.contentText,
    this.bulletPoints,
    this.customContent,
    this.badgeText,
  });

  void _copyContent(BuildContext context) {
    String copyText = '$title:\n';
    if (contentText != null) {
      copyText += contentText!;
    } else if (bulletPoints != null) {
      copyText += bulletPoints!.map((e) => '• $e').join('\n');
    }

    Clipboard.setData(ClipboardData(text: copyText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSinhala ? 'සටහන පිටපත් කර ගන්නා ලදී' : 'Copied to clipboard',
          style: isSinhala ? GoogleFonts.notoSansSinhala() : null,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleStyle = (isSinhala
            ? GoogleFonts.notoSansSinhala(fontWeight: FontWeight.w700)
            : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700))
        .copyWith(
      fontSize: 15,
      color: isDark ? Colors.white : const Color(0xFF1E293B),
    );

    final bodyStyle = (isSinhala
            ? GoogleFonts.notoSansSinhala(fontWeight: FontWeight.w400)
            : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400))
        .copyWith(
      fontSize: 13.5,
      height: 1.5,
      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F20) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2B3A3B)
              : accentColor.withOpacity(0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : accentColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: titleStyle,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  color: isDark ? const Color(0xFF8C9E9E) : const Color(0xFF64748B),
                  tooltip: 'Copy',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _copyContent(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8, color: Color(0x1A808080)),
            const SizedBox(height: 12),

            // Content
            if (customContent != null)
              customContent!
            else if (bulletPoints != null && bulletPoints!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bulletPoints!.map((point) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 10),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            point,
                            style: bodyStyle,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            else if (contentText != null)
              Text(
                contentText!,
                style: bodyStyle,
              ),
          ],
        ),
      ),
    );
  }
}
