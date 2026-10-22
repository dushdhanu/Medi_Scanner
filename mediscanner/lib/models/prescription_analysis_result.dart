import 'dart:convert';

/// Represents a single medication line parsed from a doctor's handwritten prescription
class PrescribedMedicineItem {
  final String drugName;
  final String genericName;
  final String dosageStrength;
  final String frequencyCode; // e.g. "o.d.", "b.d.", "t.d.s.", "q.d.s.", "p.r.n.", "nocte"
  final String instructionsEn;
  final String instructionsSi;
  final String mealTiming; // "Before meals", "After meals", "With meals", "Unspecified"
  final String mealTimingSi; // "කෑමට පෙර", "කෑමට පසු", "ආහාර සමඟ", "සඳහන්ව නැත"
  final String duration; // e.g. "5 days", "1 month"
  final String durationSi;
  final String? specialPrecautions;
  bool isSelectedForReminder;

  PrescribedMedicineItem({
    required this.drugName,
    required this.genericName,
    required this.dosageStrength,
    required this.frequencyCode,
    required this.instructionsEn,
    required this.instructionsSi,
    required this.mealTiming,
    required this.mealTimingSi,
    required this.duration,
    required this.durationSi,
    this.specialPrecautions,
    this.isSelectedForReminder = true,
  });

  factory PrescribedMedicineItem.fromJson(Map<String, dynamic> json) {
    return PrescribedMedicineItem(
      drugName: json['drugName']?.toString() ?? 'Unknown Medication',
      genericName: json['genericName']?.toString() ?? 'Unspecified',
      dosageStrength: json['dosageStrength']?.toString() ?? 'Standard Dose',
      frequencyCode: json['frequencyCode']?.toString() ?? 'o.d.',
      instructionsEn: json['instructionsEn']?.toString() ?? 'Take as instructed by physician',
      instructionsSi: json['instructionsSi']?.toString() ?? 'වෛද්‍ය උපදෙස් පරිදි ලබා ගන්න',
      mealTiming: json['mealTiming']?.toString() ?? 'After meals',
      mealTimingSi: json['mealTimingSi']?.toString() ?? 'කෑමට පසු',
      duration: json['duration']?.toString() ?? 'As directed',
      durationSi: json['durationSi']?.toString() ?? 'උපදෙස් අනුව',
      specialPrecautions: json['specialPrecautions']?.toString(),
      isSelectedForReminder: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drugName': drugName,
      'genericName': genericName,
      'dosageStrength': dosageStrength,
      'frequencyCode': frequencyCode,
      'instructionsEn': instructionsEn,
      'instructionsSi': instructionsSi,
      'mealTiming': mealTiming,
      'mealTimingSi': mealTimingSi,
      'duration': duration,
      'durationSi': durationSi,
      'specialPrecautions': specialPrecautions,
    };
  }

  /// Suggested reminder schedule hours according to medical abbreviation
  List<TimeSlot> get suggestedTimes {
    final code = frequencyCode.toLowerCase().replaceAll('.', '').trim();
    switch (code) {
      case 'od': // once daily (morning)
      case 'mane':
        return [const TimeSlot(hour: 8, minute: 0, label: 'Morning / උදෑසන')];
      case 'nocte': // once daily at night
        return [const TimeSlot(hour: 21, minute: 0, label: 'Night / රාත්‍රී')];
      case 'bd': // twice daily
        return [
          const TimeSlot(hour: 8, minute: 0, label: 'Morning / උදෑසන'),
          const TimeSlot(hour: 20, minute: 0, label: 'Night / රාත්‍රී'),
        ];
      case 'tds': // thrice daily
      case 'tid':
        return [
          const TimeSlot(hour: 8, minute: 0, label: 'Morning / උදෑසන'),
          const TimeSlot(hour: 14, minute: 0, label: 'Afternoon / දහවල්'),
          const TimeSlot(hour: 20, minute: 0, label: 'Night / රාත්‍රී'),
        ];
      case 'qds': // four times daily
      case 'qid':
        return [
          const TimeSlot(hour: 6, minute: 0, label: 'Early Morning / අලුයම'),
          const TimeSlot(hour: 12, minute: 0, label: 'Noon / මද්දහන'),
          const TimeSlot(hour: 18, minute: 0, label: 'Evening / සවස'),
          const TimeSlot(hour: 22, minute: 0, label: 'Night / රාත්‍රී'),
        ];
      case 'prn': // as needed
      default:
        return [const TimeSlot(hour: 8, minute: 0, label: 'Morning / උදෑසන')];
    }
  }
}

class TimeSlot {
  final int hour;
  final int minute;
  final String label;

  const TimeSlot({
    required this.hour,
    required this.minute,
    required this.label,
  });
}

/// Represents the decoded handwritten doctor's prescription
class PrescriptionAnalysisResult {
  final String id;
  final DateTime timestamp;
  final String? imagePath;
  final String? doctorOrClinicName;
  final String? prescriptionDate;
  final String? patientName;
  final List<PrescribedMedicineItem> medicines;
  final String clinicalNotesEn;
  final String clinicalNotesSi;
  final String generalWarning;

  const PrescriptionAnalysisResult({
    required this.id,
    required this.timestamp,
    this.imagePath,
    this.doctorOrClinicName,
    this.prescriptionDate,
    this.patientName,
    required this.medicines,
    required this.clinicalNotesEn,
    required this.clinicalNotesSi,
    required this.generalWarning,
  });

  factory PrescriptionAnalysisResult.fromJson(Map<String, dynamic> json, {String? imagePath}) {
    final now = DateTime.now();
    final parsedTimestamp = json['timestamp'] != null 
        ? DateTime.tryParse(json['timestamp'].toString()) ?? now 
        : now;

    final medList = <PrescribedMedicineItem>[];
    if (json['medicines'] is List) {
      for (final item in json['medicines'] as List) {
        if (item is Map<String, dynamic>) {
          medList.add(PrescribedMedicineItem.fromJson(item));
        }
      }
    }

    return PrescriptionAnalysisResult(
      id: json['id']?.toString() ?? 'rx_${now.millisecondsSinceEpoch}',
      timestamp: parsedTimestamp,
      imagePath: imagePath ?? json['imagePath']?.toString(),
      doctorOrClinicName: json['doctorOrClinicName']?.toString(),
      prescriptionDate: json['prescriptionDate']?.toString(),
      patientName: json['patientName']?.toString(),
      medicines: medList,
      clinicalNotesEn: json['clinicalNotesEn']?.toString() ?? 'Review dosage with your pharmacist.',
      clinicalNotesSi: json['clinicalNotesSi']?.toString() ?? 'ෆාමසි නිලධාරීවරයා සමඟ මාත්‍රාව නැවත තහවුරු කරගන්න.',
      generalWarning: json['generalWarning']?.toString() ?? 
          'Handwritten medical prescriptions must always be verified by a licensed registered pharmacist prior to dispensing.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'doctorOrClinicName': doctorOrClinicName,
      'prescriptionDate': prescriptionDate,
      'patientName': patientName,
      'medicines': medicines.map((m) => m.toJson()).toList(),
      'clinicalNotesEn': clinicalNotesEn,
      'clinicalNotesSi': clinicalNotesSi,
      'generalWarning': generalWarning,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory PrescriptionAnalysisResult.fromJsonString(String source, {String? imagePath}) {
    return PrescriptionAnalysisResult.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
      imagePath: imagePath,
    );
  }
}
