import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../food/food_controller.dart';
import '../food/models/log_model.dart';
import 'FormTambahMakananManual.dart';

class PilihMakananManual extends StatefulWidget {
  const PilihMakananManual({super.key});

  @override
  State<PilihMakananManual> createState() => _PilihMakananManualState();
}

class _PilihMakananManualState extends State<PilihMakananManual> {
  static const Color _primary = Color(0xFF2ECC71);
  static const Color _bg = Color(0xFFF4FAF6);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF1A2E22);
  static const Color _textMuted = Color(0xFF7A9485);
  static const Color _calColor = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    final foodCtrl = context.watch<FoodController>();
    // Filter manual logs (you might want to filter by user too if needed, 
    // but FoodController notifyListeners usually handles the global log state for now)
    final manualLogs = foodCtrl.allLogs.where((log) => log.isManual).toList()
      ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Log Manual',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: manualLogs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: manualLogs.length,
              itemBuilder: (context, index) => _buildManualLogCard(manualLogs[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormTambahMakananManual()),
          );
          if (result == true) {
            // Refresh logic handled by Provider
          }
        },
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildManualLogCard(LogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.history_edu_rounded, color: _primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.foodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textDark)),
                const SizedBox(height: 2),
                Text('${log.category} • ${log.servingSize.toStringAsFixed(0)}g', style: const TextStyle(color: _textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${log.calories.toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold, color: _calColor, fontSize: 14)),
              Text(log.formattedTime, style: const TextStyle(color: _textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_rounded, size: 64, color: _textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Belum ada log manual', style: TextStyle(color: _textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Klik + untuk menambah log baru', style: TextStyle(color: _textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
