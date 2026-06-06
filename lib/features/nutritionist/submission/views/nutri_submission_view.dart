import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nutritrack_app/features/general/submission/controllers/submission_controller.dart';
import 'package:nutritrack_app/features/general/submission/models/submission_model.dart';
import 'package:nutritrack_app/features/general/submission/views/widgets/submission_image_widget.dart';
import 'package:nutritrack_app/features/nutritionist/views/nutri_food_form_view.dart';

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

  // ── Pagination ──────────────────────────────────────────────────────────
  static const _pageSize = 5;
  int _needsFillPage = 0;
  int _filledPage = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) {
        setState(() {
          _needsFillPage = 0;
          _filledPage = 0;
        });
      }
    });
    _searchCtrl.addListener(
      () => setState(() {
        _query = _searchCtrl.text.toLowerCase();
        _needsFillPage = 0;
        _filledPage = 0;
      }),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showImageViewer(BuildContext ctx, String imagePath) {
    if (imagePath.isEmpty) return;
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => _ImageViewerPage(imagePath: imagePath)),
    );
  }

  String _formatDateShort(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SubmissionController>();

    // Sort by newest (createdAt descending)
    final belumDiisi = ctrl.approvedNeedsFill
        .where((s) => s.foodName.toLowerCase().contains(_query))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final sudahDiisi = ctrl.approvedFilled
        .where((s) => s.foodName.toLowerCase().contains(_query))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Pengajuan Saya',
          style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari nama makanan...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: _muted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _muted,
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      suffixIcon: _query.isNotEmpty
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
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
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
          _buildPaginatedList(
            belumDiisi,
            needsFill: true,
            currentPage: _needsFillPage,
            onPageChanged: (p) => setState(() => _needsFillPage = p),
          ),
          _buildPaginatedList(
            sudahDiisi,
            needsFill: false,
            currentPage: _filledPage,
            onPageChanged: (p) => setState(() => _filledPage = p),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginatedList(
    List<SubmissionModel> items, {
    required bool needsFill,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
  }) {
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
              style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(fontSize: 13, color: _muted),
            ),
          ],
        ),
      );
    }

    final totalPages = (items.length / _pageSize).ceil();
    final safePage = currentPage.clamp(0, totalPages - 1);
    final start = safePage * _pageSize;
    final end = (start + _pageSize).clamp(0, items.length);
    final pageItems = items.sublist(start, end);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: pageItems.length,
            itemBuilder: (ctx, i) {
              final item = pageItems[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NutriListCard(
                  item: item,
                  needsFill: needsFill,
                  dateLabel: _formatDateShort(item.createdAt),
                  timeLabel: _formatTime(item.createdAt),
                  onViewImage: item.imagePath.isNotEmpty
                      ? () => _showImageViewer(ctx, item.imagePath)
                      : null,
                ),
              );
            },
          ),
        ),

        // Pagination Bar
        if (totalPages > 1)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageBtn(
                  icon: Icons.chevron_left_rounded,
                  enabled: safePage > 0,
                  onTap: () => onPageChanged(safePage - 1),
                ),
                const SizedBox(width: 6),
                ...List.generate(totalPages, (idx) {
                  final active = idx == safePage;
                  return GestureDetector(
                    onTap: () => onPageChanged(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 34 : 30,
                      height: 32,
                      decoration: BoxDecoration(
                        color: active ? _green : const Color(0xFFF4FAF6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? _green : const Color(0xFFD5EDE0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : _muted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                _pageBtn(
                  icon: Icons.chevron_right_rounded,
                  enabled: safePage < totalPages - 1,
                  onTap: () => onPageChanged(safePage + 1),
                ),
                const SizedBox(width: 12),
                Text(
                  '${start + 1}–$end dari ${items.length}',
                  style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _pageBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF4FAF6) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFFD5EDE0) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _dark : const Color(0xFFB0BEC5),
        ),
      ),
    );
  }
}

// ─── Card di list ─────────────────────────────────────────────────────────────
class _NutriListCard extends StatelessWidget {
  final SubmissionModel item;
  final bool needsFill;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback? onViewImage;

  const _NutriListCard({
    required this.item,
    required this.needsFill,
    required this.dateLabel,
    required this.timeLabel,
    this.onViewImage,
  });

  static const _green = Color(0xFF2E7D32);
  static const _dark = Color(0xFF1A2E22);
  static const _muted = Color(0xFF7A9485);

  @override
  Widget build(BuildContext context) {
    final accent = needsFill ? const Color(0xFFFF8F00) : _green;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NutriFoodFormView(item: item),
          ),
        );
      },
      child: Container(
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
          children: [
            // 1:1 image on top if exists
            if (item.imagePath.isNotEmpty)
              GestureDetector(
                onTap: onViewImage,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: SubmissionImage(
                          imagePath: item.imagePath,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: _noImage(),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.zoom_out_map_rounded, size: 11, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Perbesar',
                                style: TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  color: accent.withValues(alpha: 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_rounded, color: accent.withValues(alpha: 0.5), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Tidak ada foto',
                        style: TextStyle(fontSize: 11, color: accent.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ),

            if (item.imagePath.isNotEmpty)
              const Divider(height: 1, color: Color(0xFFF0F0F0)),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.foodName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _dark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'dari ${item.userName} · $dateLabel $timeLabel',
                              style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          needsFill ? 'Isi Data' : 'Selesai',
                          style: GoogleFonts.poppins(
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
                        _macro('Protein', '${item.protein!.toStringAsFixed(1)}g', const Color(0xFFE53935)),
                        _macro('Karbo', '${item.carbs!.toStringAsFixed(1)}g', const Color(0xFFF59E0B)),
                        _macro('Lemak', '${item.fat!.toStringAsFixed(1)}g', const Color(0xFF1E88E5)),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_rounded, color: _green, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Ketuk untuk mengisi data nutrisi',
                            style: GoogleFonts.poppins(
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
          ],
        ),
      ),
    );
  }

  Widget _noImage() => Container(
        width: double.infinity,
        color: const Color(0xFFF4FAF6),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, color: Color(0xFFB0BEC5), size: 32),
            SizedBox(height: 6),
            Text(
              'Foto tidak tersedia',
              style: TextStyle(fontSize: 11, color: Color(0xFFB0BEC5)),
            ),
          ],
        ),
      );

  Widget _macro(String label, String value, Color color) => Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: _muted)),
        ],
      );
}

// ─── Image Viewer Page ────────────────────────────────────────────────────────
class _ImageViewerPage extends StatelessWidget {
  final String imagePath;
  const _ImageViewerPage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Foto Pengajuan',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: SubmissionImage(
            imagePath: imagePath,
            fit: BoxFit.contain,
            placeholder: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 64,
                ),
                SizedBox(height: 12),
                Text(
                  'Foto tidak dapat ditampilkan',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
