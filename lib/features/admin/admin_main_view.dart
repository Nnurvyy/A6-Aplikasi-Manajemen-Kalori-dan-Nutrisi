import 'package:flutter/material.dart';
import 'package:nutritrack_app/features/admin/UserManagement/admin_user_management_view.dart';
import 'package:provider/provider.dart';
import '../general/auth/auth_controller.dart';
import '../general/auth/models/user_model.dart';
import 'dashboard/admin_dashboard_view.dart';
import 'food/admin_food_list_view.dart';
import 'submission/admin_submission_view.dart';
import '../general/auth/login_view.dart';

class AdminMainView extends StatefulWidget {
  const AdminMainView({super.key});

  @override
  State<AdminMainView> createState() => _AdminMainViewState();
}

class _AdminMainViewState extends State<AdminMainView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardView(),
    const AdminFoodListView(),
    const AdminSubmissionView(),
    const AdminUserManagementView(),
    const _AdminProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final user = authCtrl.currentUser;

    if (user == null) {
      return const LoginView();
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF4CAF50),
            unselectedItemColor: const Color(0xFFB0BEC5),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fastfood_rounded),
                label: 'Database',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_rounded),
                label: 'Pengajuan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                label: 'Pengguna',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Admin Profile View ─────────────────────────────────────────────────────
class _AdminProfileView extends StatelessWidget {
  const _AdminProfileView();

  static const Color _primary = Color(0xFF4CAF50);
  static const Color _dark = Color(0xFF1B2A1B);
  static const Color _muted = Color(0xFF5A7A5A);
  static const Color _bg = Color(0xFFF4F6F0);

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final UserModel? user = authCtrl.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ─── Header ───
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF4CAF50),
                      Color(0xFF66BB6A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.name ?? 'Admin',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  _buildCard(
                    child: Column(
                      children: [
                        _infoRow(
                          Icons.email_rounded,
                          'Email',
                          user?.email ?? '-',
                        ),
                        const Divider(height: 24),
                        _infoRow(Icons.badge_rounded, 'Role', 'Administrator'),
                        const Divider(height: 24),
                        _infoRow(
                          Icons.verified_user_rounded,
                          'Status',
                          'Aktif',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Admin Stats
                  const Text(
                    'PANEL ADMIN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildCard(
                    child: Column(
                      children: [
                        _menuRow(
                          icon: Icons.fastfood_rounded,
                          label: 'Kelola Database Makanan',
                          color: _primary,
                          subtitle: 'Tambah, edit, dan hapus makanan',
                        ),
                        const Divider(height: 24),
                        _menuRow(
                          icon: Icons.assignment_rounded,
                          label: 'Kelola Pengajuan',
                          color: Colors.orange,
                          subtitle: 'Review pengajuan dari pengguna',
                        ),
                        const Divider(height: 24),
                        _menuRow(
                          icon: Icons.dashboard_rounded,
                          label: 'Dashboard Statistik',
                          color: Colors.blue,
                          subtitle: 'Monitor aktivitas pengguna',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  GestureDetector(
                    onTap: () => _confirmLogout(context, authCtrl),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFCDD2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFE53935),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: _dark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required Color color,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: _dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: _muted, size: 18),
      ],
    );
  }

  void _confirmLogout(BuildContext context, AuthController authCtrl) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.logout_rounded, color: Color(0xFFE53935)),
                SizedBox(width: 8),
                Text(
                  'Konfirmasi Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: const Text('Anda yakin ingin keluar dari akun admin?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Color(0xFF5A7A5A)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await authCtrl.logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Keluar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }
}
