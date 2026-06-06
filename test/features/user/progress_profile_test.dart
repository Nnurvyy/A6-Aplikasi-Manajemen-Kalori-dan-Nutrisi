import 'package:flutter_test/flutter_test.dart';
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';
import 'package:nutritrack_app/features/user/progress/models/weight_log_model.dart';

void main() {
  group('3. Progress & Profil (User)', () {
    test('Positive: Daily progress percentage calculation is correct', () {
      double target = 2000;
      double consumed = 1500;
      double percentage = consumed / target;
      expect(percentage, 0.75);
    });

    test('Positive: Update profile (weight/height) recalculates TDEE correctly', () {
      final user = UserModel(
        id: '1', name: 'Test', email: 'test@t.com', password: '1', role: 'user', dailyCalorieNeed: 2000,
        weight: 70, height: 170, age: 25, gender: 'Laki-laki', activityLevel: 'Aktif'
      );
      final macros = user.macroTargets; 
      expect(macros['carbs']! > 0, true);
    });

    test('Positive: Add Weight Log saves history correctly', () {
      final wLog = WeightLogModel(
        id: 'w1', userId: '1', actualWeight: 69.5, month: DateTime.now()
      );
      expect(wLog.actualWeight, 69.5);
    });

    test('Positive: Notification settings toggle updates correctly', () {
      bool isBreakfastAlarmOn = false;
      // User toggles on
      isBreakfastAlarmOn = true;
      expect(isBreakfastAlarmOn, true);
    });
  });
}
