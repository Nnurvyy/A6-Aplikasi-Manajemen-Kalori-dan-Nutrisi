import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'package:nutritrack_app/features/user/dashboard/controllers/dashboard_controller.dart';
import 'package:nutritrack_app/features/general/food/controllers/food_controller.dart';
import 'package:nutritrack_app/features/general/food/models/log_model.dart';
import 'package:nutritrack_app/helpers/date_controller.dart';
import 'package:nutritrack_app/helpers/app_colors.dart';
import 'package:nutritrack_app/services/offline_storage_service.dart';
import 'package:nutritrack_app/helpers/string_helper.dart';

import 'package:nutritrack_app/features/general/food/views/food_detail_view.dart';
import 'package:nutritrack_app/features/general/food/models/food_model.dart';
import 'package:nutritrack_app/services/hive_service.dart';
import 'package:nutritrack_app/features/general/food/controllers/watchlist_controller.dart';
import 'dart:io';

import 'package:percent_indicator/circular_percent_indicator.dart';

/// Widget murni isi dashboard — TANPA Scaffold/BottomNav sendiri.
/// Dibungkus oleh UserMainView yang sudah punya satu BottomAppBar.
class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

enum NutritionState {
  normal,
  warning,
  danger,
}

  // ─────────────────────────────────────────────────────────────
  // GLOBAL HANDLER
  // ─────────────────────────────────────────────────────────────

  NutritionState nutritionState(
    double consumed,
    double target, {
    bool allowOverConsume = true,
  }) {
    final ratio = consumed / target;

    if (!allowOverConsume) {
      return NutritionState.normal;
    }

    if (ratio <= 1.10) {
      return NutritionState.normal;
    }

    if (ratio <= 1.25) {
      return NutritionState.warning;
    }

    return NutritionState.danger;
  }

class _DashboardBodyState extends State<DashboardBody> {
  final DashboardController _controller = DashboardController();
  int _riwayatPage = 0;
  static const int _riwayatItemsPerPage = 7;
  final ScrollController _daySelectorController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.init();
    // Sync initial today's date to global controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final initialDate = _controller.days[_controller.selectedDayIndex].date;
        context.read<DateController>().setDate(initialDate);
        _scrollToSelectedDay();

        // Sync foods for current user
        final auth = context.read<AuthController>();
        final foodCtrl = context.read<FoodController>();
        final userId = auth.currentUser?.id;
        
