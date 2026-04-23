import 'package:hive/hive.dart';

class UserModel extends HiveObject {
  String id;
  String name;
  String email;
  String password;

  /// 'user' | 'admin' | 'nutritionist'
  String role;

  double? weight;     // kg
  double? height;     // cm
  int? age;
  String? gender;     // 'Laki-laki' | 'Perempuan'
  String? activityLevel;
  String? medicalHistory;
  double? dailyCalorieNeed;
  DateTime? birthDate;
  bool isBlocked;
  double? targetWeightGainPerMonth; // kg/bulan (pos = naik, neg = turun)

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.weight,
    this.height,
    this.age,
    this.gender,
    this.activityLevel,
    this.medicalHistory,
    this.dailyCalorieNeed,
    this.birthDate,
    this.isBlocked = false,
    this.targetWeightGainPerMonth,
  });

  /// Target makro harian (gram)
  Map<String, double> get macroTargets {
    final cal = dailyCalorieNeed ?? 2000;
    return {
      'protein': (cal * 0.30) / 4,
      'carbs': (cal * 0.50) / 4,
      'fat': (cal * 0.20) / 9,
    };
  }
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: f[0] as String,
      name: f[1] as String,
      email: f[2] as String,
      password: f[3] as String,
      role: f[4] as String,
      weight: f[5] as double?,
      height: f[6] as double?,
      age: f[7] as int?,
      gender: f[8] as String?,
      activityLevel: f[9] as String?,
      medicalHistory: f[10] as String?,
      dailyCalorieNeed: f[11] as double?,
      birthDate: f[12] as DateTime?,
      isBlocked: f[13] as bool? ?? false,
      targetWeightGainPerMonth: f[14] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.email)
      ..writeByte(3)..write(obj.password)
      ..writeByte(4)..write(obj.role)
      ..writeByte(5)..write(obj.weight)
      ..writeByte(6)..write(obj.height)
      ..writeByte(7)..write(obj.age)
      ..writeByte(8)..write(obj.gender)
      ..writeByte(9)..write(obj.activityLevel)
      ..writeByte(10)..write(obj.medicalHistory)
      ..writeByte(11)..write(obj.dailyCalorieNeed)
      ..writeByte(12)..write(obj.birthDate)
      ..writeByte(13)..write(obj.isBlocked)
      ..writeByte(14)..write(obj.targetWeightGainPerMonth);
  }
}
