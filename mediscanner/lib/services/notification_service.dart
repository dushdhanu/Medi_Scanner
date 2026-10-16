import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
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
    // Show confirmation notification
    await showInstantNotification(
      id: id,
      title: 'Reminder Set: $medicineName',
      body: 'Scheduled daily for $doseTimeLabel at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
  }
}
