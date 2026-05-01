import 'package:hive/hive.dart';

/// Model untuk menyimpan berat badan aktual user per bulan.
/// typeId = 5
class WeightLogModel extends HiveObject {
  String id;
  String userId;

  /// Tahun + Bulan yang dicatat (hari selalu 1)
  DateTime month; // e.g. DateTime(2025, 4, 1)

  /// Berat badan aktual yang diinput user (kg)
  /// null jika user melewati input → sistem pakai perhitungan
  double? actualWeight;

  WeightLogModel({
    required this.id,
    required this.userId,
    required this.month,
    this.actualWeight,
  });
}

class WeightLogModelAdapter extends TypeAdapter<WeightLogModel> {
  @override
  final int typeId = 5;

  @override
  WeightLogModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return WeightLogModel(
      id: f[0] as String,
      userId: f[1] as String,
      month: f[2] as DateTime,
      actualWeight: (f[3] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, WeightLogModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.actualWeight);
  }
}
