import 'package:flutter/material.dart';

// ─── DATA MODELS ──────────────────────────────────────────────────────────────

class DayItem {
  final DateTime date;
  final String label;
  final int number;
  const DayItem({required this.date, required this.label, required this.number});
}

class NutrisiItem {
  final String name;
  final double consumed;
  final double target;
  final IconData icon;
  final Color bgColor;
  final Color fillColor;
  final Color borderColor;
  final Color iconColor;

  const NutrisiItem({
    required this.name,
    required this.consumed,
    required this.target,
    required this.icon,
    required this.bgColor,
    required this.fillColor,
    required this.borderColor,
    required this.iconColor,
  });

  double get percentage => (consumed / target).clamp(0.0, 1.0);
}

// ─── FOOD HISTORY MODEL ───────────────────────────────────────────────────────
// Strukturnya mengacu pada FoodModel (id, name, category, calories, protein,
// carbs, fat, servingSize) ditambah metadata log (consumedAt, mealTime).

class FoodHistoryItem {
  final String id;
  final String name;
  final String category;
  final double calories; // kkal per 100g
  final double protein; // g per 100g
  final double carbs; // g per 100g
  final double fat; // g per 100g
  final double servingSize; // gram yang dikonsumsi
  final DateTime consumedAt;
  final String mealTime; // 'Sarapan' | 'Makan Siang' | 'Makan Malam' | 'Snack'

  const FoodHistoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.consumedAt,
    required this.mealTime,
  });

  // Nilai aktual berdasarkan serving size
  double get totalCalories => calories * servingSize / 100;
  double get totalProtein => protein * servingSize / 100;
  double get totalCarbs => carbs * servingSize / 100;
  double get totalFat => fat * servingSize / 100;
}

// ─── CONTROLLER ───────────────────────────────────────────────────────────────

class DashboardController {
  // ── State ──
  int selectedDayIndex = 0;
  int selectedNavIndex = 0;

  // ── Kalori data (nanti dihitung dari recentFoodHistory) ──
  double kaloriConsumed = 760;
  double kaloriTarget = 2000; // akan di-update dari profil user

  double get kaloriPercentage =>
      (kaloriConsumed / kaloriTarget).clamp(0.0, 1.0);

  // ── Days ──
  List<DayItem> days = [];

