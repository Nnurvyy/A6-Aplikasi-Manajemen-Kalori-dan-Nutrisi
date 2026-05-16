import 'package:hive/hive.dart';

part 'notification_setting_model.g.dart';

/// Model Hive untuk menyimpan preferensi notifikasi makan harian.
/// Setiap instance mewakili satu sesi makan (pagi / siang / malam).
///
/// typeId = 7 (0=UserModel, 1-3=food models, 5=weight, 6=submission)
@HiveType(typeId: 7)
class NotificationSettingModel extends HiveObject {
  /// ID unik notifikasi — dipakai oleh flutter_local_notifications
  /// untuk membedakan notif pagi (0), siang (1), malam (2)
  @HiveField(0)
  int notificationId;

  /// Label tampilan, contoh: "Sarapan", "Makan Siang", "Makan Malam"
  @HiveField(1)
  String label;

  /// Jam notifikasi (0–23)
  @HiveField(2)
  int hour;

  /// Menit notifikasi (0–59)
  @HiveField(3)
  int minute;

  /// Teks judul notifikasi yang bisa dikustomisasi user
  @HiveField(4)
  String title;

  /// Teks isi/body notifikasi yang bisa dikustomisasi user
  @HiveField(5)
  String body;

  /// Apakah notifikasi ini aktif atau tidak
  @HiveField(6)
  bool isEnabled;

  NotificationSettingModel({
    required this.notificationId,
    required this.label,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    this.isEnabled = true,
  });

  /// Default settings untuk ketiga sesi makan
  static List<NotificationSettingModel> defaultSettings() {
    return [
      NotificationSettingModel(
        notificationId: 0,
        label: 'Sarapan',
        hour: 7,
        minute: 0,
        title: '🌅 Waktunya Sarapan!',
        body: 'Mulai hari dengan sarapan bergizi. Jangan lupa catat makanmu!',
      ),
      NotificationSettingModel(
        notificationId: 1,
        label: 'Makan Siang',
        hour: 12,
        minute: 0,
        title: '☀️ Waktunya Makan Siang!',
        body: 'Isi energi untuk sore hari. Sudah catat nutrisimu hari ini?',
      ),
      NotificationSettingModel(
        notificationId: 2,
        label: 'Makan Malam',
        hour: 19,
        minute: 0,
        title: '🌙 Waktunya Makan Malam!',
        body: 'Jangan sampai kelewatan makan malam. Pilih menu yang sehat ya!',
      ),
    ];
  }
}