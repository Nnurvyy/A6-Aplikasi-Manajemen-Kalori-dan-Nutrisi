import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/submission/submission_model.dart';
import '../../general/submission/submission_controller.dart';
import '../widgets/nutri_fill_sheet.dart';

/// Halaman "Isi Nutrisi" dengan dua tab (Perlu Diisi / Selesai) + pagination
class NutriSubmissionView extends StatefulWidget {
  const NutriSubmissionView({super.key});

  @override
  State<NutriSubmissionView> createState() => _NutriSubmissionViewState();
}

class _NutriSubmissionViewState extends State<NutriSubmissionView>
    with SingleTickerProviderStateMixin {
  static const _teal = Color(0xFF00897B);
  static const _dark = Color(0xFF1A2E2C);
  static const _muted = Color(0xFF5A7A78);
  static const _bg = Color(0xFFF0FAF9);
  static const _pageSize = 5;

  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Pagination state per tab
  int _pagePending = 1;
  int _pageDone = 1;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.toLowerCase();
        _pagePending = 1;
        _pageDone = 1;
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SubmissionController>();

    final allPending =
        ctrl.approvedNeedsFill
            .where(
              (s) =>
                  s.foodName.toLowerCase().contains(_query) ||
                  s.userName.toLowerCase().contains(_query),
            )
            .toList();
    final allDone =
        ctrl.approvedFilled
            .where(
              (s) =>
                  s.foodName.toLowerCase().contains(_query) ||
                  s.userName.toLowerCase().contains(_query),
            )
            .toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Data Nutrisi Pengajuan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: _teal,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${ctrl.approved.length} total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Info bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 14,
                      color: _teal,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Hanya menampilkan pengajuan yang sudah di-ACC admin',
                        style: TextStyle(
                          fontSize: 11,
                          color: _teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _teal.withValues(alpha: 0.2)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari makanan atau pengaju...',
                      hintStyle: const TextStyle(fontSize: 13, color: _muted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _muted,
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      suffixIcon:
                          _query.isNotEmpty
                              ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: _muted,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {
                                    _query = '';
                                    _pagePending = 1;
                                    _pageDone = 1;
                                  });
                                },
                              )
                              : null,
                    ),
                  ),
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabCtrl,
                labelColor: _teal,
                unselectedLabelColor: _muted,
                indicatorColor: _teal,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: _tabChip(
                      'Perlu Diisi',
                      allPending.length,
                      const Color(0xFFFF8F00),
                    ),
                  ),
                  Tab(child: _tabChip('Selesai', allDone.length, _teal)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _PaginatedList(
            key: ValueKey('pending_${_query}_$_pagePending'),
            items: allPending,
            needsFill: true,
            page: _pagePending,
            pageSize: _pageSize,
            onPageChanged: (p) => setState(() => _pagePending = p),
          ),
          _PaginatedList(
            key: ValueKey('done_${_query}_$_pageDone'),
            items: allDone,
            needsFill: false,
            page: _pageDone,
            pageSize: _pageSize,
            onPageChanged: (p) => setState(() => _pageDone = p),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int count, Color color) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(label),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        decoration: BoxDecoration(
          color:
              count > 0
                  ? color.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: count > 0 ? color : _muted,
          ),
        ),
      ),
    ],
  );
}

// ─── Paginated List Widget ────────────────────────────────────────────────────
class _PaginatedList extends StatelessWidget {
  final List<SubmissionModel> items;
  final bool needsFill;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  static const _teal = Color(0xFF00897B);
  static const _dark = Color(0xFF1A2E2C);
  static const _muted = Color(0xFF5A7A78);

