import 'package:flutter/material.dart';
import '../../models/submission_model.dart';

class SubmissionCard extends StatelessWidget {
  final SubmissionModel item;
  final VoidCallback? onTap;

  const SubmissionCard({super.key, required this.item, this.onTap});

  static const _bg = Color(0xFFF4FAF6);
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
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child:
                  item.imagePath.startsWith('assets')
                      ? Image.asset(
                        item.imagePath,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 90,
                        height: 90,
                        color: _primary.withOpacity(0.1),
                        child: const Icon(
                          Icons.fastfood_rounded,
                          color: _primary,
                          size: 36,
                        ),
                      ),
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
