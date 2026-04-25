import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import 'dashboard_controller.dart';

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
              _buildNutriGrid(macros),
              const SizedBox(height: 24),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              if (nama != null)
                Text(
                  'Halo, $nama 👋',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A7A5A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings, color: Colors.white, size: 20),
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
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: percentage,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFA5D6A7),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  // ─── NUTRISI GRID ─────────────────────────────────────────────────────────
  Widget _buildNutriGrid(Map<String, double>? macros) {
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
}

// ─── BACKWARD COMPAT: alias lama masih bisa compile ─────────────────────────
typedef DashboardView = DashboardBody;
