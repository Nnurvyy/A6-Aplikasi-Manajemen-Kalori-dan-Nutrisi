import 'dart:io';
import 'package:flutter/material.dart';
import 'submission_model.dart';

class SubmissionDetailScreen extends StatelessWidget {
  final SubmissionModel submission;

  const SubmissionDetailScreen({super.key, required this.submission});

  static const _primary = Color(0xFF2ECC71);
  static const _bg = Color(0xFFF4FAF6);
  static const _textDark = Color(0xFF1A2E22);
  static const _textMuted = Color(0xFF7A9485);

  Color get _statusColor {
    switch (submission.status) {
      case SubmissionStatus.approved:
        return const Color(0xFF2ECC71);
      case SubmissionStatus.canceled:
        return Colors.redAccent;
      case SubmissionStatus.pending:
        return const Color(0xFFFFB800);
    }
  }

  String get _statusLabel {
    switch (submission.status) {
      case SubmissionStatus.approved:
        return 'Diterima';
      case SubmissionStatus.canceled:
        return 'Ditolak';
      case SubmissionStatus.pending:
        return 'Menunggu Review';
    }
  }

  IconData get _statusIcon {
    switch (submission.status) {
      case SubmissionStatus.approved:
        return Icons.check_circle_rounded;
      case SubmissionStatus.canceled:
        return Icons.cancel_rounded;
      case SubmissionStatus.pending:
        return Icons.hourglass_top_rounded;
    }
  }

  Widget _buildImageWidget() {
    // File lokal dari image_picker
    if (submission.imagePath.isNotEmpty &&
        !submission.imagePath.startsWith('assets') &&
        File(submission.imagePath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(submission.imagePath),
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        ),
      );
    }
    // Asset path
    if (submission.imagePath.startsWith('assets')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          submission.imagePath,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        ),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, size: 72, color: _primary),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pengajuan',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImageWidget(),
          const SizedBox(height: 16),
          _infoCard(),
          const SizedBox(height: 16),
          if (submission.calories != null ||
              submission.protein != null ||
              submission.carbs != null ||
              submission.fat != null)
            _nutriCard(),
          const SizedBox(height: 16),
          _statusCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Informasi Makanan'),
          const SizedBox(height: 12),
          _row(Icons.restaurant_rounded, 'Nama', submission.foodName),
          _row(Icons.person_rounded, 'Diajukan oleh', submission.userName),
          _row(
            Icons.calendar_today_rounded,
            'Tanggal',
            _formatDate(submission.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _nutriCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Perkiraan Nutrisi'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (submission.calories != null)
                _nutriBadge(
                  '${submission.calories!.toStringAsFixed(0)}',
                  'kal',
                  const Color(0xFFFF6B35),
                ),
              if (submission.protein != null)
                _nutriBadge(
                  '${submission.protein!.toStringAsFixed(1)}g',
                  'protein',
                  _primary,
                ),
              if (submission.carbs != null)
                _nutriBadge(
                  '${submission.carbs!.toStringAsFixed(1)}g',
                  'karbo',
                  const Color(0xFFFFB800),
                ),
              if (submission.fat != null)
                _nutriBadge(
                  '${submission.fat!.toStringAsFixed(1)}g',
                  'lemak',
                  const Color(0xFF3498DB),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Status Pengajuan'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon, color: _statusColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (submission.reviewNote != null) ...[
            const SizedBox(height: 10),
            Text(
              'Catatan: ${submission.reviewNote}',
              style: TextStyle(color: _textMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: _textDark,
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 16),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: _textMuted, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _textDark, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutriBadge(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(label, style: TextStyle(color: _textMuted, fontSize: 11)),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
