import 'package:flutter/material.dart';
<<<<<<< HEAD:lib/features/widgets/submission/submission_card.dart
import '../../screen/submission/submission_model.dart';
=======
import '../submission_model.dart';
import './submission_image_widget.dart';
>>>>>>> 39cad47cb319498d4508136c007c0b5a0b7427a0:lib/features/general/submission/widgets/submission_card.dart

class SubmissionCard extends StatelessWidget {
  final SubmissionModel item;
  final VoidCallback? onTap;

  const SubmissionCard({super.key, required this.item, this.onTap});

  static const _primary = Color(0xFF2ECC71);
  static const _textDark = Color(0xFF1A2E22);
  static const _textMuted = Color(0xFF7A9485);

  Color get _statusColor {
    switch (item.status) {
      case SubmissionStatus.approved:
        return const Color(0xFF2ECC71);
      case SubmissionStatus.canceled:
        return Colors.redAccent;
      case SubmissionStatus.pending:
        return const Color(0xFFFFB800);
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case SubmissionStatus.approved:
        return 'Diterima';
      case SubmissionStatus.canceled:
        return 'Ditolak';
      case SubmissionStatus.pending:
        return 'Menunggu';
    }
  }

  IconData get _statusIcon {
    switch (item.status) {
      case SubmissionStatus.approved:
        return Icons.check_circle_rounded;
      case SubmissionStatus.canceled:
        return Icons.cancel_rounded;
      case SubmissionStatus.pending:
        return Icons.hourglass_top_rounded;
    }
  }

  Widget _buildImage() {
    return SubmissionImage(
      imagePath: item.imagePath,
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      placeholder: _placeholder(),
      loadingWidget: Container(
        width: 90,
        height: 90,
        color: _primary.withOpacity(0.08),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 90,
      height: 90,
      color: _primary.withOpacity(0.1),
      child: const Icon(Icons.fastfood_rounded, color: _primary, size: 36),
    );
  }

  /// Badge indikator sync cloud di pojok kanan atas gambar
  Widget _buildSyncBadge() {
    if (item.isSynced) {
      return Positioned(
        top: 6,
        left: 6,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.cloud_done_rounded,
            color: Colors.white,
            size: 13,
          ),
        ),
      );
    } else {
      return Positioned(
        top: 6,
        left: 6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'Mengirim...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          // Border orange tipis kalau belum sync
          border:
              item.isSynced
                  ? null
                  : Border.all(color: Colors.orange.shade300, width: 1.5),
        ),
        child: Row(
          children: [
            // Gambar + badge sync
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Stack(children: [_buildImage(), _buildSyncBadge()]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.foodName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.calories != null)
                      Text(
                        '~${item.calories!.toStringAsFixed(0)} kal',
                        style: TextStyle(color: _textMuted, fontSize: 12),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(_statusIcon, color: _statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (!item.isSynced) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Menunggu koneksi internet...',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded, color: _textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
