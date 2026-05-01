import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/food/food_controller.dart';
import '../../general/food/models/log_model.dart';
import '../../general/food/models/food_model.dart';
import '../../general/food/food_detail_view.dart';
import '../../general/auth/auth_controller.dart';
import './manual_food_form_view.dart';

class PilihMakananManual extends StatefulWidget {
  const PilihMakananManual({super.key});

  @override
  State<PilihMakananManual> createState() => _PilihMakananManualState();
}

class _PilihMakananManualState extends State<PilihMakananManual> {
  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);

  @override
  Widget build(BuildContext context) {
    final foodCtrl = context.watch<FoodController>();
    final authCtrl = context.watch<AuthController>();
    final userId = authCtrl.currentUser?.id ?? '';
    
    // Filter manual logs for current user and unique-ify by name
    final Map<String, LogModel> uniqueManuals = {};
    for (var log in foodCtrl.allLogs) {
      if (log.isManual && log.userId == userId) {
        // Simpan yang terbaru (consumedAt paling baru)
        final existing = uniqueManuals[log.foodName.toLowerCase()];
        if (existing == null || log.consumedAt.isAfter(existing.consumedAt)) {
          uniqueManuals[log.foodName.toLowerCase()] = log;
        }
      }
    }

    final manualLogs = uniqueManuals.values.toList()
      ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Log Manual',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: manualLogs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              itemCount: manualLogs.length,
              itemBuilder: (context, index) => _buildManualLogCard(manualLogs[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormTambahMakananManual()),
          );
          if (result == true) {
            // Refresh handled by Provider
          }
        },
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tambah Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildManualLogCard(LogModel log) {
    final Color accentColor = _getCategoryColor(log.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLogDetail(log),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            log.foodName.isNotEmpty ? log.foodName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.foodName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${log.category} • ${log.servingSize.toInt()}g',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _nutriChip('P ${log.protein.toStringAsFixed(1)}g', const Color(0xFFFFEBEE), const Color(0xFFE53935)),
                                const SizedBox(width: 4),
                                _nutriChip('K ${log.carbs.toStringAsFixed(1)}g', const Color(0xFFFFF8E1), const Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                _nutriChip('L ${log.fat.toStringAsFixed(1)}g', const Color(0xFFFFF3E0), const Color(0xFFFF8C00)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${log.calories.toInt()}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const Text(
                            'kkal',
                            style: TextStyle(fontSize: 10, color: _textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.formattedTime,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24), // Buffer for the menu button
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: _buildMoreAction(context, log),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreAction(BuildContext context, LogModel log) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: _textMuted, size: 20),
      onSelected: (val) {
        if (val == 'edit') {
          _editManualLog(context, log);
        } else if (val == 'delete') {
          _confirmDeleteManualLog(context, log);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
              SizedBox(width: 10),
              Text('Edit Definisi'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
              SizedBox(width: 10),
              Text('Hapus Item', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _editManualLog(BuildContext context, LogModel log) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormTambahMakananManual(initialLog: log)),
    );
    if (result == true) {
      // Refresh handled by Provider
    }
  }

  void _confirmDeleteManualLog(BuildContext context, LogModel log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Makanan?'),
        content: Text('Semua catatan riwayat untuk "${log.foodName}" juga akan ikut terhapus. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              final authCtrl = context.read<AuthController>();
              final foodCtrl = context.read<FoodController>();
              await foodCtrl.deleteManualFood(authCtrl.currentUser?.id ?? '', log.foodName);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLogDetail(LogModel log) {
    // Convert LogModel to FoodModel for FoodDetailView
    // Total nutrition in LogModel is for log.servingSize, we need per 100g
    final factor = 100 / log.servingSize;
    final food = FoodModel(
      id: 'manual_${log.foodName.replaceAll(' ', '_').toLowerCase()}',
      name: log.foodName,
      category: log.category,
      calories: log.calories * factor,
      protein: log.protein * factor,
      carbs: log.carbs * factor,
      fat: log.fat * factor,
      defaultServingSize: log.servingSize,
      createdAt: log.consumedAt,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodDetailView(food: food, isManual: true)),
    );
  }

  Widget _nutriChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.note_add_rounded, size: 40, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada log manual',
            style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Klik + untuk membuat catatan baru',
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// Global Helper
Color _getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'lauk': return const Color(0xFF4CAF50);
    case 'makanan pokok': return const Color(0xFFF59E0B);
    case 'sayuran': return const Color(0xFF43A047);
    case 'buah': return const Color(0xFFE91E63);
    case 'minuman': return const Color(0xFF1E88E5);
    case 'snack': return const Color(0xFF9C27B0);
    default: return const Color(0xFF78909C);
  }
}
