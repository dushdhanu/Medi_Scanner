import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyDirectoryScreen extends StatelessWidget {
  const EmergencyDirectoryScreen({super.key});

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openNearbyPharmacies() async {
    final uri = Uri.parse('https://www.google.com/maps/search/pharmacy+near+me');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hotlines = [
      {
        'title': 'National Poisons Information Centre (ජාතික විෂ තොරතුරු මධ්‍යස්ථානය)',
        'number': '0112686143',
        'displayNumber': '011-2686143 / 011-2691111',
        'desc': 'National Hospital of Sri Lanka (NHSL). 24/7 toxicological advice for accidental medicine overdose or poisoning.',
        'color': const Color(0xFFC62828),
        'icon': Icons.warning_rounded,
      },
      {
        'title': '1990 Suwa Seriya Ambulance (සුවසැරිය ගිලන්රථ සේවය)',
        'number': '1990',
        'displayNumber': '1990',
        'desc': 'Free 24/7 emergency pre-hospital healthcare and rapid ambulance response throughout Sri Lanka.',
        'color': const Color(0xFF0288D1),
        'icon': Icons.medical_services_rounded,
      },
      {
        'title': 'Government Health Information Service (සුව සහන සේවය)',
        'number': '1959',
        'displayNumber': '1959',
        'desc': 'Ministry of Health, Sri Lanka. Public inquiries, hospital information, and health advisory service.',
        'color': const Color(0xFF00696B),
        'icon': Icons.local_hospital_rounded,
      },
      {
        'title': 'Mental Health & Suicide Prevention Helpline (ජාතික මානසික සුවතා සහන සේවය)',
        'number': '1926',
        'displayNumber': '1926',
        'desc': 'NIMH Angoda 24/7 toll-free helpline for emotional distress, psychological crisis, and mental health support.',
        'color': const Color(0xFF5E35B1),
        'icon': Icons.support_agent_rounded,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emergency Directory (හදිසි ඇමතුම්)',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B1414) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF5C2626) : const Color(0xFFFFCDD2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.emergency_rounded, color: Color(0xFFC62828), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medicine Overdose or Emergency?',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isDark ? Colors.white : const Color(0xFFB71C1C),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'අධික මාත්‍රාවක් හෝ හදිසි අසාත්මිකතාවයක් ඇතිවුවහොත් වහාම පහත අංක අමතන්න.',
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFFFCDD2) : const Color(0xFF880E4F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Hotlines List
          ...hotlines.map((item) {
            final color = item['color'] as Color;
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item['icon'] as IconData, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['desc'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _makeCall(item['number'] as String),
                        icon: const Icon(Icons.call, size: 18),
                        label: Text(
                          'Call ${item['displayNumber']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 10),

          // Nearby Pharmacy Finder Button
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00696B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.map_rounded, color: Color(0xFF00696B)),
              ),
              title: Text(
                'Find Nearby Pharmacies (ළඟම ඖෂධසල්)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text('Open Google Maps to view registered pharmacies nearby'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: _openNearbyPharmacies,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
