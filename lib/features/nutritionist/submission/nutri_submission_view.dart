import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/submission/submission_controller.dart';
import '../../general/submission/submission_model.dart';
import '../widgets/nutri_fill_sheet.dart';

class NutriSubmissionView extends StatefulWidget {
  const NutriSubmissionView({super.key});

  @override
  State<NutriSubmissionView> createState() => _NutriSubmissionViewState();
}

class _NutriSubmissionViewState extends State<NutriSubmissionView>
    with SingleTickerProviderStateMixin {
  // ── Tema hijau selaras ────────────────────────────────────────────────────
  static const _green = Color(0xFF2E7D32);
  static const _dark = Color(0xFF1A2E22);
  static const _muted = Color(0xFF7A9485);
  static const _bg = Color(0xFFF4FAF6);

  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ← Pakai SubmissionController GLOBAL (shared dengan admin & user)
    final ctrl = context.watch<SubmissionController>();
    final belumDiisi =
        ctrl.approvedNeedsFill
            .where((s) => s.foodName.toLowerCase().contains(_query))
            .toList();
    final sudahDiisi =
        ctrl.approvedFilled
            .where((s) => s.foodName.toLowerCase().contains(_query))
            .toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Pengajuan Saya',
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
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: _green,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${ctrl.approved.length} total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _green.withValues(alpha: 0.2)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari nama makanan...',
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
                                  setState(() => _query = '');
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
                labelColor: _green,
                unselectedLabelColor: _muted,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: _green,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pending_actions_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('Perlu Diisi (${belumDiisi.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('Selesai (${sudahDiisi.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildList(belumDiisi, needsFill: true),
          _buildList(sudahDiisi, needsFill: false),
        ],
      ),
    );
  }

  Widget _buildList(List<SubmissionModel> items, {required bool needsFill}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                needsFill
                    ? Icons.pending_actions_rounded
                    : Icons.task_alt_rounded,
                size: 48,
                color: _green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              needsFill ? 'Semua sudah diisi! 🎉' : 'Belum ada yang selesai',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _dark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              needsFill
                  ? 'Tidak ada pengajuan yang perlu dilengkapi'
                  : 'Data nutrisi yang sudah diisi muncul di sini',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      itemBuilder:
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NutriListCard(item: items[i], needsFill: needsFill),
          ),
    );
  }
}

// ─── Card di list ─────────────────────────────────────────────────────────────

class _NutriListCard extends StatelessWidget {
  final SubmissionModel item;
  final bool needsFill;

  const _NutriListCard({required this.item, required this.needsFill});

  static const _green = Color(0xFF2E7D32);
  static const _dark = Color(0xFF1A2E22);
  static const _muted = Color(0xFF7A9485);

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m lalu';
    if (d.inHours < 24) return '${d.inHours}j lalu';
    return '${d.inDays}h lalu';
  }

  @override
  Widget build(BuildContext context) {
    final accent = needsFill ? const Color(0xFFFF8F00) : _green;

    return GestureDetector(
      onTap:
          () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => NutriFillSheet(item: item),
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
                    needsFill ? 'Isi Data' : 'Selesai',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),

            if (!needsFill && item.calories != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE8F5E9)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _macro('Kalori', '${item.calories!.toInt()} kkal', _green),
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
            ],

            if (needsFill) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, color: _green, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Ketuk untuk mengisi data nutrisi',
                      style: TextStyle(
                        fontSize: 12,
                        color: _green,
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
