import 'package:flutter/material.dart';

class SubmissionInfoDialog extends StatelessWidget {
  const SubmissionInfoDialog({super.key});

  static const _primary = Color(0xFF2ECC71);
  static const _textDark = Color(0xFF1A2E22);
  static const _textMuted = Color(0xFF7A9485);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: _primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Ketentuan Pengajuan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _rule(Icons.image_rounded, 'Foto makanan harus jelas dan terang'),
            _rule(Icons.no_food_rounded, 'Bukan makanan merek dagang komersial'),
            _rule(Icons.restaurant_rounded, 'Hanya makanan/minuman yang dapat dikonsumsi'),
            _rule(Icons.block_rounded, 'Tidak mengandung SARA atau konten tidak pantas'),
            _rule(Icons.description_rounded,
                'Nama makanan wajib diisi, info nutrisi bersifat opsional'),
            _rule(Icons.pending_rounded,
                'Pengajuan akan direview oleh Admin atau Ahli Nutrisi'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFFB800), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pengajuan yang tidak memenuhi ketentuan akan berstatus Ditolak.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Mengerti',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rule(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: _textDark)),
          ),
        ],
      ),
    );
  }
}
