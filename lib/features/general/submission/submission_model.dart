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
  });

  bool get isNutriFilled =>
      calories != null && protein != null && carbs != null && fat != null;

  SubmissionModel copyWith({
    String? foodName,
    SubmissionStatus? status,
    String? reviewNote,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? nutriNote,
  }) {
    return SubmissionModel(
      id: id,
      userId: userId,
      userName: userName,
      foodName: foodName ?? this.foodName,
      imagePath: imagePath,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      status: status ?? this.status,
      createdAt: createdAt,
      reviewNote: reviewNote ?? this.reviewNote,
      nutriNote: nutriNote ?? this.nutriNote,
    );
  }
}
