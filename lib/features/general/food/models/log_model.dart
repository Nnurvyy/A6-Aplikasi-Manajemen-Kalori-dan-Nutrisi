import 'package:hive/hive.dart';

class LogModel extends HiveObject {
  String id;
  String userId;
  String foodName;
  double calories;
  double protein;
  double carbs;
  double fat;
  String mealType; 
  DateTime consumedAt;
  String syncStatus; // pending or synced
  double servingSize; 
  String category;
  bool isManual;
  String? imageUrl;
  String? ingredientsJson;
  int quantity; // New field for pieces/servings

  LogModel({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
    required this.consumedAt,
    this.syncStatus = 'pending', // Default
    required this.servingSize,
    required this.category,
    this.isManual = false,
    this.imageUrl,
    this.ingredientsJson,
    this.quantity = 1, // Default to 1
  });

  String get formattedTime {
    return "${consumedAt.hour.toString().padLeft(2, '0')}:${consumedAt.minute.toString().padLeft(2, '0')}";
  }

  LogModel copyWith({
    String? id,
    String? userId,
    String? foodName,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? mealType,
    DateTime? consumedAt,
    String? syncStatus,
    double? servingSize,
    String? category,
    bool? isManual,
    String? imageUrl,
    String? ingredientsJson,
    int? quantity,
  }) {
    return LogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      mealType: mealType ?? this.mealType,
      consumedAt: consumedAt ?? this.consumedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      servingSize: servingSize ?? this.servingSize,
      category: category ?? this.category,
      isManual: isManual ?? this.isManual,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredientsJson: ingredientsJson ?? this.ingredientsJson,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Konversi ke Map untuk dikirim ke Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'mealType': mealType,
      'consumedAt': consumedAt.toIso8601String(),
      'syncStatus': 'synced', // selalu 'synced' saat dikirim ke Firestore
      'servingSize': servingSize,
      'category': category,
      'isManual': isManual,
      'imageUrl': imageUrl,
      'ingredientsJson': ingredientsJson,
      'quantity': quantity,
    };
  }

  /// Konversi dari dokumen Firestore ke LogModel
  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      foodName: json['foodName'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      mealType: json['mealType'] as String,
      consumedAt: DateTime.parse(json['consumedAt'] as String),
      syncStatus: json['syncStatus'] as String? ?? 'synced',
      servingSize: (json['servingSize'] as num).toDouble(),
      category: json['category'] as String? ?? '',
      isManual: json['isManual'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      ingredientsJson: json['ingredientsJson'] as String?,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class LogModelAdapter extends TypeAdapter<LogModel> {
  @override
  final int typeId = 2; 

  @override
  LogModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return LogModel(
      id: f[0] as String,
      userId: f[1] as String,
      foodName: f[2] as String,
      calories: f[3] as double,
      protein: f[4] as double,
      carbs: f[5] as double,
      fat: f[6] as double,
      mealType: f[7] as String,
      consumedAt: f[8] as DateTime,
      syncStatus: f[9] as String,
      servingSize: (f[10] as double?) ?? 100.0,
      category: (f[11] as String?) ?? '',
      isManual: (f[12] as bool?) ?? false,
      imageUrl: f[13] as String?,
      ingredientsJson: f[14] as String?,
      quantity: (f[15] as int?) ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, LogModel obj) {
    writer
      ..writeByte(16) // Total fields
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.userId)
      ..writeByte(2)..write(obj.foodName)
      ..writeByte(3)..write(obj.calories)
      ..writeByte(4)..write(obj.protein)
      ..writeByte(5)..write(obj.carbs)
      ..writeByte(6)..write(obj.fat)
      ..writeByte(7)..write(obj.mealType)
      ..writeByte(8)..write(obj.consumedAt)
      ..writeByte(9)..write(obj.syncStatus)
      ..writeByte(10)..write(obj.servingSize)
      ..writeByte(11)..write(obj.category)
      ..writeByte(12)..write(obj.isManual)
      ..writeByte(13)..write(obj.imageUrl)
      ..writeByte(14)..write(obj.ingredientsJson)
      ..writeByte(15)..write(obj.quantity);
  }
}
