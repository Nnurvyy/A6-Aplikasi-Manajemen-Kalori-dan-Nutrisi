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
  });

  SubmissionModel copyWith({
    SubmissionStatus? status,
    String? reviewNote,
  }) {
    return SubmissionModel(
      id: id,
      userId: userId,
      userName: userName,
      foodName: foodName,
      imagePath: imagePath,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      status: status ?? this.status,
      createdAt: createdAt,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }
}
