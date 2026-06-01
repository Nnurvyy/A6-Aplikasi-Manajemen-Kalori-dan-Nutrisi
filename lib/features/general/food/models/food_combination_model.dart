import 'package:hive/hive.dart';
import './food_model.dart';

@HiveType(typeId: 4) 
class FoodCombinationModel extends HiveObject {
  
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final List<FoodModel> foods;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  bool isSynced;

  FoodCombinationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.foods,
    required this.createdAt,
    this.isSynced = false,
  });
}


class FoodCombinationModelAdapter extends TypeAdapter<FoodCombinationModel> {
  @override
  final int typeId = 4;

  @override
  FoodCombinationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodCombinationModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      foods: (fields[3] as List).cast<FoodModel>(),
      createdAt: fields[4] as DateTime,
      isSynced: fields[5] == true,
    );
  }

  @override
  void write(BinaryWriter writer, FoodCombinationModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.userId)
      ..writeByte(2)..write(obj.title)
      ..writeByte(3)..write(obj.foods)
      ..writeByte(4)..write(obj.createdAt)
      ..writeByte(5)..write(obj.isSynced);
  }
}