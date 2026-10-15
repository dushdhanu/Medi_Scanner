import 'dart:convert';

/// Represents medicine details in a single language (Sinhala or English)
class MedicineLanguageData {
  final String brandName;
  final String genericName;
  final String dosageStrength;
  final List<String> clinicalUses;
  final String usageInstructions;
  final List<String> sideEffects;
  final List<String> precautions;
  final String storageGuidelines;
  final String? unreadableNotice;

  const MedicineLanguageData({
    required this.brandName,
    required this.genericName,
    required this.dosageStrength,
    required this.clinicalUses,
    required this.usageInstructions,
    required this.sideEffects,
    required this.precautions,
    required this.storageGuidelines,
    this.unreadableNotice,
  });

  factory MedicineLanguageData.fromJson(Map<String, dynamic> json) {
    return MedicineLanguageData(
      brandName: json['brandName']?.toString() ?? 'Unknown',
      genericName: json['genericName']?.toString() ?? 'Not specified',
      dosageStrength: json['dosageStrength']?.toString() ?? 'Not specified',
      clinicalUses: _parseList(json['clinicalUses']),
      usageInstructions: json['usageInstructions']?.toString() ?? 'Follow physician advice',
      sideEffects: _parseList(json['sideEffects']),
      precautions: _parseList(json['precautions']),
      storageGuidelines: json['storageGuidelines']?.toString() ?? 'Store in a cool, dry place away from direct sunlight.',
      unreadableNotice: json['unreadableNotice']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brandName': brandName,
      'genericName': genericName,
      'dosageStrength': dosageStrength,
      'clinicalUses': clinicalUses,
      'usageInstructions': usageInstructions,
      'sideEffects': sideEffects,
      'precautions': precautions,
      'storageGuidelines': storageGuidelines,
      'unreadableNotice': unreadableNotice,
    };
  }

  static List<String> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (data is String) {
      return [data.trim()];
    }
    return [];
  }
}

/// Represents the overall analysis result returned by Gemini Multimodal Vision API
class MedicineAnalysisResult {
  final String id;
  final DateTime timestamp;
  final String? imagePath;
  final bool isMedicine;
  final String confidenceRating; // 'High', 'Moderate', 'Low', 'Uncertain'
  final String packageType; // 'Tablet/Capsule', 'Blister Pack', 'Syrup Bottle', 'Ointment Tube', 'Other'
  final String identifiedManufacturer;
  final MedicineLanguageData sinhala;
  final MedicineLanguageData english;
  final String generalWarning;

  const MedicineAnalysisResult({
    required this.id,
    required this.timestamp,
    this.imagePath,
    required this.isMedicine,
    required this.confidenceRating,
    required this.packageType,
    required this.identifiedManufacturer,
    required this.sinhala,
    required this.english,
    required this.generalWarning,
  });

