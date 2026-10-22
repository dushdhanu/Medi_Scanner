import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/medicine_analysis_result.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(initSettings);

      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (_) {
      // Ignored if platform doesn't support local notifications
    }
  }

  /// Show an immediate notification confirmation
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'med_scan_reminders',
        'Medicine Reminders',
        channelDescription: 'Notifications for medicine dosage schedules',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(id, title, body, details);
    } catch (_) {}
  }

  /// Schedule a medicine reminder
  Future<void> scheduleMedicineReminder({
    required int id,
    required String medicineName,
    required String doseTimeLabel,
    required int hour,
    required int minute,
  }) async {
    await init();
    await showInstantNotification(
      id: id,
      title: 'Reminder Set: $medicineName',
      body: 'Scheduled daily for $doseTimeLabel at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
  }

  /// Schedule 30-day and 7-day expiry alerts for a medicine
  Future<void> scheduleExpiryAlerts(MedicineAnalysisResult result) async {
    final expDate = result.parsedExpiryDate;
    if (expDate == null) return;
    await init();

    final now = DateTime.now();
    final name = result.english.brandName;
    final baseId = result.id.hashCode.abs() % 100000;

    // 30 days before
    final thirtyDaysBefore = expDate.subtract(const Duration(days: 30));
    if (thirtyDaysBefore.isAfter(now)) {
      try {
        await _notificationsPlugin.zonedSchedule(
          baseId + 1,
          '⚠️ ඖෂධ කල් ඉකුත්වීමේ අනතුරු ඇඟවීම (Expiry in 30 Days)',
          '$name ඖෂධය තව දින 30 කින් කල් ඉකුත් වේ ($name will expire in 30 days).',
          tz.TZDateTime.from(thirtyDaysBefore, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'med_scan_expiry',
              'Expiry Alerts',
              channelDescription: 'Alerts when medicines are close to expiring',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }

    // 7 days before
    final sevenDaysBefore = expDate.subtract(const Duration(days: 7));
    if (sevenDaysBefore.isAfter(now)) {
      try {
        await _notificationsPlugin.zonedSchedule(
          baseId + 2,
          '🚨 ඖෂධ කල් ඉකුත්වීමේ අවසන් සතිය (Expiry in 7 Days)',
          'අවධානය දෙන්න: $name ඖෂධය මෙම සතියේ කල් ඉකුත් වේ! භාවිතයෙන් වළකින්න.',
          tz.TZDateTime.from(sevenDaysBefore, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'med_scan_expiry',
              'Expiry Alerts',
              channelDescription: 'Alerts when medicines are close to expiring',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  /// Show refill alert when remaining pills count is low (<= 2)
  Future<void> showRefillAlert({
    required String medicineName,
    required int remainingPills,
  }) async {
    await init();
    try {
      final isOut = remainingPills <= 0;
      final title = isOut 
          ? '🚨 ඖෂධ අවසන් වී ඇත (Medication Out of Stock)'
          : '⚠️ ඖෂධ අවසන් වෙමින් පවතී (Refill Alert)';
      final body = isOut
          ? '$medicineName පෙති සියල්ල අවසන්. කරුණාකර ෆාමසියකින් ලබා ගන්න.'
          : '$medicineName ඖෂධයෙන් ඉතිරිව ඇත්තේ පෙති $remainingPills ක් පමණි. කරුණාකර නව තොගයක් ලබා ගන්න.';

      await showInstantNotification(
        id: ('refill_$medicineName'.hashCode.abs() % 100000),
        title: title,
        body: body,
      );
    } catch (_) {}
  }
}
