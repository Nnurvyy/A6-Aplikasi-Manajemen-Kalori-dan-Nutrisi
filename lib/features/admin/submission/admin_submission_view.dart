import 'dart:io';
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

  // ── Pagination ──────────────────────────────────────────────────────────
  static const _pageSize = 5;
  int _pendingPage = 0;
  int _approvedPage = 0;
  int _canceledPage = 0;

  static const _rejectReasons = [
    'Foto tidak jelas / buram',
    'Foto bukan makanan',
    'Nama makanan tidak jelas',
    'Makanan sudah ada di database',
    'Gambar melanggar ketentuan',
    'Data nutrisi tidak valid',
    'Duplikat pengajuan',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) {
        setState(() {
          _pendingPage = 0;
          _approvedPage = 0;
          _canceledPage = 0;
        });
      }
    });
    _searchCtrl.addListener(
      () => setState(() {
        _query = _searchCtrl.text.toLowerCase();
        _pendingPage = 0;
        _approvedPage = 0;
        _canceledPage = 0;
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

  // ── Dialog info pengaju (klik baris pengaju) ─────────────────────────────
  void _showSubmitterInfo(BuildContext ctx, SubmissionModel item) {
    showDialog(
      context: ctx,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: _green,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Info Pengaju',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _dark,
                              ),
                            ),
                            Text(
                              item.foodName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _muted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: _muted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 14),
                  _infoRow(
                    Icons.person_outline_rounded,
                    'Nama Pengaju',
                    item.userName,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.fastfood_rounded,
                    'Nama Makanan',
                    item.foodName,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.calendar_today_rounded,
                    'Tanggal Pengajuan',
                    _formatDateFull(item.createdAt),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.access_time_rounded,
                    'Waktu Pengajuan',
                    _formatTime(item.createdAt),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.info_outline_rounded,
                    'Status',
                    _statusLabel(item.status),
                    valueColor: _statusColor(item.status),
                  ),
                  if (item.status == SubmissionStatus.canceled &&
                      item.reviewNote != null &&
                      item.reviewNote!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.cancel_outlined,
                      'Alasan Ditolak',
                      item.reviewNote!,
                      valueColor: Colors.red[700],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF4FAF6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w600,
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

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _muted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? _dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Review bottom sheet ──────────────────────────────────────────────────
  void _showReviewSheet(
    BuildContext ctx,
    SubmissionModel item,
    SubmissionStatus action,
  ) {
    final noteCtrl = TextEditingController(text: item.reviewNote ?? '');
    final isApprove = action == SubmissionStatus.approved;
    String? selectedReason;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setSheetState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isApprove ? _green : Colors.red)
                                      .withValues(alpha: 0.1),
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
                                        color:
                                            isApprove
                                                ? _green
                                                : Colors.red[700],
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

                          // Foto di review sheet
                          if (item.imagePath.isNotEmpty) ...[
                            const Text(
                              'Foto yang diajukan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                _showImageViewer(ctx, item.imagePath);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: 160,
                                      child: Image.file(
                                        File(item.imagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => _imgErrBox(160),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.zoom_out_map_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Perbesar',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4FAF6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFD5EDE0),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_rounded,
                                    color: Color(0xFFB0BEC5),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tidak ada foto dalam pengajuan ini',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB0BEC5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Info pengaju dengan waktu lengkap
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4FAF6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD5EDE0),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_rounded,
                                      size: 16,
                                      color: _muted,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Diajukan oleh',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _muted,
                                          ),
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
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: _muted,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Tanggal & Waktu',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _muted,
                                          ),
                                        ),
                                        Text(
                                          '${_formatDateFull(item.createdAt)}, ${_formatTime(item.createdAt)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _dark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick-select alasan tolak
                          if (!isApprove) ...[
                            const Text(
                              'Alasan penolakan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  _rejectReasons.map((reason) {
                                    final selected = selectedReason == reason;
                                    return GestureDetector(
                                      onTap:
                                          () => setSheetState(() {
                                            selectedReason =
                                                selected ? null : reason;
                                            if (!selected) {
                                              noteCtrl.text = reason;
                                            } else {
                                              noteCtrl.clear();
                                            }
                                          }),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              selected
                                                  ? Colors.red.withValues(
                                                    alpha: 0.12,
                                                  )
                                                  : const Color(0xFFF4FAF6),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color:
                                                selected
                                                    ? Colors.red
                                                    : const Color(0xFFD5EDE0),
                                            width: selected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Text(
                                          reason,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                            color:
                                                selected
                                                    ? Colors.red[700]
                                                    : _muted,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Atau tulis alasan lain:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],

                          if (isApprove)
                            const Text(
                              'Catatan untuk ahli gizi (opsional)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _dark,
                              ),
                            ),
                          if (isApprove) const SizedBox(height: 8),
                          TextField(
                            controller: noteCtrl,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText:
                                  isApprove
                                      ? 'Mis: Harap isi data nutrisi sesuai TKPI 2019'
                                      : 'Tulis catatan tambahan...',
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB0BEC5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF4FAF6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD5EDE0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD5EDE0),
                                ),
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
                                backgroundColor:
                                    isApprove ? _green : Colors.red[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isApprove
                                    ? 'Konfirmasi Terima'
                                    : 'Konfirmasi Tolak',
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
                ),
          ),
    );
  }

  Widget _imgErrBox(double h) => Container(
    width: double.infinity,
    height: h,
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

  // ── Format helpers ────────────────────────────────────────────────────────
  static const _monthsFull = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  static const _monthsShort = [
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

  String _formatDateFull(DateTime dt) =>
      '${dt.day} ${_monthsFull[dt.month - 1]} ${dt.year}';
  String _formatDateShort(DateTime dt) =>
      '${dt.day} ${_monthsShort[dt.month - 1]} ${dt.year}';
  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  String _statusLabel(SubmissionStatus s) {
    switch (s) {
      case SubmissionStatus.pending:
        return 'Menunggu Review';
      case SubmissionStatus.approved:
        return 'Diterima';
      case SubmissionStatus.canceled:
        return 'Ditolak';
    }
  }

  Color _statusColor(SubmissionStatus s) {
    switch (s) {
      case SubmissionStatus.pending:
        return Colors.orange;
      case SubmissionStatus.approved:
        return _green;
      case SubmissionStatus.canceled:
        return Colors.red;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SubmissionController>();

    List<SubmissionModel> filter(List<SubmissionModel> src) =>
        _query.isEmpty
            ? src
            : src
                .where(
                  (s) =>
                      s.foodName.toLowerCase().contains(_query) ||
                      s.userName.toLowerCase().contains(_query),
                )
                .toList();

    final pending = filter(ctrl.pending);
    final approved = filter(ctrl.approved);
    final canceled = filter(ctrl.canceled);

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
          _buildPaginatedList(
            context,
            pending,
            showActions: true,
            currentPage: _pendingPage,
            onPageChanged: (p) => setState(() => _pendingPage = p),
          ),
          _buildPaginatedList(
            context,
            approved,
            showActions: false,
            showNutriStatus: true,
            currentPage: _approvedPage,
            onPageChanged: (p) => setState(() => _approvedPage = p),
          ),
          _buildPaginatedList(
            context,
            canceled,
            showActions: false,
            showRejectionReason: true,
            currentPage: _canceledPage,
            onPageChanged: (p) => setState(() => _canceledPage = p),
          ),
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

  // ── Paginated list ────────────────────────────────────────────────────────
  Widget _buildPaginatedList(
    BuildContext context,
    List<SubmissionModel> items, {
    required bool showActions,
    bool showNutriStatus = false,
    bool showRejectionReason = false,
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

    final totalPages = (items.length / _pageSize).ceil();
    final safePage = currentPage.clamp(0, totalPages - 1);
    final start = safePage * _pageSize;
    final end = (start + _pageSize).clamp(0, items.length);
    final pageItems = items.sublist(start, end);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: pageItems.length,
            itemBuilder:
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubmissionCard(
                    item: pageItems[i],
                    showActions: showActions,
                    showNutriStatus: showNutriStatus,
                    showRejectionReason: showRejectionReason,
                    timeAgo: _timeAgo(pageItems[i].createdAt),
                    dateLabel: _formatDateShort(pageItems[i].createdAt),
                    timeLabel: _formatTime(pageItems[i].createdAt),
                    onViewImage:
                        pageItems[i].imagePath.isNotEmpty
                            ? () =>
                                _showImageViewer(ctx, pageItems[i].imagePath)
                            : null,
                    onTapSubmitter: () => _showSubmitterInfo(ctx, pageItems[i]),
                    onApprove:
                        showActions
                            ? () => _showReviewSheet(
                              ctx,
                              pageItems[i],
                              SubmissionStatus.approved,
                            )
                            : null,
                    onReject:
                        showActions
                            ? () => _showReviewSheet(
                              ctx,
                              pageItems[i],
                              SubmissionStatus.canceled,
                            )
                            : null,
                  ),
                ),
          ),
        ),

        // ── Pagination bar ─────────────────────────────────────────────
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
                          style: TextStyle(
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
                  style: const TextStyle(fontSize: 11, color: _muted),
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

// ─── Image Viewer Fullscreen ──────────────────────────────────────────────────
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
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder:
                (_, __, ___) => const Column(
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

// ─── Card Submission Admin ────────────────────────────────────────────────────
class _SubmissionCard extends StatelessWidget {
  final SubmissionModel item;
  final bool showActions;
  final bool showNutriStatus;
  final bool showRejectionReason;
  final String timeAgo;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback? onViewImage;
  final VoidCallback? onTapSubmitter;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _SubmissionCard({
    required this.item,
    required this.showActions,
    required this.showNutriStatus,
    required this.showRejectionReason,
    required this.timeAgo,
    required this.dateLabel,
    required this.timeLabel,
    this.onViewImage,
    this.onTapSubmitter,
    this.onApprove,
    this.onReject,
  });

  static const _green = Color(0xFF2E7D32);
  static const _dark = Color(0xFF1A2E22);
  static const _muted = Color(0xFF7A9485);

  @override
  Widget build(BuildContext context) {
    final borderColor =
        showActions
            ? Colors.orange.withValues(alpha: 0.25)
            : showNutriStatus
            ? _green.withValues(alpha: 0.2)
            : Colors.red.withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
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
          // ── Foto thumbnail ──────────────────────────────────────────
          if (item.imagePath.isNotEmpty)
            GestureDetector(
              onTap: onViewImage,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 130,
                      child: Image.file(
                        File(item.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _noImage(),
                      ),
                    ),
                    if (showActions)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.image_search_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Periksa foto',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.zoom_out_map_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Perbesar',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
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
            // Strip "tidak ada foto"
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: 52,
                color:
                    showActions
                        ? Colors.orange.withValues(alpha: 0.07)
                        : showNutriStatus
                        ? _green.withValues(alpha: 0.05)
                        : Colors.red.withValues(alpha: 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_rounded,
                      color:
                          showActions
                              ? Colors.orange.withValues(alpha: 0.5)
                              : const Color(0xFFB0BEC5),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tidak ada foto',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            showActions
                                ? Colors.orange.withValues(alpha: 0.7)
                                : const Color(0xFFB0BEC5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (item.imagePath.isNotEmpty)
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

          Padding(
            padding: const EdgeInsets.all(14),
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
                const SizedBox(height: 8),

                // ── Baris pengaju (bisa diklik) ───────────────────────
                GestureDetector(
                  onTap: onTapSubmitter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD5EDE0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: _muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.userName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _dark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: _muted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$dateLabel  $timeLabel',
                          style: const TextStyle(fontSize: 10, color: _muted),
                        ),
                        const SizedBox(width: 5),
                        // Indikator bisa diklik
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Detail',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Status nutri ──────────────────────────────────────
                if (showNutriStatus) ...[
                  const SizedBox(height: 8),
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
                        color: item.isNutriFilled ? _green : Colors.orange,
                      ),
                    ),
                  ),
                ],

                // ── Alasan penolakan ──────────────────────────────────
                if (showRejectionReason) ...[
                  const SizedBox(height: 8),
                  if (item.reviewNote != null && item.reviewNote!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 14,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alasan Penolakan',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[400],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.reviewNote!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Tidak ada catatan penolakan',
                        style: TextStyle(fontSize: 11, color: _muted),
                      ),
                    ),
                ],

                // ── Catatan review biasa ──────────────────────────────
                if (!showRejectionReason &&
                    item.reviewNote != null &&
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
                            style: const TextStyle(fontSize: 11, color: _muted),
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

          // ── Action buttons ────────────────────────────────────────────
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

  Widget _noImage() => Container(
    width: double.infinity,
    height: 130,
    color: const Color(0xFFF4FAF6),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported_rounded,
          color: Color(0xFFB0BEC5),
          size: 28,
        ),
        SizedBox(height: 4),
        Text(
          'Foto tidak tersedia',
          style: TextStyle(fontSize: 11, color: Color(0xFFB0BEC5)),
        ),
      ],
    ),
  );
}