  void initDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    days = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      return DayItem(
        date: d,
        label: labels[d.weekday - 1],
        number: d.day,
      );
    });
    selectedDayIndex = 6; // Default to today
  }

  // ── Nutrisi items ──
  List<NutrisiItem> get nutrisiItems => [
    NutrisiItem(
      name: 'Protein',
      consumed: 35,
      target: 80,
      icon: Icons.fitness_center,
      bgColor: const Color(0xFFFFEBEE),
      fillColor: const Color(0xFFFFCDD2),
      borderColor: const Color(0xFFEF9A9A),
      iconColor: const Color(0xFFE53935),
    ),
    NutrisiItem(
      name: 'Karbohidrat',
      consumed: 160,
      target: 250,
      icon: Icons.grain,
      bgColor: const Color(0xFFFFF8E1),
      fillColor: const Color(0xFFFFD54F),
      borderColor: const Color(0xFFFFCA28),
      iconColor: const Color(0xFFF59E0B),
    ),
    NutrisiItem(
      name: 'Lemak',
      consumed: 28,
      target: 65,
      icon: Icons.water_drop,
      bgColor: const Color(0xFFFFF3E0),
      fillColor: const Color(0xFFFFE0B2),
      borderColor: const Color(0xFFFFCC80),
      iconColor: const Color(0xFFFF8C00),
    ),
  ];

  // ── Nutrisi items dengan target kustom (dari profil user) ──
  List<NutrisiItem> nutrisiItemsWithTargets({
    required double consumedProtein,
    required double targetProtein,
    required double consumedCarbs,
    required double targetCarbs,
    required double consumedFat,
    required double targetFat,
  }) => [
    NutrisiItem(
      name: 'Protein',
      consumed: consumedProtein,
      target: targetProtein,
      icon: Icons.fitness_center,
      bgColor: const Color(0xFFFFEBEE),
      fillColor: const Color(0xFFFFCDD2),
      borderColor: const Color(0xFFEF9A9A),
      iconColor: const Color(0xFFE53935),
    ),
    NutrisiItem(
      name: 'Karbohidrat',
      consumed: consumedCarbs,
      target: targetCarbs,
      icon: Icons.grain,
      bgColor: const Color(0xFFFFF8E1),
      fillColor: const Color(0xFFFFD54F),
      borderColor: const Color(0xFFFFCA28),
      iconColor: const Color(0xFFF59E0B),
    ),
    NutrisiItem(
      name: 'Lemak',
      consumed: consumedFat,
      target: targetFat,
      icon: Icons.water_drop,
      bgColor: const Color(0xFFFFF3E0),
      fillColor: const Color(0xFFFFE0B2),
      borderColor: const Color(0xFFFFCC80),
      iconColor: const Color(0xFFFF8C00),
    ),
  ];

  // ── Food History — 3 makanan terakhir (dummy) ──
  // Ganti list ini dengan data dari Hive/API saat integrasi.
  // Untuk menguji empty state, kosongkan list ini: []
  List<FoodHistoryItem> get recentFoodHistory => [
    FoodHistoryItem(
      id: 'fh-003',
      name: 'Ayam Krispi',
      category: 'Lauk',
      calories: 260,
      protein: 25,
      carbs: 10,
      fat: 15,
      servingSize: 150,
      consumedAt: DateTime(2025, 4, 25, 19, 30),
      mealTime: 'Makan Malam',
    ),
    FoodHistoryItem(
      id: 'fh-002',
      name: 'Nasi Putih',
      category: 'Makanan Pokok',
      calories: 130,
      protein: 2.7,
      carbs: 28,
      fat: 0.3,
      servingSize: 200,
      consumedAt: DateTime(2025, 4, 25, 12, 15),
      mealTime: 'Makan Siang',
    ),
    FoodHistoryItem(
      id: 'fh-001',
      name: 'Telur Rebus',
      category: 'Lauk',
      calories: 155,
      protein: 13,
      carbs: 1.1,
      fat: 11,
      servingSize: 100,
      consumedAt: DateTime(2025, 4, 25, 7, 30),
      mealTime: 'Sarapan',
    ),
  ];

  // ─── LIFECYCLE ──────────────────────────────────────────────────────────────

  void init() {
    initDays();
  }

  // ─── USER ACTIONS ───────────────────────────────────────────────────────────

  void selectDay(int index) {
    selectedDayIndex = index;
  }

  void selectNav(int index) {
    selectedNavIndex = index;
  }

  void onSettingsTapped() {
    // TODO: navigasi ke Settings
  }

  // ── FAB: buka FoodListView (database) ──
  void onAddFromDatabaseTapped(BuildContext context) {
    // TODO: navigasi ke FoodListView
    // Navigator.push(context,
    //   MaterialPageRoute(builder: (_) => const FoodListView()));
  }

  // ── FAB: buka ScanView ──
  void onScanTapped(BuildContext context) {
    // TODO: navigasi ke ScanView
    // Navigator.push(context,
    //   MaterialPageRoute(builder: (_) => const ScanView()));
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  double get kaloriRemaining =>
      (kaloriTarget - kaloriConsumed).clamp(0, kaloriTarget);

  Color get kaloriStatusColor {
    if (kaloriPercentage < 0.5) return const Color(0xFF4CAF50);
    if (kaloriPercentage < 0.85) return const Color(0xFFF59E0B);
    return const Color(0xFFE53935);
  }

  String get kaloriStatusLabel {
    if (kaloriPercentage < 0.5) return 'Masih aman';
    if (kaloriPercentage < 0.85) return 'Hampir tercapai';
    return 'Batas tercapai';
  }

  String formatMealTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
