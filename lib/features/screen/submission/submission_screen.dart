import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_controller.dart';
import 'submission_model.dart';
import '../../widgets/submission/submission_card.dart';
import '../../widgets/submission/submission_info_dialog.dart';
import 'add_submission_screen.dart';
import 'submission_detail_screen.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({super.key});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  static const _primary = Color(0xFF2ECC71);
  static const _bg = Color(0xFFF4FAF6);
  static const _textDark = Color(0xFF1A2E22);
  static const _textMuted = Color(0xFF7A9485);

  // List pengajuan user yang sedang login
  final List<SubmissionModel> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    // Data dummy sesuai user yang login (bisa diganti dengan Hive persistence)
    setState(() {
      _submissions.addAll([
        SubmissionModel(
          id: '1',
          userId: user.id,
          userName: user.name,
          foodName: 'Nasi Goreng Spesial',
          imagePath: '',
          calories: 350,
          protein: 12,
          carbs: 55,
          fat: 8,
          status: SubmissionStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        SubmissionModel(
          id: '2',
          userId: user.id,
          userName: user.name,
          foodName: 'Es Teh Manis',
          imagePath: '',
          calories: 80,
          status: SubmissionStatus.approved,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
    });
  }

  void _goToAdd() async {
    final result = await Navigator.push<SubmissionModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddSubmissionScreen()),
    );
    if (result != null) setState(() => _submissions.insert(0, result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pengajuan Makanan',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: _textMuted),
            onPressed:
                () => showDialog(
                  context: context,
                  builder: (_) => const SubmissionInfoDialog(),
                ),
          ),
        ],
      ),
      body: _submissions.isEmpty ? _buildEmpty() : _buildList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAdd,
        backgroundColor: _primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _submissions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder:
          (_, i) => SubmissionCard(
            item: _submissions[i],
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            SubmissionDetailScreen(submission: _submissions[i]),
                  ),
                ),
          ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              size: 54,
              color: _primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada pengajuan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajukan makanan favoritmu\nuntuk ditambahkan ke database!',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _goToAdd,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Buat Pengajuan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