  const _PaginatedList({
    super.key,
    required this.items,
    required this.needsFill,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                needsFill
                    ? Icons.pending_actions_rounded
                    : Icons.task_alt_rounded,
                size: 48,
                color: _teal,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              needsFill ? 'Semua sudah terisi! 🎉' : 'Belum ada yang selesai',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _dark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              needsFill
                  ? 'Tidak ada yang perlu dilengkapi saat ini'
                  : 'Data nutrisi yang diisi akan muncul di sini',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ],
        ),
      );
    }

    final totalPages = (items.length / pageSize).ceil();
    final safePage = page.clamp(1, totalPages);
    final start = (safePage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, items.length);
    final pageItems = items.sublist(start, end);

    return Column(
      children: [
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: pageItems.length,
            itemBuilder:
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NutriCard(item: pageItems[i], needsFill: needsFill),
                ),
          ),
        ),

        // ── Pagination bar ──────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Info
              Expanded(
                child: Text(
                  'Hal. $safePage dari $totalPages  (${items.length} item)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Prev
              _PageBtn(
                icon: Icons.chevron_left_rounded,
                enabled: safePage > 1,
                onTap: () => onPageChanged(safePage - 1),
              ),
              const SizedBox(width: 4),
              // Page numbers
              ..._buildPageNumbers(safePage, totalPages),
              const SizedBox(width: 4),
              // Next
              _PageBtn(
                icon: Icons.chevron_right_rounded,
                enabled: safePage < totalPages,
                onTap: () => onPageChanged(safePage + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(int current, int total) {
    // Tampilkan maks 5 nomor halaman
    final List<int> pages = [];
    if (total <= 5) {
      pages.addAll(List.generate(total, (i) => i + 1));
    } else {
      if (current <= 3) {
        pages.addAll([1, 2, 3, 4, 5]);
      } else if (current >= total - 2) {
        pages.addAll([total - 4, total - 3, total - 2, total - 1, total]);
      } else {
        pages.addAll([
          current - 2,
          current - 1,
          current,
          current + 1,
          current + 2,
        ]);
      }
    }

    return pages
        .map(
          (p) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () => onPageChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: p == current ? _teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: p == current ? _teal : const Color(0xFFD0E8E5),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p == current ? Colors.white : _muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  static const _teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color:
              enabled
                  ? _teal.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                enabled
                    ? const Color(0xFFD0E8E5)
                    : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, size: 18, color: enabled ? _teal : Colors.grey[400]),
      ),
    );
  }
}

// ─── Card per item ────────────────────────────────────────────────────────────
class _NutriCard extends StatelessWidget {
  final SubmissionModel item;
  final bool needsFill;

  const _NutriCard({required this.item, required this.needsFill});

  static const _teal = Color(0xFF00897B);
  static const _dark = Color(0xFF1A2E2C);
  static const _muted = Color(0xFF5A7A78);

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m lalu';
    if (d.inHours < 24) return '${d.inHours}j lalu';
    return '${d.inDays}h lalu';
  }

  @override
  Widget build(BuildContext context) {
    final accent = needsFill ? const Color(0xFFFF8F00) : _teal;

    return GestureDetector(
      onTap:
          () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder:
                (_) => ChangeNotifierProvider.value(
                  value: context.read<SubmissionController>(),
                  child: NutriFillSheet(item: item),
                ),
          ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      item.foodName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: accent,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'dari ${item.userName} · ${_timeAgo(item.createdAt)}',
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    needsFill ? 'Isi Data' : 'Edit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),

            if (item.isNutriFilled) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE8F5E9)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _macro('Kalori', '${item.calories!.toInt()} kkal', _teal),
                  _macro(
                    'Protein',
                    '${item.protein!.toStringAsFixed(1)}g',
                    const Color(0xFFE53935),
                  ),
                  _macro(
                    'Karbo',
                    '${item.carbs!.toStringAsFixed(1)}g',
                    const Color(0xFFF59E0B),
                  ),
                  _macro(
                    'Lemak',
                    '${item.fat!.toStringAsFixed(1)}g',
                    const Color(0xFF1E88E5),
                  ),
                ],
              ),
              if (item.nutriNote != null && item.nutriNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note_rounded, size: 12, color: _muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.nutriNote!,
                          style: const TextStyle(fontSize: 11, color: _muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            if (needsFill) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, color: _teal, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Ketuk untuk mengisi data nutrisi',
                      style: TextStyle(
                        fontSize: 12,
                        color: _teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _macro(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
    ],
  );
}
