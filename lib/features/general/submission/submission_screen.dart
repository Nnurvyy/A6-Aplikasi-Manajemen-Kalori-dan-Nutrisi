import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import './submission_controller.dart';
import './submission_model.dart';
import './add_submission_screen.dart';
import './submission_detail_screen.dart';
import './widgets/submission_card.dart';
import './widgets/submission_info_dialog.dart';

class SubmissionScreen extends StatelessWidget {
  const SubmissionScreen({super.key});

  static const _green = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF4FAF6);
  static const _textDark = Color(0xFF1A2E22);
  static const _textMuted = Color(0xFF7A9485);

  void _goToAdd(BuildContext context) async {
    // AddSubmissionScreen mengembalikan SubmissionModel langsung
    final result = await Navigator.push<SubmissionModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddSubmissionScreen()),
    );
    if (result == null) return;
    if (!context.mounted) return;

    // Simpan ke SubmissionController (Hive) — langsung terbaca admin & nutri
    await context.read<SubmissionController>().addSubmission(
      userId: result.userId,
      userName: result.userName,
      foodName: result.foodName,
      imagePath: result.imagePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) return const SizedBox();

    // Watch SubmissionController → otomatis rebuild saat ada perubahan
    final ctrl = context.watch<SubmissionController>();
    final items = ctrl.byUser(user.id);

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
      body: items.isEmpty ? _buildEmpty(context) : _buildList(context, items),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToAdd(context),
        backgroundColor: _green,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<SubmissionModel> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder:
          (_, i) => SubmissionCard(
            item: items[i],
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => SubmissionDetailScreen(submission: items[i]),
                  ),
                ),
          ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              size: 54,
              color: _green,
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
          const Text(
            'Ajukan makanan favoritmu\nuntuk ditambahkan ke database!',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _goToAdd(context),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Buat Pengajuan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
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
