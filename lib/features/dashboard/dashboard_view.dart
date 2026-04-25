import 'package:flutter/material.dart';
import 'dashboard_controller.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardController _controller = DashboardController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildDaySelector(),
              _buildKaloriCard(),
              const SizedBox(height: 8),
              _buildNutriGrid(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
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
          GestureDetector(
            onTap: _controller.onSettingsTapped,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 20),
            ),
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
                color: isActive
                    ? const Color(0xFF4CAF50)
                    : Colors.transparent,
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
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF5A7A5A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.number}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF1B2A1B),
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
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5A7A5A),
              ),
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
                          const Icon(Icons.local_fire_department,
                              color: Colors.white, size: 18),
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

  Widget _buildNutriGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: _controller.nutrisiItems.map((item) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: item == _controller.nutrisiItems.last ? 0 : 10,
              ),
              child: _buildNutriCard(item),
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
          // Terminal atas
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
          // Body baterai
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
                    // Fill level
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
                    // Icon
                    Center(
                      child: Icon(
                        item.icon,
                        color: item.iconColor,
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

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: const Color(0xFF2E7D32),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.history, 'Riwayat', 1),
            const SizedBox(width: 48), // space for FAB
            _buildNavItem(Icons.assignment, 'Pengajuan', 2),
            _buildNavItem(Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _controller.selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _controller.selectNav(index)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : Colors.white54,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _controller.onAddTapped,
      backgroundColor: const Color(0xFF1B2A1B),
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.white, size: 26),
    );
  }
}