import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'dashboard/dashboard_view.dart';
import 'profile/profile_view.dart';
import 'scan/scan_view.dart';
import 'scan/scan_controller.dart';
import 'screen/submission/submission_screen.dart';
import 'screen/food_database_screen.dart';
import 'screen/PilihMakananManual.dart';
import 'auth/auth_controller.dart';
import 'food/watchlist_controller.dart';
import 'food/models/watchlist_model.dart';
import 'food/watchlist_view.dart';
import 'food/food_detail_view.dart';

// ═══════════════════════════════════════════════════════════════════════════
// USER MAIN VIEW
// ═══════════════════════════════════════════════════════════════════════════

class UserMainView extends StatefulWidget {
  const UserMainView({super.key});

  @override
  State<UserMainView> createState() => _UserMainViewState();
}

class _UserMainViewState extends State<UserMainView>
    with TickerProviderStateMixin {
  // ── Navigasi ─────────────────────────────────────────────────────────────
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.history_rounded, label: 'Riwayat'),
    _NavItem(icon: Icons.assignment_rounded, label: 'Pengajuan'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  // Pages — gunakan const agar IndexedStack tidak rebuild
  static const List<Widget> _pages = [
    DashboardView(),
    _RiwayatPlaceholder(),
    SubmissionScreen(),
    ProfileView(),
  ];

  // ── Speed Dial ───────────────────────────────────────────────────────────
  bool _dialOpen = false;

  late final AnimationController _mainCtrl; // FAB rotate + backdrop
  late final AnimationController _item0Ctrl; // Scan
  late final AnimationController _item1Ctrl; // Tersimpan
  late final AnimationController _item2Ctrl; // Database
  late final AnimationController _item3Ctrl; // Manual

  late final Animation<double> _rotateAnim;
  late final Animation<double> _backdropAnim;

  // ── Speed Dial item definitions ──────────────────────────────────────────
  static const List<_DialItemData> _dialItems = [
    _DialItemData(
      icon: Icons.document_scanner_rounded,
      label: 'Scan Makanan',
      sublabel: 'Deteksi otomatis dengan AI',
      startColor: Color(0xFF00C897),
      endColor: Color(0xFF009B76),
      tag: 'scan',
    ),
    _DialItemData(
      icon: Icons.bookmark_rounded,
      label: 'Makanan Tersimpan',
      sublabel: 'Riwayat & favorit kamu',
      startColor: Color(0xFF7C4DFF),
      endColor: Color(0xFF5C35CC),
      tag: 'saved',
    ),
    _DialItemData(
      icon: Icons.menu_book_rounded,
      label: 'Database Makanan',
      sublabel: 'Cari makanan di database',
      startColor: Color(0xFFFF6B6B),
      endColor: Color(0xFFCC4444),
      tag: 'db',
    ),
    _DialItemData(
      icon: Icons.create_rounded,
      label: 'Tambah Log Manual',
      sublabel: 'Buat catatan makanan sendiri',
      startColor: Color(0xFFFF9800),
      endColor: Color(0xFFF57C00),
      tag: 'manual',
    ),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthController>().currentUser?.id;
      if (userId != null) {
        context.read<WatchlistController>().loadWatchlist(userId);
      }
    });

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _item0Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _item1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _item2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _item3Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _rotateAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.easeInOutCubic));
    _backdropAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _item0Ctrl.dispose();
    _item1Ctrl.dispose();
    _item2Ctrl.dispose();
    _item3Ctrl.dispose();
    super.dispose();
  }

  List<AnimationController> get _itemCtrls => [
    _item0Ctrl,
    _item1Ctrl,
    _item2Ctrl,
    _item3Ctrl,
  ];

  void _openDial() {
    setState(() => _dialOpen = true);
    HapticFeedback.mediumImpact();
    _mainCtrl.forward();
    // Stagger: item teratas muncul terakhir (paling dekat FAB = index 2)
    for (int i = 0; i < _itemCtrls.length; i++) {
      final delay = i * 65;
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _itemCtrls[i].forward();
      });
    }
  }

  void _closeDial() async {
    HapticFeedback.lightImpact();
    _mainCtrl.reverse();
    for (final c in _itemCtrls.reversed) {
      c.reverse();
    }
    await Future.delayed(const Duration(milliseconds: 380));
    if (mounted) setState(() => _dialOpen = false);
  }

  void _toggleDial() {
    if (_dialOpen) {
      _closeDial();
    } else {
      _openDial();
    }
  }

  void _onDialItemTap(String tag) async {
    _closeDial();
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    switch (tag) {
      case 'scan':
        Navigator.of(context).push(
          _upRoute(
            ChangeNotifierProvider(
              create: (_) => ScanController(),
              child: const ScanFoodView(),
            ),
          ),
        );
        break;
      case 'saved':
        Navigator.of(context).push(_upRoute(const WatchlistView()));
        break;
      case 'db':
        Navigator.of(context).push(_upRoute(const FoodDatabaseScreen()));
        break;
      case 'manual':
        Navigator.of(context).push(_upRoute(const PilihMakananManual()));
        break;
    }
  }

  PageRoute<T> _upRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder:
          (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
      transitionDuration: const Duration(milliseconds: 420),
    );
  }


  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      body: Stack(
        children: [
          // ── Halaman aktif ──────────────────────────────────────────────
          IndexedStack(index: _currentIndex, children: _pages),

          // ── Backdrop gelap ─────────────────────────────────────────────
          if (_dialOpen)
            AnimatedBuilder(
              animation: _backdropAnim,
              builder:
                  (_, __) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeDial,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(
                          0.6 * _backdropAnim.value,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
            ),

          // ── Speed Dial Cards ───────────────────────────────────────────
          if (_dialOpen)
            Positioned(
              left: 16,
              right: 16,
              bottom: 82, // di atas BottomAppBar
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialCard(
                    data: _dialItems[0],
                    ctrl: _item0Ctrl,
                    onTap: () => _onDialItemTap(_dialItems[0].tag),
                  ),
                  const SizedBox(height: 10),
                  _DialCard(
                    data: _dialItems[1],
                    ctrl: _item1Ctrl,
                    onTap: () => _onDialItemTap(_dialItems[1].tag),
                  ),
                  const SizedBox(height: 10),
                  _DialCard(
                    data: _dialItems[2],
                    ctrl: _item2Ctrl,
                    onTap: () => _onDialItemTap(_dialItems[2].tag),
                  ),
                  const SizedBox(height: 10),
                  _DialCard(
                    data: _dialItems[3],
                    ctrl: _item3Ctrl,
                    onTap: () => _onDialItemTap(_dialItems[3].tag),
                  ),
                ],
              ),
            ),
        ],
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: AnimatedBuilder(
        animation: _rotateAnim,
        builder: (_, __) {
          return GestureDetector(
            onTap: _toggleDial,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      _dialOpen
                          ? [const Color(0xFF455A64), const Color(0xFF263238)]
                          : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_dialOpen ? Colors.black : const Color(0xFF2E7D32))
                        .withOpacity(0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: _rotateAnim.value * math.pi * 0.75,
                child: Icon(
                  _dialOpen ? Icons.close_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom Nav ───────────────────────────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF2E7D32),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _buildNavBtn(0),
                _buildNavBtn(1),
                const SizedBox(width: 64), // notch space
                _buildNavBtn(2),
                _buildNavBtn(3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBtn(int index) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_dialOpen) _closeDial();
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  item.icon,
                  key: ValueKey(isActive),
                  color: isActive ? Colors.white : Colors.white54,
                  size: isActive ? 24 : 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS (internal)
// ═══════════════════════════════════════════════════════════════════════════

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _DialItemData {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color startColor;
  final Color endColor;
  final String tag;
  const _DialItemData({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.startColor,
    required this.endColor,
    required this.tag,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// SPEED DIAL CARD
// ═══════════════════════════════════════════════════════════════════════════

class _DialCard extends StatefulWidget {
  final _DialItemData data;
  final AnimationController ctrl;
  final VoidCallback onTap;
  const _DialCard({
    required this.data,
    required this.ctrl,
    required this.onTap,
  });

  @override
  State<_DialCard> createState() => _DialCardState();
}

class _DialCardState extends State<_DialCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return AnimatedBuilder(
      animation: widget.ctrl,
      builder: (_, __) {
        final t =
            CurvedAnimation(
              parent: widget.ctrl,
              curve: Curves.easeOutBack,
            ).value;

        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - t)),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) {
                setState(() => _pressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.96 : 1.0,
                duration: const Duration(milliseconds: 80),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: data.startColor.withOpacity(0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // ── Ikon gradient ──────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [data.startColor, data.endColor],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: data.startColor.withOpacity(0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(data.icon, color: Colors.white, size: 26),
                        ),
                      ),

                      // ── Teks ──────────────────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A2E1A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              data.sublabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7A9485),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Arrow ─────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: data.startColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: data.startColor,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SAVED FOOD SHEET (placeholder cantik)
// ═══════════════════════════════════════════════════════════════════════════

class _SavedFoodSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistController>();
    final items = watchlist.items;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Makanan Tersimpan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E22),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _buildEmptyState()
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                itemBuilder:
                    (context, index) => _buildSavedItem(context, items[index]),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSavedItem(BuildContext context, WatchlistModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F1EC)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF7C4DFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.bookmark_rounded,
            color: Color(0xFF7C4DFF),
            size: 20,
          ),
        ),
        title: Text(
          item.food.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${item.food.category} • ${item.food.calories.toStringAsFixed(0)} kkal',
          style: const TextStyle(fontSize: 12, color: Color(0xFF7A9485)),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FoodDetailView(food: item.food)),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 48,
            color: Colors.grey.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada makanan tersimpan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Simpan makanan favoritmu untuk akses cepat di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RIWAYAT PLACEHOLDER
// ═══════════════════════════════════════════════════════════════════════════

class _RiwayatPlaceholder extends StatelessWidget {
  const _RiwayatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 40,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Riwayat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2A1B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Fitur ini akan segera hadir',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
