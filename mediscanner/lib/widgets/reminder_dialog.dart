import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';

class ReminderDialog extends StatefulWidget {
  final String medicineName;
  final bool isSinhala;

  const ReminderDialog({
    super.key,
    required this.medicineName,
    required this.isSinhala,
  });

  static Future<void> show(BuildContext context, {required String medicineName, required bool isSinhala}) {
    return showDialog(
      context: context,
      builder: (context) => ReminderDialog(
        medicineName: medicineName,
        isSinhala: isSinhala,
      ),
    );
  }

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  bool _morning = true;
  bool _afternoon = false;
  bool _night = true;
  bool _isSaving = false;

  Future<void> _saveReminders() async {
    setState(() => _isSaving = true);

    final med = widget.medicineName;
    int baseId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (_morning) {
      await NotificationService().scheduleMedicineReminder(
        id: baseId + 1,
        medicineName: med,
        doseTimeLabel: widget.isSinhala ? 'උදෑසන මාත්‍රාව (Morning Dose)' : 'Morning Dose',
        hour: 8,
        minute: 0,
      );
    }

    if (_afternoon) {
      await NotificationService().scheduleMedicineReminder(
        id: baseId + 2,
        medicineName: med,
        doseTimeLabel: widget.isSinhala ? 'දහවල් මාත්‍රාව (Afternoon Dose)' : 'Afternoon Dose',
        hour: 13,
        minute: 0,
      );
    }

    if (_night) {
      await NotificationService().scheduleMedicineReminder(
        id: baseId + 3,
        medicineName: med,
        doseTimeLabel: widget.isSinhala ? 'රාත්‍රී මාත්‍රාව (Night Dose)' : 'Night Dose',
        hour: 20,
        minute: 0,
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isSinhala
                ? 'ඖෂධ මාත්‍රා මතක් කිරීම් සකස් කරන ලදී!'
                : 'Dosage reminders scheduled successfully!',
            style: widget.isSinhala ? GoogleFonts.notoSansSinhala() : null,
          ),
          backgroundColor: const Color(0xFF00696B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00696B).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_add_rounded, color: Color(0xFF00696B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isSinhala ? 'මාත්‍රා වේලාවන් සකසන්න' : 'Set Dose Reminders',
              style: (widget.isSinhala
                      ? GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold)
                      : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))
                  .copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.medicineName,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00696B)),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isSinhala
                ? 'ඔබ මෙම ඖෂධය ලබා ගත යුතු වේලාවන් තෝරන්න:'
                : 'Select the times you need to take this medicine:',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            dense: true,
            title: Text(widget.isSinhala ? 'උදෑසන (Morning - 08:00 AM)' : 'Morning (08:00 AM)'),
            value: _morning,
            activeColor: const Color(0xFF00696B),
            onChanged: (val) => setState(() => _morning = val ?? false),
          ),
          CheckboxListTile(
            dense: true,
            title: Text(widget.isSinhala ? 'දහවල් (Afternoon - 01:00 PM)' : 'Afternoon (01:00 PM)'),
            value: _afternoon,
            activeColor: const Color(0xFF00696B),
            onChanged: (val) => setState(() => _afternoon = val ?? false),
          ),
          CheckboxListTile(
            dense: true,
            title: Text(widget.isSinhala ? 'රාත්‍රී (Night - 08:00 PM)' : 'Night (08:00 PM)'),
            value: _night,
            activeColor: const Color(0xFF00696B),
            onChanged: (val) => setState(() => _night = val ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isSinhala ? 'අවලංගුයි' : 'Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00696B),
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _saveReminders,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.isSinhala ? 'සකසන්න' : 'Save Reminder'),
        ),
      ],
    );
  }
}
