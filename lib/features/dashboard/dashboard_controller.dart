import 'package:flutter/material.dart';


// ─── DATA MODELS ──────────────────────────────────────────────────────────────

class DayItem {
  final String label;
  final int number;

  const DayItem({required this.label, required this.number});
}

class NutrisiItem {
  final String name;
  final double consumed;   // gram dikonsumsi
  final double target;     // gram target
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

class FoodHistoryItem {
  final String id;
  final String name;
  final String category;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize; // grams
  final DateTime consumedAt;
  final String mealTime; // 'Sarapan', 'Makan Siang', 'Makan Malam', 'Snack'

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

  // Kalori aktual berdasarkan serving size
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

  // ── Kalori data ──
  double kaloriConsumed = 760;
  double kaloriTarget   = 2000;

  double get kaloriPercentage => (kaloriConsumed / kaloriTarget).clamp(0.0, 1.0);

  // ── Days ──
  final List<DayItem> days = const [
    DayItem(label: 'sen', number: 6),
    DayItem(label: 'sel', number: 7),
    DayItem(label: 'rab', number: 8),
    DayItem(label: 'kam', number: 9),
    DayItem(label: 'jum', number: 10),
    DayItem(label: 'sab', number: 11),
    DayItem(label: 'min', number: 12),
  ];

  // ── Nutrisi items ──
  List<NutrisiItem> get nutrisiItems => [
    NutrisiItem(
      name: 'Protein',
      consumed: 35,
      target: 80,
      icon: Icons.fitness_center,
      bgColor:    const Color(0xFFFFEBEE),
      fillColor:  const Color(0xFFFFCDD2),
      borderColor:const Color(0xFFEF9A9A),
      iconColor:  const Color(0xFFE53935),
    ),
    NutrisiItem(
      name: 'Karbohidrat',
      consumed: 160,
      target: 250,
      icon: Icons.grain,
      bgColor:    const Color(0xFFFFF8E1),
      fillColor:  const Color(0xFFFFF9C4),
      borderColor:const Color(0xFFFFE082),
      iconColor:  const Color(0xFFF59E0B),
    ),
    NutrisiItem(
      name: 'Lemak',
      consumed: 28,
      target: 65,
      icon: Icons.water_drop,
      bgColor:    const Color(0xFFFFF3E0),
      fillColor:  const Color(0xFFFFE0B2),
      borderColor:const Color(0xFFFFCC80),
      iconColor:  const Color(0xFFFF8C00),
    ),
  ];

  // ── Food History (dummy data, 3 makanan terakhir) ──
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
    // TODO: load data dari local DB atau API
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // TODO: panggil repository / service untuk ambil data harian
  }

  // ─── USER ACTIONS ───────────────────────────────────────────────────────────

  void selectDay(int index) {
    selectedDayIndex = index;
    _loadDashboardData();
  }

  void selectNav(int index) {
    selectedNavIndex = index;
  }

  void onAddTapped() {
    // TODO: buka bottom sheet / halaman tambah makanan
  }

  void onSettingsTapped() {
    // TODO: navigasi ke halaman settings
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  double get kaloriRemaining => (kaloriTarget - kaloriConsumed).clamp(0, kaloriTarget);

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