        if (userId != null) {
          foodCtrl.syncWithFirebase(userId: userId);
          foodCtrl.syncLogsFromFirebase(userId: userId); // ← TAMBAHKAN INI
        }
      }
    });
  }

  @override
  void dispose() {
    _daySelectorController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_daySelectorController.hasClients) return;
      const itemWidth = 38.0 + 6.0; // width + separator
      final offset = _controller.selectedDayIndex * itemWidth;
      _daySelectorController.animateTo(
        offset.clamp(0.0, _daySelectorController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _showMonthYearPicker() async {
    final now = DateTime.now();
    int selectedYear = _controller.viewYear;
    int selectedMonth = _controller.viewMonth;
    final months = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    final years = List.generate(10, (i) => now.year - i);

    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Pilih Bulan', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFF4F6F0),
                  border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _wheelPicker(
                        items: months,
                        selected: selectedMonth - 1,
                        onChanged: (i) => setS(() => selectedMonth = i + 1),
                        label: 'Bulan',
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFF2E7D32).withValues(alpha: 0.1)),
                    Expanded(
                      flex: 1,
                      child: _wheelPicker(
                        items: years.map((y) => y.toString()).toList(),
                        selected: years.indexOf(selectedYear).clamp(0, years.length - 1),
                        onChanged: (i) => setS(() => selectedYear = years[i]),
                        label: 'Tahun',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${months[selectedMonth - 1]} $selectedYear',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final picked = DateTime(selectedYear, selectedMonth);
                if (picked.isAfter(DateTime(now.year, now.month + 1))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tidak bisa memilih bulan di masa depan')),
                  );
                } else {
                  Navigator.pop(ctx, picked);
                }
              },
              child: const Text('Pilih'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _controller.setViewMonthYear(result.year, result.month);
        _riwayatPage = 0;
      });
      final newDate = _controller.days[_controller.selectedDayIndex].date;
      context.read<DateController>().setDate(newDate);
      _scrollToSelectedDay();
    }
  }

  Widget _wheelPicker({required List<String> items, required int selected, required void Function(int) onChanged, required String label}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32).withValues(alpha: 0.6))),
        ),
        Expanded(
          child: ListWheelScrollView(
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: selected.clamp(0, items.length - 1)),
            onSelectedItemChanged: onChanged,
            children: items.asMap().entries.map((e) {
              final isSelected = e.key == selected;
              return Center(
                child: Text(
                  e.value,
                  style: GoogleFonts.poppins(
                    fontSize: isSelected ? 16 : 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final foodController = context.watch<FoodController>();

    final kaloriTarget = user?.dailyCalorieNeed ?? 2000.0;
    final macros = user?.macroTargets;

    final isMonitor = auth.isMonitoring;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: HiveService.logs.listenable(),
          builder: (context, box, child) {
            final selectedDate = _controller.days[_controller.selectedDayIndex].date;
            // Re-calculate history whenever box changes
            List<LogModel> history = [];
            if (user != null) {
              history = foodController.getUserLogs(user.id);
            }

            final filteredHistory = history.where((log) {
              final logDate = DateTime(
                log.consumedAt.year,
                log.consumedAt.month,
                log.consumedAt.day,
              );
              return logDate.isAtSameMomentAs(selectedDate);
            }).toList();

            // Calculate consumed macros
            final kaloriConsumed = filteredHistory.fold(0.0, (s, i) => s + i.calories);
            final proteinConsumed = filteredHistory.fold(0.0, (s, i) => s + i.protein);
            final carbsConsumed = filteredHistory.fold(0.0, (s, i) => s + i.carbs);
            final fatConsumed = filteredHistory.fold(0.0, (s, i) => s + i.fat);
            final waterConsumed = filteredHistory.fold(0.0, (s, i) {
              if (i.foodName.toLowerCase() == 'air putih') {
                return s + (i.servingSize * i.quantity);
              }
              return s;
            });

            _controller.kaloriTarget = kaloriTarget;
            _controller.kaloriConsumed = kaloriConsumed;

            return RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  await foodController.syncWithFirebase(userId: user.id);
                  await foodController.syncLogsFromFirebase(userId: user.id);
                }
              },
              color: const Color(0xFF2E7D32),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(selectedDate, auth),
                    _buildDaySelector(),
                    _buildKaloriCard(),
                    const SizedBox(height: 8),
                    _buildNutriGrid(
                      proteinConsumed,
                      carbsConsumed,
                      fatConsumed,
                      waterConsumed,
                      macros,
                    ),
                    const SizedBox(height: 8),
                    _buildRiwayatHeader(),
                    _buildRiwayatList(filteredHistory, isMonitor),
                    const SizedBox(height: 100), // ruang agar tidak ketutup navbar
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader(DateTime selectedDate, AuthController auth) {
    final List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final List<String> bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final dateStr = '${hari[selectedDate.weekday - 1]}, ${selectedDate.day} ${bulan[selectedDate.month - 1]}';
    final user = auth.currentUser;
    final isMonitor = auth.isMonitoring;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMonitor ? 'Mode Pantau' : 'NutriTrack',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isMonitor ? const Color(0xFF1976D2) : const Color(0xFF2E7D32),
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: _showMonthYearPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isMonitor ? const Color(0xFF1976D2) : const Color(0xFF2E7D32)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: isMonitor ? const Color(0xFF1976D2) : const Color(0xFF2E7D32), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isMonitor ? const Color(0xFF1976D2) : const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_rounded, color: isMonitor ? const Color(0xFF1976D2) : const Color(0xFF2E7D32), size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isMonitor && user != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.child_care_rounded, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Memantau: ${user.name}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.age ?? '-'} tahun • ${user.gender ?? '-'} • ${user.weight?.toStringAsFixed(1) ?? '-'} kg',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  // ─── DAY SELECTOR ─────────────────────────────────────────────────────────
  Widget _buildDaySelector() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        controller: _daySelectorController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _controller.days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final day = _controller.days[index];
          final isActive = index == _controller.selectedDayIndex;
          // Is it today?
          final now = DateTime.now();
          final isToday = day.date.year == now.year && day.date.month == now.month && day.date.day == now.day;
          return GestureDetector(
            onTap: () {
              setState(() {
                _controller.selectDay(index);
                _riwayatPage = 0;
              });
              context.read<DateController>().setDate(day.date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2E7D32) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isActive
                    ? Border.all(color: const Color(0xFF2E7D32), width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFF5A7A5A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.number}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : (isToday ? const Color(0xFF2E7D32) : const Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  

  double nutritionRatio(double consumed, double target) {
    return consumed / target;
  }

  Color _dangerRed() {
    return const Color(0xFFD96C6C);
  }

  // ─────────────────────────────────────────────────────────────
  // KALORI CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildKaloriCard() {
    final consumed = _controller.kaloriConsumed;
    final target = _controller.kaloriTarget;

    final ratio = nutritionRatio(consumed, target);
    final state = nutritionState(consumed, target);

    final bool isWarning = state == NutritionState.warning;
    final bool isDanger = state == NutritionState.danger;

    final displayPct = ratio.clamp(0.0, 1.0);

    final difference = target - consumed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: isDanger
                ? const Color.fromARGB(255, 230, 200, 200)
                : isWarning
                    ? const Color(0xFF7A8D7B)
                    : const Color(0xFFC8E6C9),
            width: isWarning || isDanger ? 2 : 1.5,
          ),

          boxShadow: [
            BoxShadow(
              color: isDanger
                  ? _dangerRed().withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCalorieRing(displayPct, ratio, state),

              const SizedBox(height: 18),

              const Text(
                'Kalori',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                ratio < 1
                    ? '${difference.toInt()} kkal dibutuhkan'
                    : ratio <= 1.10
                        ? 'Target tercapai (${consumed.toInt()} / ${target.toInt()} kkal)'
                        : '${consumed.toInt()} / ${target.toInt()} kkal',

                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ratio < 1
                      ? const Color(0xFF5A7A5A)
                      : ratio <= 1.10
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFD96C6C),
                ),
              ),

              if (ratio > 1.0) ...[
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${(consumed - target).toInt()} kkal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _dangerRed(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MAIN BATTERY BAR
  // ─────────────────────────────────────────────────────────────

  Widget _buildCalorieRing(
    double displayPercentage,
    double rawRatio,
    NutritionState state,
  ) {
    final bool isWarning = state == NutritionState.warning;
    final bool isDanger = state == NutritionState.danger;

    final progress = displayPercentage.clamp(0.0, 1.0);

    final Color progressColor = isDanger
        ? const Color(0xFFE53935)
        : isWarning
            ? const Color(0xFFFFA000)
            : const Color(0xFF2E7D32);

    return CircularPercentIndicator(
      radius: 82,
      lineWidth: 16,
      percent: progress,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animateFromLastPercent: true,
      backgroundColor: isDanger
        ? const Color(0xFFFFEBEE)
        : isWarning
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFE8F5E9),
      progressColor: progressColor,

      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDanger
                ? Icons.report_problem_rounded
                : isWarning
                    ? Icons.warning_amber_rounded
                    : Icons.local_fire_department,
            color: progressColor,
            size: 36,
          ),

          const SizedBox(height: 4),

          Text(
            '${(rawRatio * 100).toInt()}%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: progressColor,
            ),
          ),

          Text(
            isDanger
                ? 'Melebihi Target'
                : isWarning
                    ? 'Melebihi Target'
                    : 'Normal',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── NUTRISI GRID ─────────────────────────────────────────────────────────
  Widget _buildNutriGrid(
    double consumedProtein,
    double consumedCarbs,
    double consumedFat,
    double consumedWater, [
    Map<String, double>? macros,
  ]) {
    final items = [
      ..._controller.nutrisiItemsWithTargets(
        consumedProtein: consumedProtein,
        targetProtein: macros?['protein'] ?? 80,
        consumedCarbs: consumedCarbs,
        targetCarbs: macros?['carbs'] ?? 250,
        consumedFat: consumedFat,
        targetFat: macros?['fat'] ?? 65,
      ),

      // 🔥 TAMBAH AIR
      NutrisiItem(
        name: 'Air',
        consumed: consumedWater,
        target: macros?['water'] ?? 2000, // ml
        icon: Icons.water_drop,
        iconColor: const Color(0xFF1E88E5),
        bgColor: const Color(0xFFE3F2FD),
        borderColor: const Color(0xFF64B5F6),
        fillColor: const Color(0xFF42A5F5),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          return _buildNutriCard(items[index]);
        },
      ),
    );
  }

  Widget _buildNutriCard(NutrisiItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            item.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: item.iconColor,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildMiniBattery(item),
          const Spacer(),
          Text(
            '${item.consumed.round()} / ${item.target.round()}${item.name == "Air" ? "ml" : "g"}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: item.borderColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── HELPER: warna dinamis berdasarkan persentase ────────────────────────
  //
  // 0%   → sangat pudar
  // 50%  → sedang
  // 100% → penuh
  // >100% → bergeser ke merah (over-target)

  // ─────────────────────────────────────────────────────────────
  // DYNAMIC COLORS
  // ─────────────────────────────────────────────────────────────

  Color _dynamicFillColor(NutrisiItem item) {
    return item.fillColor;
  }

  Color _dynamicBorderColor(NutrisiItem item) {
    return item.borderColor;
  }

  Color _dynamicIconColor(NutrisiItem item) {
    return item.iconColor;
  }

  Widget _buildMiniBattery(NutrisiItem item) {
    final bool isOver = item.rawPercentage > 1.10;

    if (isOver) {
      return _WaterSpillBattery(item: item);
    }

    final displayPct = item.percentage.clamp(0.0, 1.0);
    final Color dynBorder = _dynamicBorderColor(item);
    final Color dynFill = _dynamicFillColor(item);
    final Color dynIcon = _dynamicIconColor(item);

    return SizedBox(
      width: 46,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 14,
              height: 5,
              decoration: BoxDecoration(
                color: dynBorder,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ),
          ),

          Positioned(
            top: 5,
            child: Container(
              width: 46,
              height: 48,
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: dynBorder,
                  width: 2,
                ),
                boxShadow: [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    FractionallySizedBox(
                      heightFactor: displayPct,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: dynFill,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        item.icon,
                        color: dynIcon,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEPARATOR "Riwayat Makanan" ──────────────────────────────────────────

  Widget _buildRiwayatHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: const Color(0xFFD0E8D0))),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Riwayat Makanan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: const Color(0xFFD0E8D0))),
        ],
      ),
    );
  }

  // ─── RIWAYAT LIST ─────────────────────────────────────────────────────────

  Widget _buildRiwayatList(List<LogModel> history, bool isMonitor) {
    final sortedHistory = List<LogModel>.from(history)
      ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

    if (sortedHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.no_meals_rounded,
                  color: Color(0xFF4CAF50),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Belum ada makanan hari ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tekan tombol + untuk menambahkan\nmakanan dari database atau scan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5A7A5A),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildRiwayatPaginated(sortedHistory, isMonitor),
    );
  }

  // ─── RIWAYAT PAGINATED ───────────────────────────────────────────────────

  Widget _buildRiwayatPaginated(List<LogModel> sortedHistory, bool isMonitor) {
    final totalPages = sortedHistory.isEmpty ? 1 : (sortedHistory.length / _riwayatItemsPerPage).ceil();
    final safeCurrentPage = _riwayatPage.clamp(0, totalPages - 1);
    final startIndex = safeCurrentPage * _riwayatItemsPerPage;
    final endIndex = (startIndex + _riwayatItemsPerPage).clamp(
      0,
      sortedHistory.length,
    );
    final pageItems =
        sortedHistory.isEmpty
            ? <LogModel>[]
            : sortedHistory.sublist(startIndex, endIndex);

    return Column(
      children: [
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  '${sortedHistory.length} entri',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5A7A5A),
                  ),
                ),
                const Spacer(),
                Text(
                  'Hal. ${safeCurrentPage + 1}/$totalPages',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5A7A5A),
                  ),
                ),
              ],
            ),
          ),
        ...pageItems.map((item) => _buildFoodHistoryCard(item, isMonitor)),
        if (totalPages > 1) _buildRiwayatPagination(safeCurrentPage, totalPages),
      ],
    );
  }

  Widget _buildRiwayatPagination(int current, int total) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0E8D0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _riwayatPageBtn(
            Icons.chevron_left_rounded,
            current > 0,
            () => setState(() => _riwayatPage--),
          ),
          const SizedBox(width: 8),
          ...List.generate(total, (i) {
            final isActive = i == current;
            return GestureDetector(
              onTap: () => setState(() => _riwayatPage = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color:
                      isActive ? const Color(0xFF2E7D32) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isActive
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFD0E8D0),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : const Color(0xFF5A7A5A),
                    ),
                  ),
                ),
              ),
            );
          }).take(7),
          const SizedBox(width: 8),
          _riwayatPageBtn(
            Icons.chevron_right_rounded,
            current < total - 1,
            () => setState(() => _riwayatPage++),
          ),
        ],
      ),
    );
  }

  Widget _riwayatPageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFFD0E8D0) : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color:
              enabled
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF5A7A5A).withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // ─── FOOD HISTORY CARD ────────────────────────────────────────────────────

  Widget _buildFoodHistoryCard(LogModel item, bool isMonitor) {
    final Color accentColor = _categoryColor(item.category);

    // ── The actual card widget ──
    final Widget card = GestureDetector(
      onTap: isMonitor ? null : () => _showFoodDetailModal(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildHistoryAvatar(item, accentColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    StringHelper.getFoodHistoryDisplayName(item.foodName, item.quantity, item.category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    StringHelper.formatCategory(item.category),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5A7A5A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _nutriChip('P ${item.protein.round()}g', const Color(0xFFFFEBEE), const Color(0xFFE53935)),
                      const SizedBox(width: 4),
                      _nutriChip('K ${item.carbs.round()}g', const Color(0xFFFFF8E1), const Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      _nutriChip('L ${item.fat.round()}g', const Color(0xFFFFF3E0), const Color(0xFFFF8C00)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item.calories.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
                const Text('kkal', style: TextStyle(fontSize: 10, color: Color(0xFF5A7A5A))),
                const SizedBox(height: 4),
                Text(
                  "${item.consumedAt.hour.toString().padLeft(2, '0')}:${item.consumedAt.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Icon(
                  item.syncStatus == 'synced' ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                  size: 14,
                  color: item.syncStatus == 'synced' ? const Color(0xFF4CAF50) : const Color(0xFFF59E0B),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Monitor users cannot swipe
    if (isMonitor) return card;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // ── Swipe RIGHT → Toggle Watchlist ──
          final auth = context.read<AuthController>();
          final userId = auth.currentUser?.id;
          if (userId == null) return false;
          final watchlist = context.read<WatchlistController>();
          final totalWeight = item.servingSize * (item.quantity > 0 ? item.quantity : 1);
          double getPer100(double total) => totalWeight > 0 ? (total * 100) / totalWeight : 0;
          final food = FoodModel(
            id: 'log_${item.id}',
            name: item.foodName,
            category: item.category,
            calories: getPer100(item.calories),
            protein: getPer100(item.protein),
            carbs: getPer100(item.carbs),
            fat: getPer100(item.fat),
            defaultServingSize: item.servingSize,
            isApproved: true,
            createdAt: item.consumedAt,
            imageUrl: item.imageUrl,
            ingredientsJson: item.ingredientsJson,
          );
          await watchlist.toggleWatchlist(userId, food);
          final isNowSaved = watchlist.isInWatchlist(userId, food.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isNowSaved ? '${item.foodName} disimpan ke watchlist' : '${item.foodName} dihapus dari watchlist'),
              backgroundColor: isNowSaved ? const Color(0xFF1E88E5) : const Color(0xFF78909C),
              duration: const Duration(seconds: 2),
            ));
          }
          return false; // don't dismiss the card
        } else {
          // ── Swipe LEFT → Confirm delete ──
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Hapus Riwayat?', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text('Hapus "${item.foodName}" dari riwayat?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ) ?? false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<FoodController>().deleteLog(item.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${item.foodName} dihapus dari riwayat'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ));
        }
      },
      // Left/right swipe reveal backgrounds
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: const Color(0xFF1E88E5), borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      child: card,
    );
  }

  // ─── MODAL DETAIL ─────────────────────────────────────────────────────────

  // ─── HELPER TO RECONSTRUCT FOOD MODEL ─────────────────────────────────────
  FoodModel _reconstructFood(LogModel log) {
    // Total weight consumed for this log entry
    final totalWeight = log.servingSize * (log.quantity > 0 ? log.quantity : 1);

    // Formula: per100 = (totalValue * 100) / totalWeight
    double getPer100(double total) =>
        totalWeight > 0 ? (total * 100) / totalWeight : 0;

    return FoodModel(
      id: 'log_${log.id}',
      name: log.foodName,
      category: log.category,
      calories: getPer100(log.calories),
      protein: getPer100(log.protein),
      carbs: getPer100(log.carbs),
      fat: getPer100(log.fat),
      defaultServingSize: log.servingSize, // This is the grams per 1 pc
      isApproved: true,
      createdAt: log.consumedAt,
      imageUrl: log.imageUrl,
      ingredientsJson: log.ingredientsJson,
    );
  }

  void _showFoodDetailModal(LogModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                FoodDetailView(food: _reconstructFood(item), initialLog: item),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Widget _nutriChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }



  Widget _buildHistoryAvatar(LogModel item, Color accentColor) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return FutureBuilder<File?>(
        future: OfflineStorageService.getImageFile(item.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 22, color: Colors.grey),
              )
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(snapshot.data!, fit: BoxFit.cover, width: 46, height: 46);
          }
          return Center(
            child: Text(
              item.foodName.isNotEmpty ? item.foodName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          );
        },
      );
    }
    return Center(
      child: Text(
        item.foodName.isNotEmpty ? item.foodName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: accentColor,
        ),
      ),
    );
  }



  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'lauk':
        return const Color(0xFF4CAF50);
      case 'makanan pokok':
        return const Color(0xFFF59E0B);
      case 'sayuran':
        return const Color(0xFF43A047);
      case 'buah':
        return const Color(0xFFE91E63);
      case 'minuman':
        return const Color(0xFF1E88E5);
      case 'snack':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF78909C);
    }
  }
}

