import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/submission/submission_model.dart';
import '../../general/submission/submission_controller.dart';

class AdminSubmissionView extends StatefulWidget {
  const AdminSubmissionView({super.key});

  @override
  State<AdminSubmissionView> createState() => _AdminSubmissionViewState();
}

class _AdminSubmissionViewState extends State<AdminSubmissionView>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF4FAF6);
  static const _dark = Color(0xFF1A2E22);
  static const _muted = Color(0xFF7A9485);

  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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

  // ── Review bottom sheet ──────────────────────────────────────────────────
  void _showReviewSheet(
    BuildContext ctx,
    SubmissionModel item,
    SubmissionStatus action,
  ) {
    final noteCtrl = TextEditingController(text: item.reviewNote ?? '');
    final isApprove = action == SubmissionStatus.approved;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Icon + judul
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isApprove ? _green : Colors.red).withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isApprove
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isApprove ? _green : Colors.red,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isApprove
                                  ? 'Terima Pengajuan'
                                  : 'Tolak Pengajuan',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isApprove ? _green : Colors.red[700],
                              ),
                            ),
                            Text(
                              item.foodName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _muted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info pengaju
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD5EDE0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: _muted,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diajukan oleh',
                              style: TextStyle(fontSize: 10, color: _muted),
                            ),
                            Text(
                              item.userName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _dark,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: _muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(item.createdAt),
                          style: const TextStyle(fontSize: 12, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Catatan
                  Text(
                    isApprove
                        ? 'Catatan untuk ahli gizi (opsional)'
                        : 'Alasan penolakan (opsional)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          isApprove
                              ? 'Mis: Harap isi data nutrisi sesuai TKPI 2019'
                              : 'Mis: Nama makanan tidak jelas / duplikat',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB0BEC5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF4FAF6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD5EDE0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD5EDE0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol konfirmasi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context
                            .read<SubmissionController>()
                            .reviewSubmission(
                              id: item.id,
                              newStatus: action,
                              reviewNote:
                                  noteCtrl.text.trim().isEmpty
                                      ? null
                                      : noteCtrl.text.trim(),
                            );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  isApprove
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isApprove
                                        ? '"${item.foodName}" diterima & diteruskan ke ahli gizi'
                                        : '"${item.foodName}" ditolak',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor:
                                isApprove ? _green : Colors.red[700],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isApprove ? _green : Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isApprove ? 'Konfirmasi Terima' : 'Konfirmasi Tolak',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m lalu';
    if (d.inHours < 24) return '${d.inHours}j lalu';
    return '${d.inDays}h lalu';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SubmissionController>();

    List<SubmissionModel> _filter(List<SubmissionModel> src) =>
        _query.isEmpty
            ? src
            : src
                .where(
                  (s) =>
                      s.foodName.toLowerCase().contains(_query) ||
                      s.userName.toLowerCase().contains(_query),
                )
                .toList();

    final pending = _filter(ctrl.pending);
    final approved = _filter(ctrl.approved);
    final canceled = _filter(ctrl.canceled);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Kelola Pengajuan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        actions: [
          if (ctrl.pending.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions_rounded,
                    color: Colors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ctrl.pending.length} menunggu',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD5EDE0)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari nama makanan atau pengaju...',
                      hintStyle: const TextStyle(fontSize: 13, color: _muted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _muted,
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
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
                indicatorColor: _green,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                tabs: [
                  Tab(
                    child: _tabLabel('Menunggu', pending.length, Colors.orange),
                  ),
                  Tab(child: _tabLabel('Diterima', approved.length, _green)),
                  Tab(child: _tabLabel('Ditolak', canceled.length, Colors.red)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildList(context, pending, showActions: true),
          _buildList(
            context,
            approved,
            showActions: false,
            showNutriStatus: true,
          ),
          _buildList(context, canceled, showActions: false),
        ],
      ),
    );
  }

  Widget _tabLabel(String label, int count, Color color) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(label),
      const SizedBox(width: 6),
      Container(
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
      ),
    ],
  );

  Widget _buildList(
    BuildContext context,
    List<SubmissionModel> items, {
    required bool showActions,
    bool showNutriStatus = false,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                showActions
                    ? Icons.inbox_rounded
                    : Icons.check_circle_outline_rounded,
                size: 48,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              showActions ? 'Tidak ada pengajuan menunggu' : 'Tidak ada data',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Data akan muncul di sini',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      itemBuilder:
          (ctx, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SubmissionCard(
              item: items[i],
              showActions: showActions,
              showNutriStatus: showNutriStatus,
              timeAgo: _timeAgo(items[i].createdAt),
              onApprove:
                  showActions
                      ? () => _showReviewSheet(
                        ctx,
                        items[i],
                        SubmissionStatus.approved,
                      )
                      : null,
              onReject:
                  showActions
                      ? () => _showReviewSheet(
                        ctx,
                        items[i],
                        SubmissionStatus.canceled,
                      )
                      : null,
            ),
          ),
    );
  }
}

// ─── Card Submission Admin ────────────────────────────────────────────────────
class _SubmissionCard extends StatelessWidget {
  final SubmissionModel item;
  final bool showActions;
  final bool showNutriStatus;
  final String timeAgo;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _SubmissionCard({
    required this.item,
    required this.showActions,
    required this.showNutriStatus,
    required this.timeAgo,
    this.onApprove,
    this.onReject,
  });

  static const _green = Color(0xFF2E7D32);
  static const _dark = Color(0xFF1A2E22);
  static const _muted = Color(0xFF7A9485);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              showActions
                  ? Colors.orange.withValues(alpha: 0.25)
                  : showNutriStatus
                  ? _green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
          width: 1.5,
        ),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        showActions
                            ? Colors.orange.withValues(alpha: 0.12)
                            : _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      item.foodName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: showActions ? Colors.orange : _green,
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
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: _muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.userName,
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: _muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            timeAgo,
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Status badge
                      if (showNutriStatus)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                item.isNutriFilled
                                    ? _green.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.isNutriFilled
                                ? '✅ Nutrisi sudah diisi'
                                : '⏳ Menunggu ahli gizi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  item.isNutriFilled ? _green : Colors.orange,
                            ),
                          ),
                        ),

                      // Review note
                      if (item.reviewNote != null &&
                          item.reviewNote!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notes_rounded,
                                size: 12,
                                color: _muted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  item.reviewNote!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _muted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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

          // Action buttons (hanya untuk pending)
          if (showActions) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFFE53935),
                      ),
                      label: const Text(
                        'Tolak',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFE53935),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Terima',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
