import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/submission/submission_controller.dart';
import '../../general/submission/submission_model.dart';
import '../../general/submission/widgets/submission_image_widget.dart';
import '../widgets/nutri_fill_sheet.dart';

class NutriSubmissionView extends StatefulWidget {
  const NutriSubmissionView({super.key});

  @override
  State<NutriSubmissionView> createState() => _NutriSubmissionViewState();
}

class _NutriSubmissionViewState extends State<NutriSubmissionView>
    with SingleTickerProviderStateMixin {
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

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return _formatDate(dt);
  }

  @override
  Widget build(BuildContext context) {
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
                  fontSize: 13,
                ),
                indicatorColor: _green,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            'Belum Diisi',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _badge(belumDiisi.length, const Color(0xFFFF8F00)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            'Sudah Diisi',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _badge(sudahDiisi.length, _green),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body:
          ctrl.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              )
              : TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildList(belumDiisi, needsFill: true),
                  _buildList(sudahDiisi, needsFill: false),
                ],
              ),
    );
  }

  Widget _badge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
    );
  }

  Widget _buildList(List<SubmissionModel> items, {required bool needsFill}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              needsFill
                  ? Icons.assignment_outlined
                  : Icons.check_circle_outline_rounded,
              size: 56,
              color: _muted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),
            Text(
              needsFill
                  ? 'Semua pengajuan sudah diisi!'
                  : 'Belum ada yang selesai diisi',
              style: TextStyle(
                fontSize: 14,
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _NutriSubmissionCard(
            item: item,
            needsFill: needsFill,
            timeAgo: _timeAgo(item.createdAt),
            dateLabel: _formatDate(item.createdAt),
            // FIX: Pass the outer context so Provider is accessible inside bottom sheet
            outerContext: context,
          ),
        );
      },
    );
  }
}

// ── Card Widget ─────────────────────────────────────────────────────────────

class _NutriSubmissionCard extends StatelessWidget {
  final SubmissionModel item;
  final bool needsFill;
  final String timeAgo;
  final String dateLabel;
  final BuildContext outerContext; // FIX: outer context untuk Provider

  const _NutriSubmissionCard({
    required this.item,
    required this.needsFill,
    required this.timeAgo,
    required this.dateLabel,
    required this.outerContext,
  });

  static const _green = Color(0xFF2E7D32);
  static const _dark = Color(0xFF1A2E22);
  static const _muted = Color(0xFF7A9485);

  Widget _avatarFallback(Color accent) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          item.foodName.isNotEmpty ? item.foodName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ),
    );
  }

  Widget _macro(String label, String value, Color color) {
    return Column(
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
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF7A9485)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = needsFill ? const Color(0xFFFF8F00) : _green;

    return GestureDetector(
      onTap:
          () => showModalBottomSheet(
            context:
                outerContext, // FIX: gunakan outerContext bukan context card
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
                // FIX: Gunakan SubmissionImage bukan Image.file langsung
                // (mendukung URL Cloudinary dan file lokal)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child:
                        item.imagePath.isNotEmpty
                            ? SubmissionImage(
                              imagePath: item.imagePath,
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                              placeholder: _avatarFallback(accent),
                            )
                            : _avatarFallback(accent),
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
                      // FIX: Tampilkan tanggal pengajuan (dari admin)
                      Text(
                        'dari ${item.userName} · $dateLabel',
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
          ],
        ),
      ),
    );
  }
}
