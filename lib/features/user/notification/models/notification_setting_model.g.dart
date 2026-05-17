// GENERATED CODE - Adapter ditulis manual mengikuti pola proyek ini.
// Kalau tim beralih ke build_runner, hapus file ini dan jalankan:
// flutter pub run build_runner build --delete-conflicting-outputs

part of 'notification_setting_model.dart';

class NotificationSettingModelAdapter
    extends TypeAdapter<NotificationSettingModel> {
  @override
  final int typeId = 7;

  @override
  NotificationSettingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettingModel(
      notificationId: fields[0] as int,
      label: fields[1] as String,
      hour: fields[2] as int,
      minute: fields[3] as int,
      title: fields[4] as String,
      body: fields[5] as String,
      isEnabled: fields[6] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettingModel obj) {
    writer
      ..writeByte(7) // jumlah field
      ..writeByte(0)
      ..write(obj.notificationId)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.hour)
      ..writeByte(3)
      ..write(obj.minute)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.body)
      ..writeByte(6)
      ..write(obj.isEnabled);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}