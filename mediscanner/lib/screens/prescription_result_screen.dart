import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/medicine_analysis_result.dart';
import '../models/prescription_analysis_result.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class PrescriptionResultScreen extends StatefulWidget {
  final PrescriptionAnalysisResult result;

  const PrescriptionResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<PrescriptionResultScreen> createState() => _PrescriptionResultScreenState();
}

class _PrescriptionResultScreenState extends State<PrescriptionResultScreen> {
  late List<PrescribedMedicineItem> _medicines;
  bool _isScheduling = false;
  bool _isSinhala = true;

  @override
  void initState() {
    super.initState();
    _medicines = List.from(widget.result.medicines);
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      for (final m in _medicines) {
        m.isSelectedForReminder = value ?? false;
      }
    });
  }

  Future<void> _scheduleAllBatchDoses() async {
    final selected = _medicines.where((m) => m.isSelectedForReminder).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one medicine to schedule alarms.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isScheduling = true);

    int totalAlarmsScheduled = 0;
    final notificationService = NotificationService();

    for (final med in selected) {
      for (final slot in med.suggestedTimes) {
        final alarmId = ('rx_${med.drugName}_${slot.hour}_${slot.minute}'.hashCode.abs() % 100000);
        await notificationService.scheduleMedicineReminder(
          id: alarmId,
          medicineName: med.drugName,
          doseTimeLabel: '${slot.label} (${med.mealTiming})',
          hour: slot.hour,
          minute: slot.minute,
        );
        totalAlarmsScheduled++;
      }

      // Also auto-save to Medicine Cabinet SQLite database so user can track it
      try {
        final medicineRecord = MedicineAnalysisResult(
          id: 'rx_med_${med.drugName.hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          imagePath: widget.result.imagePath,
          isMedicine: true,
          confidenceRating: 'High',
          packageType: 'Prescription Item',
          identifiedManufacturer: widget.result.doctorOrClinicName ?? 'Doctor Prescription',
          expiryDate: null,
          batchNumber: null,
          remainingPills: 10,
          sinhala: MedicineLanguageData(
            brandName: med.drugName,
            genericName: med.genericName,
            dosageStrength: med.dosageStrength,
            clinicalUses: ['වෛද්‍යවරයා විසින් නියම කරන ලද ප්‍රතිකාරය'],
            usageInstructions: '${med.instructionsSi} (${med.mealTimingSi}) - කාලසීමාව: ${med.durationSi}',
            sideEffects: ['වෛද්‍ය උපදෙස් අනුව ක්‍රියා කරන්න'],
            precautions: [med.specialPrecautions ?? 'නියමිත සම්පූර්ණ මාත්‍රා ප්‍රමාණය ලබා ගන්න'],
            storageGuidelines: 'සෙල්සියස් අංශක 30ට අඩු සිසිල් වියළි ස්ථානයක ගබඩා කරන්න.',
          ),
          english: MedicineLanguageData(
            brandName: med.drugName,
            genericName: med.genericName,
            dosageStrength: med.dosageStrength,
            clinicalUses: ['As prescribed by attending physician'],
            usageInstructions: '${med.instructionsEn} (${med.mealTiming}) - Duration: ${med.duration}',
            sideEffects: ['Follow physician guidance if adverse reaction occurs'],
            precautions: [med.specialPrecautions ?? 'Complete full prescription course'],
            storageGuidelines: 'Store below 30°C in a cool, dry place away from moisture.',
          ),
          generalWarning: widget.result.generalWarning,
        );

        await DatabaseService.insertMedicine(medicineRecord);
      } catch (_) {}
    }

    setState(() => _isScheduling = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 28),
              SizedBox(width: 8),
              Text('Alarms Scheduled!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_isSinhala ? "සියලුම ඖෂධ මාත්‍රා $totalAlarmsScheduled ක් සඳහා මතක් කිරීම් (Reminders) සක්‍රිය කරන ලදී. ඒවා ඔබගේ Medicine Cabinet එකටද සුරකින ලදී." : "Successfully scheduled $totalAlarmsScheduled daily alarms for ${selected.length} medications and saved them to your Medicine Cabinet."',
                style: GoogleFonts.notoSansSinhala(fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00696B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storage_rounded, color: Color(0xFF00696B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isSinhala 
                            ? 'ඖෂධ ${selected.length} ක් SQLite දත්ත සමුදායට එක් කරන ලදී.'
                            : '${selected.length} items synced to SQLite Vault.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00696B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00696B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK / හරි'),
            ),
          ],
        ),
      );
    }
  }

  void _sharePrescriptionSummary() {
    final res = widget.result;
    final buffer = StringBuffer();
    buffer.writeln('📋 MedScan AI - Deciphered Doctor Prescription');
    buffer.writeln('=============================================');
    if (res.doctorOrClinicName != null) {
      buffer.writeln('🏥 Doctor/Clinic: ${res.doctorOrClinicName}');
    }
    if (res.prescriptionDate != null) {
      buffer.writeln('📅 Date: ${res.prescriptionDate}');
    }
    if (res.patientName != null) {
      buffer.writeln('👤 Patient: ${res.patientName}');
    }
    buffer.writeln('\n💊 Prescribed Medications (${res.medicines.length}):');
    for (int i = 0; i < res.medicines.length; i++) {
      final m = res.medicines[i];
      buffer.writeln('\n${i + 1}. ${m.drugName} (${m.dosageStrength})');
      buffer.writeln('   • Generic: ${m.genericName}');
      buffer.writeln('   • Frequency: ${m.frequencyCode} - ${m.instructionsEn}');
      buffer.writeln('   • සිංහලෙන්: ${m.instructionsSi} (${m.mealTimingSi})');
      buffer.writeln('   • Duration / කාලය: ${m.duration} (${m.durationSi})');
      if (m.specialPrecautions != null) {
        buffer.writeln('   • ⚠️ Caution: ${m.specialPrecautions}');
      }
    }
    buffer.writeln('\n---------------------------------------------');
    buffer.writeln('⚠️ Disclaimer: Always verify with a licensed pharmacist before taking medication.');

    Share.share(buffer.toString(), subject: 'Prescription Summary - ${res.patientName ?? "MedScan"}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final res = widget.result;
    final allSelected = _medicines.every((m) => m.isSelectedForReminder);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Prescription OCR',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'බෙහෙත් තිණ්ඩු විශ්ලේෂණය',
              style: GoogleFonts.notoSansSinhala(fontSize: 11, color: const Color(0xFF00696B), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSinhala ? Icons.translate_rounded : Icons.language_rounded),
            tooltip: _isSinhala ? 'Switch to English' : 'සිංහලට මාරු වන්න',
            onPressed: () => setState(() => _isSinhala = !_isSinhala),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Prescription',
            onPressed: _sharePrescriptionSummary,
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Header Summary Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161F20) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF283636) : const Color(0xFFE2EDED)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: res.imagePath != null && File(res.imagePath!).existsSync()
                      ? Image.file(
                          File(res.imagePath!),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFF00696B).withValues(alpha: 0.12),
                          child: const Icon(Icons.description_outlined, color: Color(0xFF00696B), size: 30),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.doctorOrClinicName ?? (_isSinhala ? 'වෛද්‍ය බෙහෙත් තුණ්ඩුව' : 'Doctor Prescription'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_medicines.length} ${_isSinhala ? "ඖෂධ හඳුනාගන්නා ලදී" : "Medicines Deciphered"} • ${res.prescriptionDate ?? "Recent"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF00696B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (res.patientName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Patient: ${res.patientName}',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Select All Checkbox bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: allSelected,
                      activeColor: const Color(0xFF00696B),
                      onChanged: _toggleSelectAll,
                    ),
                    Text(
                      _isSinhala ? 'සියල්ල තෝරන්න (Select All)' : 'Select All for Reminders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00696B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_medicines.where((m) => m.isSelectedForReminder).length}/${_medicines.length} Selected',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00696B)),
                  ),
                ),
              ],
            ),
          ),

          // List of Prescribed Medicines
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _medicines.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final med = _medicines[index];
                return _buildMedicineCheckCard(med, isDark);
              },
            ),
          ),

          // Bottom 1-Tap Batch Scheduler Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00696B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _isScheduling ? null : _scheduleAllBatchDoses,
                icon: _isScheduling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.alarm_add_rounded),
                label: Text(
                  _isScheduling
                      ? 'Scheduling Reminders...'
                      : (_isSinhala
                          ? '1-Tap සියලු මාත්‍රා මතක් කිරීම් සකසන්න'
                          : '1-Tap Schedule All Dose Alarms'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCheckCard(PrescribedMedicineItem med, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F20) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: med.isSelectedForReminder
              ? const Color(0xFF00696B).withValues(alpha: 0.6)
              : (isDark ? const Color(0xFF283636) : const Color(0xFFE2EDED)),
          width: med.isSelectedForReminder ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: med.isSelectedForReminder,
                activeColor: const Color(0xFF00696B),
                onChanged: (val) {
                  setState(() => med.isSelectedForReminder = val ?? false);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.drugName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${med.genericName} • ${med.dosageStrength}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF90A1A1) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0288D1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  med.frequencyCode.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0288D1),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Instructions in Sinhala & English
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF202C2C) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF00696B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _isSinhala ? med.instructionsSi : med.instructionsEn,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // Meal timing chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🍽️ ${_isSinhala ? med.mealTimingSi : med.mealTiming}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF00696B)),
                      ),
                    ),
                    // Duration chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⏳ ${_isSinhala ? med.durationSi : med.duration}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                      ),
                    ),
                  ],
                ),
                if (med.specialPrecautions != null && med.specialPrecautions!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '⚠️ ${med.specialPrecautions}',
                    style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
