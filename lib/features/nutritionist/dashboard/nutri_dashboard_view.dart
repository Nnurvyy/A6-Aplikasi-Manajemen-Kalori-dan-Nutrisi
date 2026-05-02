import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/auth/auth_controller.dart';
import '../../general/submission/submission_model.dart';
import '../submission/nutri_submission_controller.dart';
import '../widgets/nutri_fill_sheet.dart';

class NutriDashboardView extends StatelessWidget {
  const NutriDashboardView({super.key});

  static const _teal = Color(0xFF00897B);
  static const _bg = Color(0xFFF0FAF9);
  static const _dark = Color(0xFF1A2E2C);
  static const _muted = Color(0xFF5A7A78);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final ctrl = context.watch<NutriSubmissionController>();
    final belumDiisi = ctrl.belumDiisi;
    final sudahDiisi = ctrl.sudahDiisi;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00695C), Color(0xFF00897B)],
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
                              'Halo, ${user?.name?.split(' ').first ?? 'Nutri'} 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Panel Ahli Gizi · NutriTrack',
                              style: TextStyle(
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

                  // ── Stat row ──────────────────────────────────────────
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
                        const Color(0xFF66BB6A),
                      ),
                      const SizedBox(width: 10),
                      _statChip(
                        '${ctrl.all.length}',
                        'Total\nPengajuan',
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

          // ── Section: Prioritas — Perlu Diisi ────────────────────────────
          if (belumDiisi.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _sectionHeader(
                  '⚠️  Perlu Diisi',
                  '${belumDiisi.length} pengajuan belum ada data nutrisi',
                  const Color(0xFFFF8F00),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _DashboardCard(item: belumDiisi[i], needsFill: true),
                ),
                childCount: belumDiisi.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // ── Section: Sudah Dilengkapi ───────────────────────────────────
          if (sudahDiisi.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _sectionHeader(
                  '✅  Sudah Dilengkapi',
                  '${sudahDiisi.length} data nutrisi sudah lengkap',
                  const Color(0xFF43A047),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _DashboardCard(item: sudahDiisi[i], needsFill: false),
                ),
                childCount: sudahDiisi.length,
              ),
            ),
          ],

          // ── Empty state ────────────────────────────────────────────────
          if (ctrl.all.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        size: 56,
                        color: _teal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada pengajuan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pengajuan yang di-ACC admin\nakan muncul di sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 13),
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

  Widget _statChip(String value, String label, IconData icon, Color color) {
    return Expanded(
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, Color color) {
    return Container(
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Dashboard Nutritionist ─────────────────────────────────────────────
class _DashboardCard extends StatelessWidget {
  final SubmissionModel item;
  final bool needsFill;

  const _DashboardCard({required this.item, required this.needsFill});

  static const _teal = Color(0xFF00897B);
  static const _dark = Color(0xFF1A2E2C);
  static const _muted = Color(0xFF5A7A78);

  @override
  Widget build(BuildContext context) {
    final accent = needsFill ? const Color(0xFFFF8F00) : _teal;

    return GestureDetector(
      onTap:
          () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder:
                (_) => ChangeNotifierProvider.value(
                  value: context.read<NutriSubmissionController>(),
                  child: NutriFillSheet(item: item),
                ),
          ),
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
            // Avatar huruf pertama
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  item.foodName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Diajukan oleh: ${item.userName}',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 6),
                  if (item.isNutriFilled)
                    Wrap(
                      spacing: 4,
                      children: [
                        _chip(
                          '${item.calories!.toInt()} kkal',
                          const Color(0xFF4CAF50),
                        ),
                        _chip(
                          'P ${item.protein!.toStringAsFixed(0)}g',
                          const Color(0xFFE53935),
                        ),
                        _chip(
                          'K ${item.carbs!.toStringAsFixed(0)}g',
                          const Color(0xFFF59E0B),
                        ),
                        _chip(
                          'L ${item.fat!.toStringAsFixed(0)}g',
                          const Color(0xFF1E88E5),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Belum ada data nutrisi',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF8F00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Action icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                needsFill ? Icons.edit_rounded : Icons.edit_note_rounded,
                color: accent,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
    ),
  );
}
