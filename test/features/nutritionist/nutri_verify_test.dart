import 'package:flutter_test/flutter_test.dart';
import 'package:nutritrack_app/features/general/submission/models/submission_model.dart';

void main() {
  group('6. Ahli Nutrisi (Verifikasi Gizi)', () {
    test('Positive: Nutritionist inputting macros flags data as COMPLETE', () {
      final approved = SubmissionModel(
        id: 's1', userId: 'u1', userName: 'User', foodName: 'Sate', imagePath: 'path', createdAt: DateTime.now(), status: SubmissionStatus.approved
      );
      final filled = approved.copyWith(calories: 200, protein: 10, carbs: 15, fat: 5);
      expect(filled.isNutriFilled, true);
    });

    test('Edge Case: Nutritionist leaves field empty, isNutriFilled returns false', () {
      final approved = SubmissionModel(
        id: 's1', userId: 'u1', userName: 'User', foodName: 'Sate', imagePath: 'path', createdAt: DateTime.now(), status: SubmissionStatus.approved
      );
      final incomplete = approved.copyWith(calories: 200, protein: null);
      expect(incomplete.isNutriFilled, false);
    });

    test('Positive: Nutritionist adds nutriNote recommendation', () {
      final approved = SubmissionModel(
        id: 's1', userId: 'u1', userName: 'User', foodName: 'Sate', imagePath: 'path', createdAt: DateTime.now(), status: SubmissionStatus.approved
      );
      final reviewed = approved.copyWith(nutriNote: 'Porsi terlalu banyak minyak');
      expect(reviewed.nutriNote, 'Porsi terlalu banyak minyak');
    });
  });
}
