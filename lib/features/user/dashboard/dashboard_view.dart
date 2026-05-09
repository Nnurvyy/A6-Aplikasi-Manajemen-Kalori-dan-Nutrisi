import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../general/auth/auth_controller.dart';
import './dashboard_controller.dart';
import '../../general/food/food_controller.dart';
import '../../general/food/models/log_model.dart';
import '../../../helpers/date_controller.dart';
import '../manual_food/manual_food_form_view.dart';
import '../../general/food/food_detail_view.dart';
import '../../general/food/models/food_model.dart';
import 'dart:io';
import 'dart:convert';

/// Widget murni isi dashboard — TANPA Scaffold/BottomNav sendiri.
/// Dibungkus oleh UserMainView yang sudah punya satu BottomAppBar.
class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
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
                  border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2)),
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
                    Container(width: 1, color: const Color(0xFF2E7D32).withOpacity(0.1)),
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
          child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32).withOpacity(0.6))),
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
    final user = context.watch<AuthController>().currentUser;
    final foodController = context.watch<FoodController>();

    final kaloriTarget = user?.dailyCalorieNeed ?? 2000.0;
    final macros = user?.macroTargets;

    // Filter history by selected date
    List<LogModel> history = [];
    if (user != null) {
      history = foodController.getUserLogs(user.id);
    }
    
    final selectedDate = _controller.days[_controller.selectedDayIndex].date;
    final filteredHistory = history.where((log) {
      final logDate = DateTime(log.consumedAt.year, log.consumedAt.month, log.consumedAt.day);
      return logDate.isAtSameMomentAs(selectedDate);
    }).toList();

    // Calculate consumed macros
    final kaloriConsumed = filteredHistory.fold(0.0, (s, i) => s + i.calories);
    final proteinConsumed = filteredHistory.fold(0.0, (s, i) => s + i.protein);
    final carbsConsumed = filteredHistory.fold(0.0, (s, i) => s + i.carbs);
    final fatConsumed = filteredHistory.fold(0.0, (s, i) => s + i.fat);
    final waterConsumed = filteredHistory.fold(0.0, (s, i) {
      if (i.foodName.toLowerCase() == 'air putih') {
        return s + i.servingSize;
      }
      return s;
    });

    _controller.kaloriTarget = kaloriTarget;
    _controller.kaloriConsumed = kaloriConsumed;

    final isMonitor = context.watch<AuthController>().isMonitoring;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(selectedDate, context.watch<AuthController>()),
              _buildDaySelector(),
              _buildKaloriCard(),
              const SizedBox(height: 8),
              _buildNutriGrid(proteinConsumed, carbsConsumed, fatConsumed,waterConsumed , macros),
              const SizedBox(height: 8),
              _buildRiwayatHeader(),
              _buildRiwayatList(filteredHistory, context.watch<AuthController>().isMonitoring),
              const SizedBox(height: 100), // ruang agar tidak ketutup navbar
            ],
          ),
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
                    color: (isMonitor ? const Color(0xFF1976D2) : const Color(0xFF2E7D32)).withOpacity(0.12),
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
                      color: const Color(0xFF1976D2).withOpacity(0.2),
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

  // ─── KALORI CARD ──────────────────────────────────────────────────────────
  Widget _buildKaloriCard() {
    final pct = _controller.kaloriPercentage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildBatteryBar(pct),
            const SizedBox(height: 14),
            const Text(
              'Kalori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_controller.kaloriConsumed.toInt()} / ${_controller.kaloriTarget.toInt()} kkal',
              style: const TextStyle(fontSize: 13, color: Color(0xFF5A7A5A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryBar(double percentage) {
    final bool isCompleted = percentage >= 1.0;
    final displayPercentage = percentage > 1.0 ? 1.0 : percentage;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E7D32), width: 2),
                boxShadow: isCompleted ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, spreadRadius: 2)] : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isCompleted ? 11 : 12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FractionallySizedBox(
                        widthFactor: displayPercentage,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle_rounded : Icons.local_fire_department,
                              color: isCompleted ? Colors.white : Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCompleted ? 'Target Tercapai!' : '${(percentage * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isCompleted ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 4)] : [],
            ),
          ),
        ],
      ),
    );
  }

  // ─── NUTRISI GRID ─────────────────────────────────────────────────────────
  Widget _buildNutriGrid(double consumedProtein, double consumedCarbs, double consumedFat,double consumedWater, [Map<String, double>? macros]) {
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
          crossAxisCount: 2, // 🔥 2x2
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1, // biar proporsional
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMiniBattery(item),
          const SizedBox(height: 10),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
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

  Widget _buildMiniBattery(NutrisiItem item) {
    final bool isCompleted = item.percentage >= 1.0;
    final double displayPct = item.percentage > 1.0 ? 1.0 : item.percentage;

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
                color: item.borderColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
                boxShadow: isCompleted ? [BoxShadow(color: item.borderColor.withOpacity(0.3), blurRadius: 2)] : [],
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
                border: Border.all(color: item.borderColor, width: 2.5),
                boxShadow: isCompleted ? [BoxShadow(color: item.borderColor.withOpacity(0.2), blurRadius: 4, spreadRadius: 1)] : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isCompleted ? 6 : 8),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    FractionallySizedBox(
                      heightFactor: displayPct,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: item.fillColor,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Center(
                        child: Icon(Icons.check, color: item.iconColor, size: 24),
                      )
                    else
                      Center(
                        child: Icon(item.icon, color: item.iconColor, size: 20),
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
                  color: const Color(0xFFE8F5E9),
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
    final endIndex = (startIndex + _riwayatItemsPerPage).clamp(0, sortedHistory.length);
    final pageItems = sortedHistory.isEmpty ? <LogModel>[] : sortedHistory.sublist(startIndex, endIndex);

    return Column(
      children: [
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('${sortedHistory.length} entri', style: const TextStyle(fontSize: 11, color: Color(0xFF5A7A5A))),
                const Spacer(),
                Text('Hal. ${safeCurrentPage + 1}/$totalPages', style: const TextStyle(fontSize: 11, color: Color(0xFF5A7A5A))),
              ],
            ),
          ),
        ...pageItems.map((item) => _buildFoodHistoryCard(item, isMonitor)).toList(),
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
          _riwayatPageBtn(Icons.chevron_left_rounded, current > 0, () => setState(() => _riwayatPage--)),
          const SizedBox(width: 8),
          ...List.generate(total, (i) {
            final isActive = i == current;
            return GestureDetector(
              onTap: () => setState(() => _riwayatPage = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2E7D32) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFD0E8D0)),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : const Color(0xFF5A7A5A),
                    ),
                  ),
                ),
              ),
            );
          }).take(7).toList(),
          const SizedBox(width: 8),
          _riwayatPageBtn(Icons.chevron_right_rounded, current < total - 1, () => setState(() => _riwayatPage++)),
        ],
      ),
    );
  }

  Widget _riwayatPageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? const Color(0xFFD0E8D0) : Colors.transparent),
        ),
        child: Icon(icon, size: 16, color: enabled ? const Color(0xFF2E7D32) : const Color(0xFF5A7A5A).withOpacity(0.3)),
      ),
    );
  }

  // ─── FOOD HISTORY CARD ────────────────────────────────────────────────────

  Widget _buildFoodHistoryCard(LogModel item, bool isMonitor) {
    final Color accentColor = _categoryColor(item.category);

    return GestureDetector(
      onTap: isMonitor ? null : () => _showFoodDetailModal(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: item.imageUrl != null
                    ? (item.imageUrl!.startsWith('http')
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildHistoryAvatar(item, accentColor),
                          )
                        : Image.file(
                            File(item.imageUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildHistoryAvatar(item, accentColor),
                          ))
                    : _buildHistoryAvatar(item, accentColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.quantity > 1 ? '${item.quantity} pcs ${item.foodName}' : item.foodName,
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
                    item.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5A7A5A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _nutriChip(
                        'P ${item.protein.round()}g',
                        const Color(0xFFFFEBEE),
                        const Color(0xFFE53935),
                      ),
                      const SizedBox(width: 4),
                      _nutriChip(
                        'K ${item.carbs.round()}g',
                        const Color(0xFFFFF8E1),
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      _nutriChip(
                        'L ${item.fat.round()}g',
                        const Color(0xFFFFF3E0),
                        const Color(0xFFFF8C00),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.calories.toInt()}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Text(
                  'kkal',
                  style: TextStyle(fontSize: 10, color: Color(0xFF5A7A5A)),
                ),
                const SizedBox(height: 4),
                Text(
                  "${item.consumedAt.hour.toString().padLeft(2, '0')}:${item.consumedAt.minute.toString().padLeft(2, '0')}",
                  //_controller.formatMealTime(item.consumedAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── MODAL DETAIL ─────────────────────────────────────────────────────────

  // ─── HELPER TO RECONSTRUCT FOOD MODEL ─────────────────────────────────────
  FoodModel _reconstructFood(LogModel log) {
    // Total weight consumed for this log entry
    final totalWeight = log.servingSize * (log.quantity > 0 ? log.quantity : 1);
    
    // Formula: per100 = (totalValue * 100) / totalWeight
    double getPer100(double total) => totalWeight > 0 ? (total * 100) / totalWeight : 0;

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
        builder: (_) => FoodDetailView(
          food: _reconstructFood(item),
          initialLog: item,
        ),
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

  Widget _pillBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHistoryAvatar(LogModel item, Color accentColor) {
    if (item.imageUrl != null && File(item.imageUrl!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(item.imageUrl!), fit: BoxFit.cover),
      );
    }
    return Center(
      child: Text(
        item.foodName[0].toUpperCase(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _macroCard(
    String label,
    double value,
    Color bg,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              '${value.toStringAsFixed(1)}g',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
          ],
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
