class CalorieHelper {
  /// Hitung BMR dengan Mifflin-St Jeor Equation
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'laki-laki') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  /// Faktor aktivitas berdasarkan pilihan "Tambahan Aktivitas" untuk Mahasiswa JTK
  static double getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'jarang olahraga':
        return 1.2;
      case 'olahraga ringan (1-3 kali seminggu)':
        return 1.375;
      case 'olahraga sedang (3-5 kali seminggu)':
        return 1.55;
      case 'olahraga berat (6-7 hari seminggu / ngegym)':
        return 1.725;
      case 'sangat berat (latihan fisik ekstra / atlet)':
        return 1.9;
      default:
        // Asumsikan standar mahasiswa (banyak duduk/coding, jarang olahraga = 1.2)
        return 1.2;
    }
  }

  /// Hitung TDEE
  static double calculateTDEE({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
  }) {
    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
    return bmr * getActivityMultiplier(activityLevel);
  }

  /// Hitung kebutuhan kalori harian dengan target kenaikan BB
  static double calculateDailyCalorieNeed({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    double targetWeightGainPerMonth = 0,
  }) {
    final tdee = calculateTDEE(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
    );
    // 7700 kcal ≈ 1 kg lemak tubuh
    final dailyAdjustment = (targetWeightGainPerMonth * 7700) / 30;
    return tdee + dailyAdjustment;
  }

  /// Hitung target makro (protein, karbo, lemak) dalam gram
  static Map<String, double> calculateMacros(double dailyCalories) {
    return {
      'protein': (dailyCalories * 0.30) / 4, // 4 kcal/g
      'carbs': (dailyCalories * 0.50) / 4,   // 4 kcal/g
      'fat': (dailyCalories * 0.20) / 9,     // 9 kcal/g
    };
  }

  /// Format angka kalori
  static String formatCalorie(double cal) => cal.toStringAsFixed(0);
  static String formatNutrient(double g) => '${g.toStringAsFixed(1)}g';
}