  factory MedicineAnalysisResult.fromJson(Map<String, dynamic> json, {String? imagePath}) {
    final now = DateTime.now();
    final parsedTimestamp = json['timestamp'] != null 
        ? DateTime.tryParse(json['timestamp'].toString()) ?? now 
        : now;

    return MedicineAnalysisResult(
      id: json['id']?.toString() ?? 'scan_${now.millisecondsSinceEpoch}',
      timestamp: parsedTimestamp,
      imagePath: imagePath ?? json['imagePath']?.toString(),
      isMedicine: json['isMedicine'] is bool ? json['isMedicine'] as bool : true,
      confidenceRating: json['confidenceRating']?.toString() ?? 'Moderate',
      packageType: json['packageType']?.toString() ?? 'Medicine Package',
      identifiedManufacturer: json['identifiedManufacturer']?.toString() ?? 'Unspecified',
      sinhala: MedicineLanguageData.fromJson(
        (json['sinhala'] is Map<String, dynamic>) 
            ? json['sinhala'] as Map<String, dynamic> 
            : {},
      ),
      english: MedicineLanguageData.fromJson(
        (json['english'] is Map<String, dynamic>) 
            ? json['english'] as Map<String, dynamic> 
            : {},
      ),
      generalWarning: json['generalWarning']?.toString() ?? 
          'Always verify medicine information with a licensed doctor or pharmacist before consumption.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'isMedicine': isMedicine,
      'confidenceRating': confidenceRating,
      'packageType': packageType,
      'identifiedManufacturer': identifiedManufacturer,
      'sinhala': sinhala.toJson(),
      'english': english.toJson(),
      'generalWarning': generalWarning,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory MedicineAnalysisResult.fromJsonString(String source, {String? imagePath}) {
    return MedicineAnalysisResult.fromJson(jsonDecode(source) as Map<String, dynamic>, imagePath: imagePath);
  }

  /// Create sample demonstration data when testing offline or without camera
  static MedicineAnalysisResult createSample() {
    return MedicineAnalysisResult(
      id: 'sample_panadol_extra',
      timestamp: DateTime.now(),
      imagePath: null,
      isMedicine: true,
      confidenceRating: 'High',
      packageType: 'Blister Pack',
      identifiedManufacturer: 'GlaxoSmithKline (GSK)',
      sinhala: const MedicineLanguageData(
        brandName: 'පැනඩෝල් එක්ස්ට්‍රා (Panadol Extra)',
        genericName: 'පැරසිටමෝල් (Paracetamol) 500mg + කැෆේන් (Caffeine) 65mg',
        dosageStrength: '500mg / 65mg එක් පෙත්තක',
        clinicalUses: [
          'හිසරදය සහ ඉරුවාරදය (Migraine)',
          'දත් කැක්කුම සහ ස්නායු වේදනා',
          'උණ සහ සෙම්ප්‍රතිශ්‍යාව ආශ්‍රිත ඇඟපත වේදනාව',
          'ඔසප් වේදනා (Dysmenorrhea)',
          'මාංශ පේශි සහ සන්ධි වේදනාව',
        ],
        usageInstructions: 'වැඩිහිටියන් සහ අවුරුදු 12ට වැඩි ළමුන් සඳහා: අවශ්‍යතාවය අනුව සෑම පැය 4-6කට වරක් පෙති 1ක් හෝ 2ක් වතුර වීදුරුවක් සමඟ ලබා ගන්න. පැය 24ක් තුළ පෙති 8කට වඩා නොගන්න. හිස්බඩ හෝ ආහාර ගැනීමෙන් පසු ගත හැක.',
        sideEffects: [
          'කලාතුරකින් සිදුවන සමේ අසාත්මිකතා හෝ පලු දැමීම',
          'කැෆේන් අඩංගු බැවින් රාත්‍රියේ ගැනීමේදී නින්ද නොයාම හෝ නොසන්සුන්බව',
          'අධික මාත්‍රාවකින් භාවිතය අක්මාවට බරපතල හානි සිදු කළ හැක',
          'ආමාශයේ සුළු අපහසුතා හෝ හෘද ස්පන්දනය වේගවත් වීම',
        ],
        precautions: [
          'වෙනත් පැරසිටමෝල් අඩංගු ඖෂධ සමඟ එකවර ලබා නොගන්න',
          'අක්මා හෝ වකුගඩු රෝගී තත්ත්වයන් ඇත්නම් වෛද්‍ය උපදෙස් මත පමණක් ලබා ගන්න',
          'ගර්භනී හෝ මව්කිරි දෙන මව්වරුන් භාවිතයට පෙර වෛද්‍යවරයකු හමුවන්න',
          'දින 3කට වඩා උණ හෝ දින 5කට වඩා වේදනාව පවතී නම් වහාම වෛද්‍යවරයකු හමුවන්න',
          'මධ්‍යසාර (Alcohol) සමඟ භාවිතය අක්මාවට හානිකර විය හැක',
        ],
        storageGuidelines: 'සෙල්සියස් අංශක 30ට අඩු වියළි, සෘජු හිරු එළියෙන් තොර ස්ථානයක ගබඩා කරන්න. කුඩා ළමුන්ගෙන් ඈත් කර තබන්න.',
        unreadableNotice: 'ඖෂධයේ කල් ඉකුත්වීමේ දිනය (Expiry Date) පැකට්ටුවේ දාරයේ මුද්‍රණය කර ඇති බව පෙනේ. කරුණාකර එය පැහැදිලිව පරීක්ෂා කරන්න.',
      ),
      english: const MedicineLanguageData(
        brandName: 'Panadol Extra',
        genericName: 'Paracetamol 500mg + Caffeine 65mg',
        dosageStrength: '500mg / 65mg per tablet',
        clinicalUses: [
          'Tension headache and migraine',
          'Dental pain and toothache',
          'Fever reduction and cold symptoms',
          'Period pain (Dysmenorrhea)',
          'Musculoskeletal and joint aches',
        ],
        usageInstructions: 'Adults and children aged 12 years and over: 1 to 2 tablets every 4 to 6 hours as required. Do not exceed 8 tablets in any 24-hour period. Can be taken with or without food.',
        sideEffects: [
          'Rare allergic skin rashes or itching',
          'Sleeplessness or restlessness if taken near bedtime (due to caffeine)',
          'Liver toxicity in case of overdose',
          'Mild gastrointestinal upset or increased heart rate',
        ],
        precautions: [
          'Do NOT take concurrently with any other paracetamol-containing medications',
          'Consult a healthcare professional if you suffer from severe liver or kidney impairment',
          'Pregnant or lactating mothers must consult a doctor prior to consumption',
          'If symptoms persist for more than 3-5 days, seek clinical assessment immediately',
          'Avoid excessive intake of coffee/tea alongside this formulation',
        ],
        storageGuidelines: 'Store below 30°C in a dry place protected from direct heat and sunlight. Keep strictly out of reach of children.',
        unreadableNotice: 'Batch number and expiration date appear imprinted along the blister seal margin. Verify expiration date physically before ingestion.',
      ),
      generalWarning: 'This AI analysis is for informational and identification assistance only. Always consult a qualified medical doctor or registered pharmacist before taking any medication.',
    );
  }
}
