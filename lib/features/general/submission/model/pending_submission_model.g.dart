// GENERATED CODE - Karena proyek ini tidak pakai build_runner untuk submission,
// adapter ditulis manual. Kalau pakai build_runner, hapus file ini dan jalankan:
// flutter pub run build_runner build --delete-conflicting-outputs

part of 'pending_submission_model.dart';

class PendingSubmissionModelAdapter
    extends TypeAdapter<PendingSubmissionModel> {
  @override
  final int typeId = 6;

  @override
  PendingSubmissionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingSubmissionModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      userName: fields[2] as String,
      foodName: fields[3] as String,
      localImagePath: fields[4] as String,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PendingSubmissionModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.foodName)
      ..writeByte(4)
      ..write(obj.localImagePath)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingSubmissionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
