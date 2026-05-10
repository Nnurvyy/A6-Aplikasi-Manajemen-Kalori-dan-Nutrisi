enum SubmissionStatus { pending, approved, canceled }

enum UserRole { user, admin, nutritionist }

class SubmissionModel {
  final String id;
  final String userId;
  final String userName;
  final String foodName;
  final String imagePath;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final SubmissionStatus status;
  final DateTime createdAt;
  final String? reviewNote;
  final String? nutriNote;

  /// false = data belum tersimpan ke cloud (masih antri / offline)
  /// true  = sudah ada di Firestore
  final bool isSynced;

  SubmissionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.foodName,
    required this.imagePath,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.status = SubmissionStatus.pending,
    required this.createdAt,
    this.reviewNote,
    this.nutriNote,
    this.isSynced = true, // default true — data dari Firestore selalu synced
  });

  bool get isNutriFilled =>
      calories != null && protein != null && carbs != null && fat != null;

  SubmissionModel copyWith({
    String? foodName,
    String? imagePath,
    SubmissionStatus? status,
    String? reviewNote,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? nutriNote,
    bool? isSynced,
  }) {
    return SubmissionModel(
      id: id,
      userId: userId,
      userName: userName,
      foodName: foodName ?? this.foodName,
      imagePath: imagePath ?? this.imagePath,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      status: status ?? this.status,
      createdAt: createdAt,
      reviewNote: reviewNote ?? this.reviewNote,
      nutriNote: nutriNote ?? this.nutriNote,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
