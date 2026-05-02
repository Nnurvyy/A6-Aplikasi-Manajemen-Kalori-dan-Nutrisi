import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/submission/submission_model.dart';
import '../submission/nutri_submission_controller.dart';
import '../widgets/nutri_fill_sheet.dart';

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

  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
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
    final ctrl = context.watch<NutriSubmissionController>();

    final belumDiisi =
        ctrl.belumDiisi
            .where((s) => s.foodName.toLowerCase().contains(_query))
            .toList();

    final sudahDiisi =
        ctrl.sudahDiisi
            .where((s) => s.foodName.toLowerCase().contains(_query))
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
                  '${ctrl.all.length} total',
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
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // ── Info bar: dari admin ──────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
              // ── Search bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _teal.withValues(alpha: 0.2)),
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
              // ── Tab bar ────────────────────────────────────────────────
              TabBar(
                controller: _tabCtrl,
                labelColor: _teal,
                unselectedLabelColor: _muted,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: _teal,
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
            const SizedBox(height: 16),
            Text(
              needsFill ? 'Semua sudah terisi! 🎉' : 'Belum ada yang selesai',
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
                  : 'Data nutrisi yang sudah diisi akan muncul di sini',
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
            child: _NutriSubmissionCard(item: items[i], needsFill: needsFill),
          ),
    );
  }
}

// ─── Card Submission untuk Nutritionist ──────────────────────────────────────
class _NutriSubmissionCard extends StatelessWidget {
  final SubmissionModel item;
  final bool needsFill;

  const _NutriSubmissionCard({required this.item, required this.needsFill});

  static const _teal = Color(0xFF00897B);
  static const _dark = Color(0xFF1A2E2C);
  static const _muted = Color(0xFF5A7A78);

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
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
                  value: context.read<NutriSubmissionController>(),
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

                // Info
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

                // Badge
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
                  _macroCol('Kalori', '${item.calories!.toInt()} kkal', _teal),
                  _macroCol(
                    'Protein',
                    '${item.protein!.toStringAsFixed(1)}g',
                    const Color(0xFFE53935),
                  ),
                  _macroCol(
                    'Karbo',
                    '${item.carbs!.toStringAsFixed(1)}g',
                    const Color(0xFFF59E0B),
                  ),
                  _macroCol(
                    'Lemak',
                    '${item.fat!.toStringAsFixed(1)}g',
                    const Color(0xFF1E88E5),
                  ),
                ],
              ),
              if (item.nutriNote != null && item.nutriNote!.isNotEmpty) ...[
                const SizedBox(height: 10),
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
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00897B).withValues(alpha: 0.08),
                      const Color(0xFF00897B).withValues(alpha: 0.04),
                    ],
                  ),
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

  Widget _macroCol(String label, String value, Color color) => Column(
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
