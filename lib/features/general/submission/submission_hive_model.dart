import 'package:hive/hive.dart';
import 'submission_model.dart';

/// Hive-persistable version of SubmissionModel.
/// TypeId: 6 (0-5 sudah terpakai oleh model lain)
class SubmissionHiveModel extends HiveObject {
  String id;
  String userId;
  String userName;
  String foodName;
  String imagePath;
  double? calories;
  double? protein;
  double? carbs;
  double? fat;
  int statusIndex; // SubmissionStatus.index
  DateTime createdAt;
  String? reviewNote;
  String? nutriNote;

  SubmissionHiveModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.foodName,
    required this.imagePath,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    required this.statusIndex,
    required this.createdAt,
    this.reviewNote,
    this.nutriNote,
  });

  SubmissionStatus get status => SubmissionStatus.values[statusIndex];

  SubmissionModel toModel() => SubmissionModel(
    id: id,
    userId: userId,
    userName: userName,
    foodName: foodName,
    imagePath: imagePath,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    status: status,
    createdAt: createdAt,
    reviewNote: reviewNote,
    nutriNote: nutriNote,
  );

  factory SubmissionHiveModel.fromModel(SubmissionModel m) =>
      SubmissionHiveModel(
        id: m.id,
        userId: m.userId,
        userName: m.userName,
        foodName: m.foodName,
        imagePath: m.imagePath,
        calories: m.calories,
        protein: m.protein,
        carbs: m.carbs,
        fat: m.fat,
        statusIndex: m.status.index,
        createdAt: m.createdAt,
        reviewNote: m.reviewNote,
        nutriNote: m.nutriNote,
      );
}

/// Manual adapter (menggantikan build_runner)
class SubmissionHiveModelAdapter extends TypeAdapter<SubmissionHiveModel> {
  @override
  final int typeId = 6;

  @override
  SubmissionHiveModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return SubmissionHiveModel(
      id: f[0] as String,
      userId: f[1] as String,
      userName: f[2] as String,
      foodName: f[3] as String,
      imagePath: f[4] as String,
      calories: f[5] as double?,
      protein: f[6] as double?,
      carbs: f[7] as double?,
      fat: f[8] as double?,
      statusIndex: f[9] as int,
      createdAt: f[10] as DateTime,
      reviewNote: f[11] as String?,
      nutriNote: f[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SubmissionHiveModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.foodName)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.calories)
      ..writeByte(6)
      ..write(obj.protein)
      ..writeByte(7)
      ..write(obj.carbs)
      ..writeByte(8)
      ..write(obj.fat)
      ..writeByte(9)
      ..write(obj.statusIndex)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.reviewNote)
      ..writeByte(12)
      ..write(obj.nutriNote);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmissionHiveModelAdapter && typeId == other.typeId;
}
