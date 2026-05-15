import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../features/user/notification/models/notification_setting_model.dart';

/// Service untuk mengelola semua operasi flutter_local_notifications.
///
/// Cara pakai:
///   await NotificationService.init();           // di main.dart
///   await NotificationService.scheduleAll();    // setelah load settings dari Hive
///   await NotificationService.cancel(id);       // saat user toggle off
class NotificationService {
  NotificationService._(); // private constructor — semua method static

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Nama channel Android — harus konsisten di seluruh app
  static const String _channelId = 'meal_reminder_channel';
  static const String _channelName = 'Pengingat Makan';
  static const String _channelDesc =
      'Notifikasi pengingat waktu makan (sarapan, makan siang, makan malam)';

  // ─────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────

  /// Inisialisasi plugin dan timezone. Panggil sekali di main() sebelum runApp.
  static Future<void> init() async {
    // Muat database timezone (wajib untuk notifikasi berulang harian)
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // kita minta manual via requestPermission()
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

  /// Minta izin notifikasi ke user (Android 13+ dan iOS wajib).
  /// Kembalikan true jika izin diberikan.
  static Future<bool> requestPermission() async {
    // Android
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
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

  /// Jadwalkan satu notifikasi berulang harian berdasarkan [setting].
  /// Jika [setting.isEnabled] false, notifikasi dibatalkan saja.
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

    // Signature exact flutter_local_notifications 18.0.1:
    // - Positional: id, title, body, scheduledDate, notificationDetails
    // - uiLocalNotificationDateInterpretation masih required (belum dihapus di versi pub)
    // - androidAllowWhileIdle sudah diganti jadi androidScheduleMode
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
      '[NotificationService] Scheduled "${setting.label}" '
      'at ${setting.hour.toString().padLeft(2, '0')}:'
      '${setting.minute.toString().padLeft(2, '0')} '
      '(id=${setting.notificationId})',
    );
  }

  /// Jadwalkan semua notifikasi dari list [settings] sekaligus.
  static Future<void> scheduleAll(
      List<NotificationSettingModel> settings) async {
    for (final s in settings) {
      await schedule(s);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────────────────────────────────

  /// Batalkan satu notifikasi berdasarkan [id].
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    debugPrint('[NotificationService] Cancelled notification id=$id');
  }

  /// Batalkan semua notifikasi yang pernah dijadwalkan.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────────────────────────────────────

  /// Hitung TZDateTime berikutnya untuk jam [hour]:[minute].
  ///
  /// Logika:
  ///   - Ambil waktu sekarang di timezone lokal (Asia/Jakarta)
  ///   - Set jam & menit ke yang diinginkan
  ///   - Kalau waktu tersebut sudah lewat hari ini → tambah 1 hari
  ///     (supaya notifikasi pertama tidak langsung tembak di masa lalu)
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