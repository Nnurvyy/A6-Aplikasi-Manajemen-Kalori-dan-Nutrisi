import 'package:hive/hive.dart';
import './food_model.dart';

@HiveType(typeId: 3)
class WatchlistModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final FoodModel food;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  bool isSynced;

  WatchlistModel({
    required this.id,
    required this.userId,
    required this.food,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'food': food.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WatchlistModel.fromMap(Map<String, dynamic> map) {
    return WatchlistModel(
      id: map['id'],
      userId: map['userId'],
      food: FoodModel.fromMap(map['food']),
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: true,
    );
  }
}

class WatchlistModelAdapter extends TypeAdapter<WatchlistModel> {
  @override
  final int typeId = 3;

  @override
  WatchlistModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WatchlistModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      food: fields[2] as FoodModel,
      createdAt: fields[3] as DateTime,
      isSynced: fields[4] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, WatchlistModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.userId)
      ..writeByte(2)..write(obj.food)
      ..writeByte(3)..write(obj.createdAt)
      ..writeByte(4)..write(obj.isSynced);
  }
}
