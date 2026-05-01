import 'package:hive/hive.dart';

class FoodModel extends HiveObject {
  String id;
  String name;
  String category;  // 'makanan pokok', 'lauk', 'sayuran', 'buah', 'minuman', 'snack', 'lainnya'
  double calories;  // kcal per 100g
  double protein;   // g per 100g
  double carbs;     // g per 100g
  double fat;       // g per 100g
  double defaultServingSize; // grams (default quantity when scanned)
  bool isApproved;
  DateTime createdAt;
  String? imageUrl;
  String? description;

  FoodModel({
    required this.id,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.defaultServingSize = 100,
    this.isApproved = true,
    required this.createdAt,
    this.imageUrl,
    this.description,
  });

  /// Hitung nutrisi untuk jumlah tertentu (gram)
  Map<String, double> nutritionForAmount(double grams) {
    final ratio = grams / 100;
    return {
      'calories': calories * ratio,
      'protein': protein * ratio,
      'carbs': carbs * ratio,
      'fat': fat * ratio,
    };
  }
}

class FoodModelAdapter extends TypeAdapter<FoodModel> {
  @override
  final int typeId = 1;

  @override
  FoodModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return FoodModel(
      id: f[0] as String,
      name: f[1] as String,
      category: f[2] as String,
      calories: f[3] as double,
      protein: f[4] as double,
      carbs: f[5] as double,
      fat: f[6] as double,
      isApproved: f[7] as bool? ?? true,
      createdAt: f[8] as DateTime,
      imageUrl: f[9] as String?,
      description: f[10] as String?,
      defaultServingSize: f[11] as double? ?? 100,
    );
  }

  @override
  void write(BinaryWriter writer, FoodModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.category)
      ..writeByte(3)..write(obj.calories)
      ..writeByte(4)..write(obj.protein)
      ..writeByte(5)..write(obj.carbs)
      ..writeByte(6)..write(obj.fat)
      ..writeByte(7)..write(obj.isApproved)
      ..writeByte(8)..write(obj.createdAt)
      ..writeByte(9)..write(obj.imageUrl)
      ..writeByte(10)..write(obj.description)
      ..writeByte(11)..write(obj.defaultServingSize);
  }
}
