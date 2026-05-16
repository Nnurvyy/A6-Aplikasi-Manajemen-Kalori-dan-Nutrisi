import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../features/user/notification/models/notification_setting_model.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'meal_reminder_channel';
  static const String _channelName = 'Pengingat Makan';
  static const String _channelDesc =
      'Notifikasi pengingat waktu makan (sarapan, makan siang, makan malam)';

  // ─────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERMISSION
  // ─────────────────────────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      // 1. Izin notifikasi biasa (Android 13+)
      final granted = await android.requestNotificationsPermission();

      // 2. Izin exact alarm (Android 12+)
      //    Jika belum granted, buka halaman Settings device secara otomatis
      try {
        final canExact = await android.canScheduleExactNotifications();
        if (canExact == false) {
          debugPrint('[NotificationService] Requesting exact alarm permission...');
          await android.requestExactAlarmsPermission();
        }
      } catch (e) {
        // Device lama (< API 31) tidak punya method ini, abaikan
        debugPrint('[NotificationService] canScheduleExactNotifications: $e');
      }

      return granted ?? false;
    }

    // iOS
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCHEDULE
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> schedule(NotificationSettingModel setting) async {
    if (!setting.isEnabled) {
      await cancel(setting.notificationId);
      return;
    }

    final scheduledTime = _nextInstanceOfTime(setting.hour, setting.minute);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Coba exact dulu. Jika gagal (izin belum diberikan user),
    // fallback ke inexact — notifikasi tetap muncul, mungkin meleset
    // beberapa menit tapi TIDAK crash dan toggle tetap berfungsi.
    try {
      await _plugin.zonedSchedule(
        setting.notificationId,
        setting.title,
        setting.body,
        scheduledTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
        '[NotificationService] Scheduled (exact) "${setting.label}" '
        'at ${setting.hour.toString().padLeft(2, '0')}:'
        '${setting.minute.toString().padLeft(2, '0')} '
        '(id=${setting.notificationId})',
      );
    } catch (e) {
      debugPrint('[NotificationService] Exact failed, using inexact: $e');
      await _plugin.zonedSchedule(
        setting.notificationId,
        setting.title,
        setting.body,
        scheduledTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
        '[NotificationService] Scheduled (inexact) "${setting.label}" '
        'at ${setting.hour.toString().padLeft(2, '0')}:'
        '${setting.minute.toString().padLeft(2, '0')} '
        '(id=${setting.notificationId})',
      );
    }
  }

  static Future<void> scheduleAll(
      List<NotificationSettingModel> settings) async {
    for (final s in settings) {
      await schedule(s);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    debugPrint('[NotificationService] Cancelled notification id=$id');
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────────────────────────────────────

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  // Untuk testing — kirim notifikasi instan tanpa schedule
  static Future<void> instantTest() async {
    await _plugin.show(
      999,
      'TEST NOTIFICATION',
      'Jika notif ini muncul berarti plugin bekerja',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notification',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}