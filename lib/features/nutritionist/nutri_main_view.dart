import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../general/auth/auth_controller.dart';
import '../general/auth/models/user_model.dart';
import '../general/auth/login_view.dart';
import '../general/submission/submission_controller.dart';
import 'dashboard/nutri_dashboard_view.dart';
import 'database/nutri_database_view.dart';
import 'submission/nutri_submission_view.dart';

class NutriMainView extends StatefulWidget {
  const NutriMainView({super.key});

  @override
  State<NutriMainView> createState() => _NutriMainViewState();
}

class _NutriMainViewState extends State<NutriMainView>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  static const _green = Color(0xFF2E7D32);

  static const _pages = [
    NutriDashboardView(),
    NutritionistFoodDatabaseView(),
    NutriSubmissionView(),
    _NutriProfileView(),
  ];

  static const _items = [
    _NutriNavData(
      Icons.dashboard_rounded,
      Icons.dashboard_outlined,
      'Dashboard',
    ),
    _NutriNavData(
      Icons.folder_rounded,
      Icons.folder_outlined,
      'Database',
    ),
    _NutriNavData(
      Icons.assignment_rounded,
      Icons.assignment_outlined,
      'Isi Nutrisi',
    ),
    _NutriNavData(Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
  ];

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) return const LoginView();

    final hasBadge =
        context.watch<SubmissionController>().approvedNeedsFill.isNotEmpty;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _NutriNavBar(
        currentIndex: _currentIndex,
        items: _items,
        onTap: _onTap,
        badgeIndex: 2,
        showBadge: hasBadge,
        color: _green,
      ),
    );
  }
}

class _NutriNavData {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NutriNavData(this.activeIcon, this.icon, this.label);
}

class _NutriNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NutriNavData> items;
  final void Function(int) onTap;
  final int badgeIndex;
  final bool showBadge;
  final Color color;

  const _NutriNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.badgeIndex,
    required this.showBadge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.15)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = currentIndex == i;
              final item = items[i];
              final hasBadge = i == badgeIndex && showBadge;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration:
                        active
                            ? BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            )
                            : const BoxDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder:
                                  (child, anim) => ScaleTransition(
                                    scale: anim,
                                    child: child,
                                  ),
                              child: Icon(
                                active ? item.activeIcon : item.icon,
                                key: ValueKey(active),
                                color: active ? Colors.white : Colors.white60,
                                size: active ? 24 : 22,
                              ),
                            ),
                            if (hasBadge)
                              Positioned(
                                right: -5,
                                top: -3,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB300),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: color,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? Colors.white : Colors.white60,
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Ahli Gizi ───────────────────────────────────────────────────────
class _NutriProfileView extends StatelessWidget {
  const _NutriProfileView();

  static const _teal = Color(0xFF2E7D32);
  static const _dark = Color(0xFF1A2E22);
  static const _muted = Color(0xFF7A9485);
  static const _bg = Color(0xFFF4FAF6);

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final UserModel? user = authCtrl.currentUser;
    final ctrl = context.watch<SubmissionController>();

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: _teal,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF388E3C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.name ?? 'Ahli Gizi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ahli Gizi · NutriTrack',
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
                  // Info akun
                  _card(
                    child: Column(
                      children: [
                        _infoRow(
                          Icons.email_rounded,
                          'Email',
                          user?.email ?? '-',
                        ),
                        const Divider(height: 24),
                        _infoRow(Icons.badge_rounded, 'Role', 'Ahli Gizi'),
                        const Divider(height: 24),
                        _infoRow(Icons.verified_rounded, 'Status', 'Aktif'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'STATISTIK KONTRIBUSI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Statistik dari Hive (real data)
                  _card(
                    child: Column(
                      children: [
                        _menuRow(
                          Icons.pending_actions_rounded,
                          'Perlu Diisi',
                          '${ctrl.approvedNeedsFill.length} pengajuan menunggu data nutrisi',
                          const Color(0xFFFFB300),
                        ),
                        const Divider(height: 24),
                        _menuRow(
                          Icons.check_circle_rounded,
                          'Sudah Dilengkapi',
                          '${ctrl.approvedFilled.length} data nutrisi sudah lengkap',
                          _teal,
                        ),
                        const Divider(height: 24),
                        _menuRow(
                          Icons.bar_chart_rounded,
                          'Total Ditangani',
                          '${ctrl.approved.length} pengajuan dari admin',
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout
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

  Widget _card({required Widget child}) => Container(
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

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _teal, size: 18),
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

  Widget _menuRow(IconData icon, String label, String subtitle, Color color) =>
      Row(
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
        ],
      );

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
            content: const Text('Anda yakin ingin keluar dari akun ahli gizi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Color(0xFF7A9485)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await authCtrl.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                      (_) => false,
                    );
                  }
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
