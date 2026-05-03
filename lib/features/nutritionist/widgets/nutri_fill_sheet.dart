import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/submission/submission_controller.dart';
import '../../general/submission/submission_model.dart';

class NutriFillSheet extends StatefulWidget {
  final SubmissionModel item;
  const NutriFillSheet({super.key, required this.item});

  @override
  State<NutriFillSheet> createState() => _NutriFillSheetState();
}

class _NutriFillSheetState extends State<NutriFillSheet> {
  // ── Tema hijau ─────────────────────────────────────────────────────────────
  static const _green = Color(0xFF2E7D32);

  late final TextEditingController _calCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _noteCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.item;
    _calCtrl = TextEditingController(
      text: s.calories?.toStringAsFixed(0) ?? '',
    );
    _proteinCtrl = TextEditingController(
      text: s.protein?.toStringAsFixed(1) ?? '',
    );
    _carbsCtrl = TextEditingController(text: s.carbs?.toStringAsFixed(1) ?? '');
    _fatCtrl = TextEditingController(text: s.fat?.toStringAsFixed(1) ?? '');
    _noteCtrl = TextEditingController(text: s.nutriNote ?? '');
  }

  @override
  void dispose() {
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: _green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Isi Data Nutrisi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2E22),
                          ),
                        ),
                        Text(
                          widget.item.foodName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7A9485),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info per 100g
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Color(0xFFFF8F00),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Semua nilai per 100 gram bahan makanan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF8F00),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Grid 2x2
              Row(
                children: [
                  Expanded(
                    child: _nutriInput(
                      'Kalori',
                      'kkal',
                      _calCtrl,
                      const Color(0xFFE8F5E9),
                      _green,
                      Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _nutriInput(
                      'Protein',
                      'g',
                      _proteinCtrl,
                      const Color(0xFFFFEBEE),
                      const Color(0xFFE53935),
                      Icons.fitness_center_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _nutriInput(
                      'Karbohidrat',
                      'g',
                      _carbsCtrl,
                      const Color(0xFFFFF8E1),
                      const Color(0xFFF59E0B),
                      Icons.grain_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _nutriInput(
                      'Lemak',
                      'g',
                      _fatCtrl,
                      const Color(0xFFE3F2FD),
                      const Color(0xFF1E88E5),
                      Icons.water_drop_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Catatan
              const Text(
                'Catatan / Sumber Data (opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7A9485),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Mis: Berdasarkan tabel TKPI 2019',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB0BEC5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4FAF6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol simpan — panggil SubmissionController.saveNutriData()
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _saving
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Simpan Data Nutrisi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutriInput(
    String label,
    String unit,
    TextEditingController ctrl,
    Color bg,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2E22),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB0BEC5),
                    ),
                  ),
                ),
              ),
              Text(
                unit,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A9485)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final cal = double.tryParse(_calCtrl.text.trim());
    final protein = double.tryParse(_proteinCtrl.text.trim());
    final carbs = double.tryParse(_carbsCtrl.text.trim());
    final fat = double.tryParse(_fatCtrl.text.trim());

    if (cal == null || protein == null || carbs == null || fat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi semua nilai nutrisi'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    // ← Simpan ke SubmissionController global → Hive → terbaca semua role
    await context.read<SubmissionController>().saveNutriData(
      id: widget.item.id,
      calories: cal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      nutriNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Data nutrisi "${widget.item.foodName}" disimpan!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