// Alias agar import lama tetap compile
typedef DashboardView = DashboardBody;

// ─────────────────────────────────────────────────────────────────────────────
// WATER SPILL BATTERY  — ditampilkan saat nutrisi melebihi target (>110 %)
// Animasi: gelombang air yang meluap keluar dari baterai
// ─────────────────────────────────────────────────────────────────────────────

class _WaterSpillBattery extends StatefulWidget {
  final NutrisiItem item;
  const _WaterSpillBattery({required this.item});

  @override
  State<_WaterSpillBattery> createState() => _WaterSpillBatteryState();
}

class _WaterSpillBatteryState extends State<_WaterSpillBattery>
    with TickerProviderStateMixin {
  late AnimationController _waveCtrl;

  late Animation<double> _wavePhase;

  @override
  void initState() {
    super.initState();

    // Continuous wave inside battery
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _wavePhase = Tween<double>(begin: 0.0, end: 2 * dart_math.pi).animate(
      CurvedAnimation(parent: _waveCtrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color spillColor = widget.item.fillColor.withValues(alpha: 0.85);
    final Color borderColor = widget.item.borderColor;
    final Color iconColor = widget.item.iconColor;

    return AnimatedBuilder(
      animation: Listenable.merge([_waveCtrl]),
      builder: (_, __) {
        return SizedBox(
          width: 52,
          height: 54,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // ── Battery tip ───────────────────────────────────
              Positioned(
                top: 0,
                child: Container(
                  width: 14,
                  height: 5,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ),
              ),

              // ── Battery body ──────────────────────────────────
              Positioned(
                top: 5,
                child: Container(
                  width: 46,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.item.bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: spillColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: _WavePainter(
                        phase: _wavePhase.value,
                        fillColor: spillColor,
                        // Full (over) → wave at top
                        waterLevel: 0.92,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        );
      },
    );
  }
}

/// CustomPainter that draws a sine-wave water surface inside the battery
class _WavePainter extends CustomPainter {
  final double phase;
  final Color fillColor;
  final double waterLevel; // 0.0 = empty, 1.0 = full

  _WavePainter({
    required this.phase,
    required this.fillColor,
    required this.waterLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final double yBase = size.height * (1.0 - waterLevel);
    const double amplitude = 3.5;
    const double frequency = 2.0;

    path.moveTo(0, size.height);
    path.lineTo(0, yBase);

    for (double x = 0; x <= size.width; x++) {
      final double y = yBase +
          amplitude *
              dart_math.sin(
                  (x / size.width * frequency * 2 * dart_math.pi) + phase);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.phase != phase || old.waterLevel != waterLevel;
}