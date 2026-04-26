import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import 'dashboard_controller.dart';
import '../auth/login_view.dart';
import '../food/models/log_model.dart';
import '../../services/hive_service.dart';
import '../food/food_controller.dart';

/// Widget murni isi dashboard — TANPA Scaffold/BottomNav sendiri.
/// Dibungkus oleh UserMainView yang sudah punya satu BottomAppBar.
class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  final DashboardController _controller = DashboardController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    // Tidak ada bottomNavigationBar / floatingActionButton di sini.
    // Keduanya dikelola oleh UserMainView (shell).
    final user = context.watch<AuthController>().currentUser;
    final kaloriTarget = user?.dailyCalorieNeed ?? 2000;
    final macros = user?.macroTargets;

    // Update controller target dari data user
    _controller.kaloriTarget = kaloriTarget;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user?.name),
              _buildDaySelector(),
              _buildKaloriCard(),
              const SizedBox(height: 8),
              _buildNutriGrid(),
              const SizedBox(height: 8),
              _buildRiwayatHeader(),
              _buildRiwayatList(),
              const SizedBox(height: 100), // ruang agar tidak ketutup navbar
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader(String? nama) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'NutriTrack',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B2A1B),
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _controller.onSettingsTapped,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  final auth = context.read<AuthController>();
                  await auth.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                    (route) => false,
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── DAY SELECTOR ─────────────────────────────────────────────────────────
  Widget _buildDaySelector() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _controller.days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final day = _controller.days[index];
          final isActive = index == _controller.selectedDayIndex;
          return GestureDetector(
            onTap: () => setState(() => _controller.selectDay(index)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF4CAF50) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
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
                      color: isActive ? Colors.white : const Color(0xFF1B2A1B),
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
                color: Color(0xFF1B2A1B),
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FractionallySizedBox(
                        widthFactor: percentage,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(percentage * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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
            width: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFA5D6A7),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  // ─── NUTRISI GRID ─────────────────────────────────────────────────────────
  Widget _buildNutriGrid([Map<String, double>? macros]) {
    // Gunakan target dari user jika ada, fallback ke controller default
    final items =
        macros != null
            ? _controller.nutrisiItemsWithTargets(
              protein: macros['protein'] ?? 80,
              carbs: macros['carbs'] ?? 250,
              fat: macros['fat'] ?? 65,
            )
            : _controller.nutrisiItems;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children:
            items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 10),
                  child: _buildNutriCard(e.value),
                ),
              );
            }).toList(),
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
              color: Color(0xFF1B2A1B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${item.consumed.toStringAsFixed(1)}g / ${item.target.toStringAsFixed(0)}g',
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
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    FractionallySizedBox(
                      heightFactor: item.percentage,
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
              color: const Color(0xFF4CAF50),
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

  Widget _buildRiwayatList() {
    final foodController = context.watch<FoodController>();

    final history = foodController.getAllLogs;

    history.sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

    if (history.isEmpty) {
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
                  color: Color(0xFF1B2A1B),
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
      child: Column(
        children: history.map((item) => _buildFoodHistoryCard(item)).toList(),
      ),
    );
  }

  // ─── FOOD HISTORY CARD ────────────────────────────────────────────────────

  Widget _buildFoodHistoryCard(LogModel item) {
    final Color accentColor = _categoryColor(item.category);

    return GestureDetector(
      onTap: () => _showFoodDetailModal(item),
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
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  item.foodName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B2A1B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.category} • ${item.mealType}',
                    //'${item.category} • ${item.mealTime}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5A7A5A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _nutriChip(
                        'P ${item.protein.toStringAsFixed(1)}g',
                        const Color(0xFFFFEBEE),
                        const Color(0xFFE53935),
                      ),
                      const SizedBox(width: 4),
                      _nutriChip(
                        'K ${item.carbs.toStringAsFixed(1)}g',
                        const Color(0xFFFFF8E1),
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      _nutriChip(
                        'L ${item.fat.toStringAsFixed(1)}g',
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
                    color: Color(0xFF4CAF50),
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

  void _showFoodDetailModal(LogModel item) {
    final Color accentColor = _categoryColor(item.mealType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            expand: false,
            builder:
                (_, scrollCtrl) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      item.foodName[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.foodName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1B2A1B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _pillBadge(
                                            item.category,
                                            accentColor,
                                          ),
                                          const SizedBox(width: 6),
                                          _pillBadge(
                                            item.mealType,
                                            const Color(0xFF4CAF50),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF66BB6A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    children: [
                                      Text(
                                        '${item.calories.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        'kkal total',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.servingSize.toInt()} gram',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '(${item.calories.toInt()} kkal/100g)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _macroCard(
                                  'Protein',
                                  item.protein,
                                  const Color(0xFFFFEBEE),
                                  const Color(0xFFE53935),
                                  Icons.fitness_center,
                                ),
                                const SizedBox(width: 10),
                                _macroCard(
                                  'Karbo',
                                  item.carbs,
                                  const Color(0xFFFFF8E1),
                                  const Color(0xFFF59E0B),
                                  Icons.grain,
                                ),
                                const SizedBox(width: 10),
                                _macroCard(
                                  'Lemak',
                                  item.fat,
                                  const Color(0xFFFFF3E0),
                                  const Color(0xFFFF8C00),
                                  Icons.water_drop,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Color(0xFF5A7A5A),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dikonsumsi pukul ${_controller.formatMealTime(item.consumedAt)} • ${item.mealType}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5A7A5A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                // TODO: hapus dari riwayat
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFEF9A9A),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFE53935),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hapus dari Riwayat',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFE53935),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
