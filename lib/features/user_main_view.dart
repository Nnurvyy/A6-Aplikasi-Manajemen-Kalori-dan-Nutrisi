import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard/dashboard_view.dart';
import 'profile/profile_view.dart';
import 'scan/scan_view.dart';
import 'scan/scan_controller.dart';
import 'food/food_list_view.dart';
import 'screen/submission/submission_screen.dart';
import 'auth/auth_controller.dart';

class UserMainView extends StatefulWidget {
  const UserMainView({super.key});

  @override
  State<UserMainView> createState() => _UserMainViewState();
}

class _UserMainViewState extends State<UserMainView>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

<<<<<<< HEAD
  bool _isFabOpen = false;
  late AnimationController _fabAnimController;
  late Animation<double> _fabRotateAnim;
  late Animation<double> _fabScaleAnim;

  final List<Widget> _pages = const [
    DashboardView(),
    _PlaceholderView(label: 'Riwayat'),
    _PlaceholderView(label: 'Pengajuan'),
    _PlaceholderView(label: 'Profile'),
=======
  static const _green = Color(0xFF2E7D32);

  final List<Widget> _pages = const [
    DashboardBody(), // 0 – Home
    _PlaceholderRiwayat(), // 1 – Riwayat
    SubmissionScreen(), // 2 – Pengajuan
    ProfileView(), // 3 – Profile
>>>>>>> 19056787287e5d0a854be200e215defecca53f6d
  ];

  void _onFABTap() {
    // Navigasi ke ScanFoodView atau pilih makanan manual
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create: (_) => ScanController(),
              child: const ScanFoodView(),
            ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _fabRotateAnim = Tween<double>(begin: 0, end: 0.375).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );

    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      _isFabOpen
          ? _fabAnimController.forward()
          : _fabAnimController.reverse();
    });
  }

  void _closeFab() {
    if (_isFabOpen) {
      setState(() {
        _isFabOpen = false;
        _fabAnimController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScanController()),
      ],
      child: GestureDetector(
        onTap: _closeFab,
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F6F0),

          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          floatingActionButton: _buildSpeedDialFAB(),

          // 🔥 CENTER DOCKED (NOTCH MODE)
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,

          bottomNavigationBar: _buildBottomNavBar(),
=======
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFABTap,
        backgroundColor: const Color(0xFF1B2A1B),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: _green,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Home', 0),
              _navItem(Icons.history_rounded, 'Riwayat', 1),
              const SizedBox(width: 48), // ruang FAB
              _navItem(Icons.assignment_rounded, 'Pengajuan', 2),
              _navItem(Icons.person_rounded, 'Profile', 3),
            ],
          ),
>>>>>>> 19056787287e5d0a854be200e215defecca53f6d
        ),
      ),
    );
  }

<<<<<<< HEAD
  // ─── FAB ─────────────────────────────────────────────

  Widget _buildSpeedDialFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Database
        ScaleTransition(
          scale: _fabScaleAnim,
          child: _miniFabButton(
            label: 'Database',
            icon: Icons.storage_rounded,
            color: const Color(0xFF388E3C),
            onTap: () {
              _closeFab();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FoodListView()),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Scan
        ScaleTransition(
          scale: _fabScaleAnim,
          child: _miniFabButton(
            label: 'Scan',
            icon: Icons.qr_code_scanner_rounded,
            color: const Color(0xFF1565C0),
            onTap: () {
              _closeFab();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanFoodView()),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // MAIN FAB
        FloatingActionButton(
          onPressed: _toggleFab,
          backgroundColor: const Color(0xFF1B2A1B),
          elevation: 6,
          shape: const CircleBorder(),
          child: AnimatedBuilder(
            animation: _fabRotateAnim,
            builder: (_, child) => Transform.rotate(
              angle: _fabRotateAnim.value * 2 * 3.14159,
              child: child,
            ),
            child: Icon(
              _isFabOpen ? Icons.close : Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniFabButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ─── NAVBAR ──────────────────────────────────────────

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
            _buildNavItem(Icons.home_rounded, 'Home', 0),
            _buildNavItem(Icons.history_rounded, 'Riwayat', 1),
            const SizedBox(width: 56),
            _buildNavItem(Icons.assignment_rounded, 'Pengajuan', 2),
            _buildNavItem(Icons.person_rounded, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        _closeFab();
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isActive ? Colors.white : Colors.white54,
              size: 22),
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
}

// ─── PLACEHOLDER ─────────────────────────────────────

class _PlaceholderView extends StatelessWidget {
  final String label;
  const _PlaceholderView({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      body: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4CAF50),
=======
  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 22),
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
}

// ─── Placeholder Riwayat ────────────────────────────────────────────────────
class _PlaceholderRiwayat extends StatelessWidget {
  const _PlaceholderRiwayat();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6F0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 64, color: Color(0xFF4CAF50)),
              SizedBox(height: 16),
              Text(
                'Riwayat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2A1B),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Fitur ini akan segera hadir',
                style: TextStyle(color: Colors.grey),
              ),
            ],
>>>>>>> 19056787287e5d0a854be200e215defecca53f6d
          ),
        ),
      ),
    );
  }
}