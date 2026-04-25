import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard/dashboard_view.dart';
import 'profile/profile_view.dart';
import 'scan/scan_view.dart';
import 'scan/scan_controller.dart';
import 'screen/submission/submission_screen.dart';
import 'auth/auth_controller.dart';

class UserMainView extends StatefulWidget {
  const UserMainView({super.key});

  @override
  State<UserMainView> createState() => _UserMainViewState();
}

class _UserMainViewState extends State<UserMainView> {
  int _currentIndex = 0;

  static const _green = Color(0xFF2E7D32);

  final List<Widget> _pages = const [
    DashboardBody(), // 0 – Home
    _PlaceholderRiwayat(), // 1 – Riwayat
    SubmissionScreen(), // 2 – Pengajuan
    ProfileView(), // 3 – Profile
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
  Widget build(BuildContext context) {
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
        ),
      ),
    );
  }

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
          ),
        ),
      ),
    );
  }
}
