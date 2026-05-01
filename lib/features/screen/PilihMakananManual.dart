import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../food/food_controller.dart';
import '../food/models/log_model.dart';
import '../auth/auth_controller.dart';
import 'FormTambahMakananManual.dart';

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

    // Filter manual logs for current user
    final manualLogs =
        foodCtrl.allLogs
            .where((log) => log.isManual && log.userId == userId)
            .toList()
          ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Log Manual',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body:
          manualLogs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: manualLogs.length,
                itemBuilder:
                    (context, index) => _buildManualLogCard(manualLogs[index]),
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
        label: const Text(
          'Tambah Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildManualLogCard(LogModel log) {
    final Color accentColor = _getCategoryColor(log.category);

    return GestureDetector(
      onTap: () => _showLogDetail(log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
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
                    style: const TextStyle(fontSize: 12, color: _textMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _nutriChip(
                        'P ${log.protein.toStringAsFixed(1)}g',
                        const Color(0xFFFFEBEE),
                        const Color(0xFFE53935),
                      ),
                      const SizedBox(width: 4),
                      _nutriChip(
                        'K ${log.carbs.toStringAsFixed(1)}g',
                        const Color(0xFFFFF8E1),
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      _nutriChip(
                        'L ${log.fat.toStringAsFixed(1)}g',
                        const Color(0xFFFFF3E0),
                        const Color(0xFFFF8C00),
                      ),
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDetail(LogModel log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogDetailSheet(log: log),
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
          Icon(
            Icons.note_add_rounded,
            size: 64,
            color: _textMuted.withOpacity(0.5),
          ),
          Container(padding: const EdgeInsets.all(20)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada log manual',
            style: TextStyle(color: _textMuted, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Klik + untuk menambah log baru',
            style: TextStyle(color: _textMuted, fontSize: 12),
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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

class _LogDetailSheet extends StatelessWidget {
  final LogModel log;
  const _LogDetailSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final accentColor = _getCategoryColor(log.category);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    log.foodName.isNotEmpty
                        ? log.foodName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.foodName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2A1B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        log.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      '${log.calories.toInt()}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'kkal total',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _macroItem(
                'Protein',
                log.protein,
                const Color(0xFFFFEBEE),
                const Color(0xFFE53935),
                Icons.fitness_center,
              ),
              const SizedBox(width: 12),
              _macroItem(
                'Karbo',
                log.carbs,
                const Color(0xFFFFF8E1),
                const Color(0xFFF59E0B),
                Icons.grain,
              ),
              const SizedBox(width: 12),
              _macroItem(
                'Lemak',
                log.fat,
                const Color(0xFFFFF3E0),
                const Color(0xFFFF8C00),
                Icons.water_drop,
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () async {
                final foodCtrl = context.read<FoodController>();
                final authCtrl = context.read<AuthController>();
                final user = authCtrl.currentUser;
                if (user == null) return;

                final success = await foodCtrl.addFoodToDailyLog(
                  userId: user.id,
                  foodName: log.foodName,
                  category: log.category,
                  calories: log.calories,
                  protein: log.protein,
                  carbs: log.carbs,
                  fat: log.fat,
                  mealType: 'Snack',
                  dateConsumed: DateTime.now(),
                  servingSize: log.servingSize,
                  isManual: true,
                );

                if (success && context.mounted) {
                  Navigator.pop(context); // Close sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Berhasil menambahkan ${log.foodName} ke log hari ini',
                      ),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Tambah ke Log Hari Ini',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroItem(
    String label,
    double value,
    Color bg,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              '${value.toStringAsFixed(1)}g',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

// Global Helper
Color _getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'lauk':
      return const Color(0xFF4CAF50);
    case 'makanan pokok':
      return const Color(0xFFF59E0B);
    case 'sayuran':
      return const Color(0xFF43A047);
    case 'buah':
      return const Color(0xFFE91E63);
    case 'minuman':
      return const Color(0xFF1E88E5);
    case 'snack':
      return const Color(0xFF9C27B0);
    default:
      return const Color(0xFF78909C);
  }
}
