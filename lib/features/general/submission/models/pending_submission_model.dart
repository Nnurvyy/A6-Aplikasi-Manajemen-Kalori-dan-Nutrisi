import 'package:hive/hive.dart';

part 'pending_submission_model.g.dart';

/// Model Hive untuk menyimpan submission yang belum berhasil diupload ke cloud.
/// Dipakai sebagai antrian offline — kalau app ditutup sebelum upload selesai,
/// data ini tetap ada dan akan dicoba ulang saat app dibuka lagi.
@HiveType(typeId: 6)
class PendingSubmissionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String userName;

  @HiveField(3)
  String foodName;

  /// Path file lokal dari image_picker — masih di storage device
  @HiveField(4)
  String localImagePath;

  @HiveField(5)
  DateTime createdAt;

  PendingSubmissionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.foodName,
    required this.localImagePath,
    required this.createdAt,
  });
}
