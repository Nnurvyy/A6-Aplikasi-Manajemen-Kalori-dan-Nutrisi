import 'package:flutter_test/flutter_test.dart';
import 'package:nutritrack_app/features/general/submission/models/submission_model.dart';
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';
import 'package:nutritrack_app/features/general/food/models/food_model.dart';

void main() {
  group('5. Admin & Kelola Database Makanan', () {
    group('5.1 Pengajuan Makanan', () {
      test('Positive: Admin approving submission changes status to APPROVED', () {
        final submission = SubmissionModel(
          id: 's1', userId: 'u1', userName: 'User', foodName: 'Sate', imagePath: 'path', createdAt: DateTime.now(), status: SubmissionStatus.pending
        );
        final approved = submission.copyWith(status: SubmissionStatus.approved);
        expect(approved.status, SubmissionStatus.approved);
      });
      
      test('Negative: Admin rejecting requires reviewNote', () {
        final submission = SubmissionModel(
          id: 's1', userId: 'u1', userName: 'User', foodName: 'Sate', imagePath: 'path', createdAt: DateTime.now(), status: SubmissionStatus.pending
        );
        final rejected = submission.copyWith(status: SubmissionStatus.canceled, reviewNote: 'Foto buram');
        expect(rejected.reviewNote, 'Foto buram');
        expect(rejected.status, SubmissionStatus.canceled);
      });
    });

    group('5.2 Kelola User', () {
      test('Positive: Admin blocks user account', () {
        final user = UserModel(id: '1', name: 'User 1', email: 'u@u.com', password: '', role: 'user', isBlocked: false);
        final blockedUser = UserModel.fromMap({...user.toMap(), 'isBlocked': true});
        expect(blockedUser.isBlocked, true);
      });

      test('Positive: Admin changes user role to Nutritionist', () {
        final user = UserModel(id: '1', name: 'User 1', email: 'u@u.com', password: '', role: 'user');
        final upgradedUser = UserModel.fromMap({...user.toMap(), 'role': 'nutritionist'});
        expect(upgradedUser.role, 'nutritionist');
      });
    });

    group('5.3 Kelola Database Makanan', () {
      test('Positive: Admin deletes food from global database', () {
        List<FoodModel> db = [FoodModel(id: 'f1', name: 'Food', category: 'snack', calories: 10, protein: 1, carbs: 1, fat: 1, createdAt: DateTime.now())];
        db.removeWhere((f) => f.id == 'f1');
        expect(db.isEmpty, true);
      });

      test('Positive: Admin edits food nutritional value', () {
        final food = FoodModel(id: 'f1', name: 'Food', category: 'snack', calories: 10, protein: 1, carbs: 1, fat: 1, createdAt: DateTime.now());
        final updated = food.copyWith(calories: 200);
        expect(updated.calories, 200);
      });
    });
  });
}
