import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'package:nutritrack_app/features/general/submission/controllers/submission_controller.dart';
import 'package:nutritrack_app/features/general/submission/models/submission_model.dart';
import 'package:nutritrack_app/features/general/submission/views/widgets/submission_image_widget.dart';
import 'package:nutritrack_app/features/nutritionist/views/nutri_food_form_view.dart';

class NutriDashboardView extends StatelessWidget {
  const NutriDashboardView({super.key});

  static const _green = Color(0xFF2E7D32);
  static const _greenLight = Color(0xFF4CAF50);
  static const _bg = Color(0xFFF4FAF6);
  static const _dark = Color(0xFF1A2E22);
  static const _muted = Color(0xFF7A9485);

  String _formatDateShort(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final ctrl = context.watch<SubmissionController>();

    // Sort by newest
    final belumDiisi = ctrl.approvedNeedsFill
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sudahDiisi = ctrl.approvedFilled
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Limit to 4 items
    final belumDiisiLimit = belumDiisi.take(4).toList();
    final sudahDiisiLimit = sudahDiisi.take(4).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B5E20),
                    Color(0xFF2E7D32),
                    Color(0xFF388E3C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
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
                              'Halo, ${user?.name.split(' ').first ?? 'Nutri'} 👋',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Panel Ahli Gizi · NutriTrack',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ── Stat chips ──────────────────────────────────────
                  Row(
                    children: [
                      _statChip(
                        '${belumDiisi.length}',
                        'Perlu\nDiisi',
                        Icons.pending_actions_rounded,
                        const Color(0xFFFFB300),
                      ),
                      const SizedBox(width: 10),
                      _statChip(
                        '${sudahDiisi.length}',
                        'Sudah\nLengkap',
                        Icons.check_circle_rounded,
                        const Color(0xFF81C784),
                      ),
                      const SizedBox(width: 10),
                      _statChip(
                        '${ctrl.approved.length}',
                        'Total\nApproved',
                        Icons.assignment_rounded,
                        Colors.white70,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Perlu diisi ───────────────────────────────────────────────
          if (belumDiisiLimit.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _sectionHeader(
                  '⚠️  Perlu Diisi (Terbaru)',
                  'Menampilkan ${belumDiisiLimit.length} dari ${belumDiisi.length} pengajuan',
                  const Color(0xFFFF8F00),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _NutriCard(
                    item: belumDiisiLimit[i],
                    needsFill: true,
                    dateLabel: _formatDateShort(belumDiisiLimit[i].createdAt),
                  ),
                ),
                childCount: belumDiisiLimit.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // ── Sudah dilengkapi ──────────────────────────────────────────
          if (sudahDiisiLimit.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _sectionHeader(
                  '✅  Sudah Dilengkapi (Terbaru)',
                  'Menampilkan ${sudahDiisiLimit.length} dari ${sudahDiisi.length} data nutrisi',
                  _greenLight,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _NutriCard(
                    item: sudahDiisiLimit[i],
                    needsFill: false,
                    dateLabel: _formatDateShort(sudahDiisiLimit[i].createdAt),
                  ),
                ),
                childCount: sudahDiisiLimit.length,
              ),
            ),
          ],

          // ── Empty state ───────────────────────────────────────────────
          if (ctrl.approved.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        size: 56,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada pengajuan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pengajuan yang di-ACC admin\nakan muncul di sini',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sectionHeader(String title, String subtitle, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── Card di Dashboard ────────────────────────────────────────────────────────
class _NutriCard extends StatelessWidget {
  final SubmissionModel item;
  final bool needsFill;
  final String dateLabel;

  const _NutriCard({
    required this.item,
    required this.needsFill,
    required this.dateLabel,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image with fallback
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 50,
                height: 50,
                child: item.imagePath.isNotEmpty
                    ? SubmissionImage(
                        imagePath: item.imagePath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: _avatarFallback(accent),
                      )
                    : _avatarFallback(accent),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'dari ${item.userName} · Diteruskan: $dateLabel',
                    style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 6),
                  if (!needsFill && item.calories != null)
                    Wrap(
                      spacing: 4,
                      children: [
                        _chip('${item.calories!.toInt()} kkal', _green),
                        _chip('P ${item.protein!.toStringAsFixed(0)}g', const Color(0xFFE53935)),
                        _chip('K ${item.carbs!.toStringAsFixed(0)}g', const Color(0xFFF59E0B)),
                        _chip('L ${item.fat!.toStringAsFixed(0)}g', const Color(0xFF1E88E5)),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Belum ada data nutrisi',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFFFF8F00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                needsFill ? Icons.edit_rounded : Icons.check_rounded,
                color: accent,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(Color accent) => Container(
        width: 50,
        height: 50,
        color: accent.withValues(alpha: 0.12),
        child: Center(
          child: Text(
            item.foodName.isNotEmpty ? item.foodName[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ),
      );

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      );
}
