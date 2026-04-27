class CalorieHelper {
  /// Hitung BMR dengan rumus
  /// Pria = 66.47 + (13.75 x berat [kg]) + (5.003 x tinggi [cm]) - (6.755 x usia [tahun])
  /// Wanita = 655.1 + (9.563 x berat [kg]) + (1.85 x tinggi [cm]) - (4.676 x usia [tahun])
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'laki-laki') {
      return 66.47 + (13.75 * weightKg) + (5.003 * heightCm) - (6.755 * age);
    } else {
      return 655.1 + (9.563 * weightKg) + (1.85 * heightCm) - (4.676 * age);
    }
  }

  /// Faktor aktivitas 
  static double getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedikit aktif atau tidak berolahraga':
      case 'jarang olahraga':
        return 1.2;
      case 'olahraga ringan (1-3 hari/minggu)':
      case 'olahraga ringan (1-3 kali seminggu)':
        return 1.375;
      case 'cukup aktif (olahraga sekitar 3-5 hari/minggu)':
      case 'olahraga sedang (3-5 kali seminggu)':
        return 1.55;
      case 'sangat aktif (olahraga berat/olahraga 6-7 hari seminggu)':
      case 'olahraga berat (6-7 hari seminggu / ngegym)':
        return 1.725;
      case 'ekstra aktif (berolahraga secara berat disertai pekerjaan fisik)':
      case 'sangat berat (latihan fisik ekstra / atlet)':
        return 1.9;
      default:
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

  /// Hitung kebutuhan kalori harian dengan target kenaikan/penurunan BB
  /// 1 kg ≈ 7500 kalori
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
    
    // Perhitungan Surplus/Defisit:
    // 1 kg = 7500 kkal (rata-rata referensi user)
    // Surplus harian = (target kg * 7500) / 30 hari
    final dailyAdjustment = (targetWeightGainPerMonth * 7500) / 30;
    
    return tdee + dailyAdjustment;
  }

  /// Hitung target makro sesuai referensi:
  /// Protein: 10-15% (diambil 15%), 1g = 4 kkal
  /// Lemak: 10-25% (diambil 20%), 1g = 9 kkal
  /// Karbo: 60-75% (diambil 65%), 1g = 4 kkal
  static Map<String, double> calculateMacros(double dailyCalories) {
    return {
      'protein': (dailyCalories * 0.15) / 4,
      'fat': (dailyCalories * 0.20) / 9,
      'carbs': (dailyCalories * 0.65) / 4,
    };
  }

  static String formatCalorie(double cal) => cal.toStringAsFixed(0);
  static String formatNutrient(double g) => '${g.toStringAsFixed(1)}g';
}
