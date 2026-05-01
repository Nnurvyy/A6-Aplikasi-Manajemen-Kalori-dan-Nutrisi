import 'package:flutter/material.dart';
import './submission_model.dart';
import './widgets/submission_card.dart';

class AdminSubmissionScreen extends StatefulWidget {
  final UserRole role;

  const AdminSubmissionScreen({super.key, required this.role});

  @override
  State<AdminSubmissionScreen> createState() => _AdminSubmissionScreenState();
}

class _AdminSubmissionScreenState extends State<AdminSubmissionScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF2ECC71);
  static const _bg = Color(0xFFF4FAF6);
  static const _textDark = Color(0xFF1A2E22);
  static const _textMuted = Color(0xFF7A9485);

  late TabController _tabCtrl;

  final List<SubmissionModel> _all = [
    SubmissionModel(
      id: '1',
      userId: 'u1',
      userName: 'Nuri',
      foodName: 'Nasi Goreng Spesial',
      imagePath: 'assets/placeholder.png',
      calories: 350,
      protein: 12,
      carbs: 55,
      fat: 8,
      status: SubmissionStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    SubmissionModel(
      id: '2',
      userId: 'u2',
      userName: 'Budi',
      foodName: 'Sate Ayam',
      imagePath: 'assets/placeholder.png',
      calories: 280,
      status: SubmissionStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    SubmissionModel(
      id: '3',
      userId: 'u3',
      userName: 'Sari',
      foodName: 'Es Teh Manis',
      imagePath: 'assets/placeholder.png',
      calories: 80,
      status: SubmissionStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<SubmissionModel> _filterBy(SubmissionStatus status) =>
      _all.where((e) => e.status == status).toList();

  void _review(SubmissionModel item, SubmissionStatus newStatus) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              newStatus == SubmissionStatus.approved
                  ? 'Terima Pengajuan?'
                  : 'Tolak Pengajuan?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '"${item.foodName}"',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Catatan (opsional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      newStatus == SubmissionStatus.approved
                          ? _primary
                          : Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final idx = _all.indexWhere((e) => e.id == item.id);
                  setState(() {
                    _all[idx] = item.copyWith(
                      status: newStatus,
                      reviewNote:
                          noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                    );
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  newStatus == SubmissionStatus.approved ? 'Terima' : 'Tolak',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.role == UserRole.admin
              ? 'Review Pengajuan (Admin)'
              : 'Review Pengajuan (Ahli)',
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _primary,
          unselectedLabelColor: _textMuted,
          indicatorColor: _primary,
          tabs: [
            Tab(
              text: 'Pending (${_filterBy(SubmissionStatus.pending).length})',
            ),
            Tab(
              text: 'Diterima (${_filterBy(SubmissionStatus.approved).length})',
            ),
            Tab(
              text: 'Ditolak (${_filterBy(SubmissionStatus.canceled).length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildTabContent(SubmissionStatus.pending, showActions: true),
          _buildTabContent(SubmissionStatus.approved),
          _buildTabContent(SubmissionStatus.canceled),
        ],
      ),
    );
  }

  Widget _buildTabContent(SubmissionStatus status, {bool showActions = false}) {
    final list = _filterBy(status);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 54,
              color: _textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Text('Tidak ada data', style: TextStyle(color: _textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder:
          (_, i) =>
              showActions
                  ? _reviewCard(list[i])
                  : SubmissionCard(item: list[i]),
    );
  }

  Widget _reviewCard(SubmissionModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SubmissionCard(item: item),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _review(item, SubmissionStatus.canceled),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    label: const Text(
                      'Tolak',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _review(item, SubmissionStatus.approved),
                    icon: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: const Text(
                      'Terima',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
