import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? ingredientsJson;
  bool isManualIngredient;
  String? userId;
  bool isSynced;

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
    this.ingredientsJson,
    this.isManualIngredient = false,
    this.userId, 
    this.isSynced = true,
  });

  factory FoodModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return FoodModel(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Lainnya',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      defaultServingSize: (map['defaultServingSize'] as num?)?.toDouble() ?? 100.0,
      isApproved: map['isApproved'] ?? true,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt']))
          : DateTime.now(),
      imageUrl: map['imageUrl'],
      description: map['description'],
      ingredientsJson: map['ingredientsJson'],
      isManualIngredient: map['isManualIngredient'] ?? false,
      userId: map['userId'], // ← TAMBAHKAN INI
      isSynced: true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'defaultServingSize': defaultServingSize,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'description': description,
      'ingredientsJson': ingredientsJson,
      'isManualIngredient': isManualIngredient,
      'userId': userId, 
    };
  }


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

  FoodModel copyWith({
    String? id,
    String? name,
    String? category,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? defaultServingSize,
    bool? isApproved,
    DateTime? createdAt,
    String? imageUrl,
    String? description,
    String? ingredientsJson,
    bool? isManualIngredient,
    String? userId, 
    bool? isSynced,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      defaultServingSize: defaultServingSize ?? this.defaultServingSize,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      ingredientsJson: ingredientsJson ?? this.ingredientsJson,
      isManualIngredient: isManualIngredient ?? this.isManualIngredient,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'defaultServingSize': defaultServingSize,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'description': description,
      'ingredientsJson': ingredientsJson,
      'isManualIngredient': isManualIngredient,
      'userId': userId, 
      'isSynced': isSynced,
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'lainnya',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      defaultServingSize: (map['defaultServingSize'] as num?)?.toDouble() ?? 100.0,
      isApproved: map['isApproved'] ?? true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      imageUrl: map['imageUrl'],
      description: map['description'],
      ingredientsJson: map['ingredientsJson'],
      isManualIngredient: map['isManualIngredient'] ?? false,
      userId: map['userId'],
      isSynced: map['isSynced'] ?? true,
    );
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
      ingredientsJson: f[12] as String?,
      isManualIngredient: f[13] as bool? ?? false,
      userId: f[14] as String?,
      isSynced: f[15] as bool ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, FoodModel obj) {
    writer
      ..writeByte(16) 
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
      ..writeByte(11)..write(obj.defaultServingSize)
      ..writeByte(12)..write(obj.ingredientsJson)
      ..writeByte(13)..write(obj.isManualIngredient)
      ..writeByte(14)..write(obj.userId)
      ..writeByte(15)..write(obj.isSynced);
  }
}
