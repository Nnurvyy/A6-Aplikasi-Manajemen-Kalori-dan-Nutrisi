import 'package:flutter_test/flutter_test.dart';
import 'package:nutritrack_app/helpers/calorie_helper.dart';

void main() {
  group('Calorie & Macro Calculations (CalorieHelper)', () {
    test('Positive: calculateBMR returns correct value for Men and Women', () {
      // Mifflin-St Jeor formula tests
      // Pria = 66.47 + (13.75 x weight) + (5.003 x height) - (6.755 x age)
      final bmrMale = CalorieHelper.calculateBMR(
        weightKg: 70,
        heightCm: 170,
        age: 25,
        gender: 'laki-laki',
      );
      // 66.47 + 962.5 + 850.51 - 168.875 = 1710.605
      expect(bmrMale, closeTo(1710.605, 0.01));

      // Wanita = 655.1 + (9.563 x weight) + (1.85 x height) - (4.676 x age)
      final bmrFemale = CalorieHelper.calculateBMR(
        weightKg: 50,
        heightCm: 160,
        age: 30,
        gender: 'perempuan',
      );
      // 655.1 + 478.15 + 296.0 - 140.28 = 1288.97
      expect(bmrFemale, closeTo(1288.97, 0.01));
    });

    test('Positive: getActivityMultiplier returns correct value based on level', () {
      expect(CalorieHelper.getActivityMultiplier('jarang olahraga'), 1.2);
      expect(CalorieHelper.getActivityMultiplier('olahraga ringan (1-3 hari/minggu)'), 1.375);
      expect(CalorieHelper.getActivityMultiplier('olahraga sedang (3-5 kali seminggu)'), 1.55);
      expect(CalorieHelper.getActivityMultiplier('olahraga berat (6-7 hari seminggu / ngegym)'), 1.725);
      expect(CalorieHelper.getActivityMultiplier('sangat berat (latihan fisik ekstra / atlet)'), 1.9);
      expect(CalorieHelper.getActivityMultiplier('random_level'), 1.2); // Default
    });

    test('Positive: calculateTDEE calculates based on BMR and multiplier', () {
      // 70kg, 170cm, 25 years old male, 'jarang olahraga' (multiplier 1.2)
      // BMR = 1710.605
      // TDEE = 1710.605 * 1.2 = 2052.726
      final tdee = CalorieHelper.calculateTDEE(
        weightKg: 70,
        heightCm: 170,
        age: 25,
        gender: 'laki-laki',
        activityLevel: 'jarang olahraga',
      );
      expect(tdee, closeTo(2052.726, 0.01));
    });

    test('Positive: calculateDailyCalorieNeed adjusts based on weight target', () {
      // TDEE = 2052.726. Target gain = 1kg per month
      // Adjustment = (1 * 7500) / 30 = 250
      // Kebutuhan = 2052.726 + 250 = 2302.726
      final need = CalorieHelper.calculateDailyCalorieNeed(
        weightKg: 70,
        heightCm: 170,
        age: 25,
        gender: 'laki-laki',
        activityLevel: 'jarang olahraga',
        targetWeightGainPerMonth: 1.0,
      );
      expect(need, closeTo(2302.726, 0.01));
    });

    test('Positive: calculateMacros returns correct targets', () {
      // 2000 calories
      // Protein: 15% / 4 kkal = 300 / 4 = 75g
      // Fat: 20% / 9 kkal = 400 / 9 = 44.44g
      // Carbs: 65% / 4 kkal = 1300 / 4 = 325g
      final macros = CalorieHelper.calculateMacros(2000);
      expect(macros['protein'], closeTo(75.0, 0.01));
      expect(macros['fat'], closeTo(44.44, 0.01));
      expect(macros['carbs'], closeTo(325.0, 0.01));
    });

    test('Positive: formatCalorie and formatNutrient formats properly', () {
      expect(CalorieHelper.formatCalorie(2000.4), '2000');
      expect(CalorieHelper.formatNutrient(75.26), '75.3g');
    });
  });
}
