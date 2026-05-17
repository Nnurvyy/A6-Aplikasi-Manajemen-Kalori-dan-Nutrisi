import 'package:flutter/material.dart';

import '../../../services/hive_service.dart';
import '../../../services/notification_service.dart';
import './models/notification_setting_model.dart';

/// Controller untuk halaman pengaturan notifikasi makan.
///
/// Bertanggung jawab atas:
/// - Load settings dari Hive (atau isi default jika pertama kali)
/// - Simpan perubahan ke Hive + reschedule notifikasi
/// - Toggle on/off per sesi makan
/// - Update jam dan teks notifikasi
class NotificationController extends ChangeNotifier {
  List<NotificationSettingModel> _settings = [];
  List<NotificationSettingModel> get settings => _settings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────

  /// Load settings dari Hive. Jika box kosong (pertama kali),
  /// otomatis isi dengan default (pagi 07:00, siang 12:00, malam 19:00).
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    final box = HiveService.notificationSettings;

    if (box.isEmpty) {
      // Pertama kali — simpan default ke Hive
      final defaults = NotificationSettingModel.defaultSettings();
      for (final s in defaults) {
        await box.put(s.notificationId, s);
      }
      // Jadwalkan semua notifikasi default
      await NotificationService.scheduleAll(defaults);
    }

    // Load dari Hive, urutkan: pagi (0) → siang (1) → malam (2)
    _settings = box.values.toList()
      ..sort((a, b) => a.notificationId.compareTo(b.notificationId));

    _isLoading = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOGGLE ON/OFF
  // ─────────────────────────────────────────────────────────────────────────

  /// Aktifkan atau nonaktifkan notifikasi untuk sesi [index].
  Future<void> toggleEnabled(int index) async {
    final setting = _settings[index];
    setting.isEnabled = !setting.isEnabled;

    await _saveAndReschedule(setting);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE JAM
  // ─────────────────────────────────────────────────────────────────────────

  /// Update jam notifikasi untuk sesi [index].
  /// Dipanggil setelah user memilih jam dari TimePicker.
  Future<void> updateTime(int index, TimeOfDay time) async {
    final setting = _settings[index];
    setting.hour = time.hour;
    setting.minute = time.minute;

    await _saveAndReschedule(setting);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE TEKS
  // ─────────────────────────────────────────────────────────────────────────

  /// Update judul notifikasi untuk sesi [index].
  Future<void> updateTitle(int index, String newTitle) async {
    if (newTitle.trim().isEmpty) return;

    final setting = _settings[index];
    setting.title = newTitle.trim();

    await _saveAndReschedule(setting);
    notifyListeners();
  }

  /// Update body/isi notifikasi untuk sesi [index].
  Future<void> updateBody(int index, String newBody) async {
    if (newBody.trim().isEmpty) return;

    final setting = _settings[index];
    setting.body = newBody.trim();

    await _saveAndReschedule(setting);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESET
  // ─────────────────────────────────────────────────────────────────────────

  /// Reset semua notifikasi ke pengaturan default.
  Future<void> resetToDefault() async {
    await NotificationService.cancelAll();

    final defaults = NotificationSettingModel.defaultSettings();
    final box = HiveService.notificationSettings;

    for (final s in defaults) {
      await box.put(s.notificationId, s);
    }

    _settings = defaults;
    await NotificationService.scheduleAll(_settings);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────────────────────────────────────

  /// Simpan [setting] ke Hive lalu reschedule notifikasinya.
  Future<void> _saveAndReschedule(NotificationSettingModel setting) async {
    // Hive HiveObject.save() langsung update record yang sama
    await setting.save();
    await NotificationService.schedule(setting);
  }

  /// Format jam dari setting menjadi string "HH:mm" untuk ditampilkan di UI.
  String formatTime(NotificationSettingModel setting) {
    final h = setting.hour.toString().padLeft(2, '0');
    final m = setting.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Konversi setting ke TimeOfDay untuk TimePicker.
  TimeOfDay toTimeOfDay(NotificationSettingModel setting) {
    return TimeOfDay(hour: setting.hour, minute: setting.minute);
  }
}