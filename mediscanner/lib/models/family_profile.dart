import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyProfile {
  final String id;
  final String nameEn;
  final String nameSi;
  final int colorValue;
  final int iconCodePoint;

  const FamilyProfile({
    required this.id,
    required this.nameEn,
    required this.nameSi,
    required this.colorValue,
    required this.iconCodePoint,
  });

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameSi': nameSi,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory FamilyProfile.fromJson(Map<String, dynamic> json) {
    return FamilyProfile(
      id: json['id']?.toString() ?? 'self',
      nameEn: json['nameEn']?.toString() ?? 'Myself',
      nameSi: json['nameSi']?.toString() ?? 'මම',
      colorValue: json['colorValue'] is int ? json['colorValue'] as int : const Color(0xFF00696B).toARGB32(),
      iconCodePoint: json['iconCodePoint'] is int ? json['iconCodePoint'] as int : Icons.person_rounded.codePoint,
    );
  }

  /// Preset default Sri Lankan family members
  static const List<FamilyProfile> defaultProfiles = [
    FamilyProfile(
      id: 'self',
      nameEn: 'Myself',
      nameSi: 'මම',
      colorValue: 0xFF00696B, // Teal
      iconCodePoint: 0xe491, // person_rounded
    ),
    FamilyProfile(
      id: 'father',
      nameEn: 'Father',
      nameSi: 'තාත්තා',
      colorValue: 0xFF0288D1, // Blue
      iconCodePoint: 0xea39, // elderly_rounded
    ),
    FamilyProfile(
      id: 'mother',
      nameEn: 'Mother',
      nameSi: 'අම්මා',
      colorValue: 0xFFE91E63, // Pink
      iconCodePoint: 0xea3a, // elderly_woman_rounded
    ),
    FamilyProfile(
      id: 'child',
      nameEn: 'Child / Baby',
      nameSi: 'බබා / දරුවා',
      colorValue: 0xFFFF9800, // Amber
      iconCodePoint: 0xea2c, // child_care_rounded
    ),
  ];

  static const String _prefKeyCustomProfiles = 'mediscan_custom_family_profiles';

  /// Load all family profiles (defaults + custom ones created by user)
  static Future<List<FamilyProfile>> getAllProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final customListJson = prefs.getStringList(_prefKeyCustomProfiles);
    if (customListJson == null || customListJson.isEmpty) {
      return defaultProfiles;
    }

    final list = List<FamilyProfile>.from(defaultProfiles);
    for (final str in customListJson) {
      try {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        list.add(FamilyProfile.fromJson(decoded));
      } catch (_) {}
    }
    return list;
  }

  /// Add a new custom family profile
  static Future<void> addCustomProfile(FamilyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final customListJson = prefs.getStringList(_prefKeyCustomProfiles) ?? [];
    customListJson.add(jsonEncode(profile.toJson()));
    await prefs.setStringList(_prefKeyCustomProfiles, customListJson);
  }
}
