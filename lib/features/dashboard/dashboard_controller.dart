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

  // ─── LIFECYCLE ──────────────────────────────────────────────────────────────

  void init() {
    // TODO: load data dari local DB atau API
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // TODO: panggil repository / service untuk ambil data harian
    // Contoh:
    // final data = await NutrisiRepository.getDailyData(selectedDate);
    // kaloriConsumed = data.kalori;
    // ...
  }

  // ─── USER ACTIONS ───────────────────────────────────────────────────────────

  void selectDay(int index) {
    selectedDayIndex = index;
    // TODO: reload data sesuai hari yang dipilih
    _loadDashboardData();
  }

  void selectNav(int index) {
    selectedNavIndex = index;
    // TODO: navigasi ke halaman sesuai index
    // Contoh pakai GoRouter / Navigator:
    // switch (index) {
    //   case 1: context.go('/riwayat'); break;
    //   case 2: context.go('/pengajuan'); break;
    //   case 3: context.go('/profile'); break;
    // }
  }

  void onAddTapped() {
    // TODO: buka bottom sheet / halaman tambah makanan
    // showModalBottomSheet(context: context, builder: (_) => TambahMakananSheet());
  }

  void onSettingsTapped() {
    // TODO: navigasi ke halaman settings
    // context.go('/settings');
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  /// Sisa kalori yang masih bisa dikonsumsi hari ini
  double get kaloriRemaining => (kaloriTarget - kaloriConsumed).clamp(0, kaloriTarget);

  /// Status warna berdasarkan persentase kalori
  Color get kaloriStatusColor {
    if (kaloriPercentage < 0.5) return const Color(0xFF4CAF50);
    if (kaloriPercentage < 0.85) return const Color(0xFFF59E0B);
    return const Color(0xFFE53935);
  }

  /// Label status kalori
  String get kaloriStatusLabel {
    if (kaloriPercentage < 0.5) return 'Masih aman';
    if (kaloriPercentage < 0.85) return 'Hampir tercapai';
    return 'Batas tercapai';
  }
}