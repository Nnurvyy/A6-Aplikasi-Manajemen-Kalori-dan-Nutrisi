import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/submission/submission_model.dart';
import '../../general/submission/submission_controller.dart';

class NutriFillSheet extends StatefulWidget {
  final SubmissionModel item;
  const NutriFillSheet({super.key, required this.item});

  @override
  State<NutriFillSheet> createState() => _NutriFillSheetState();
}

class _NutriFillSheetState extends State<NutriFillSheet> {
  static const _teal = Color(0xFF00897B);
  late final _calCtrl = TextEditingController(
    text: widget.item.calories?.toStringAsFixed(0) ?? '',
  );
  late final _proteinCtrl = TextEditingController(
    text: widget.item.protein?.toStringAsFixed(1) ?? '',
  );
  late final _carbsCtrl = TextEditingController(
    text: widget.item.carbs?.toStringAsFixed(1) ?? '',
  );
  late final _fatCtrl = TextEditingController(
    text: widget.item.fat?.toStringAsFixed(1) ?? '',
  );
  late final _noteCtrl = TextEditingController(
    text: widget.item.nutriNote ?? '',
  );
  bool _saving = false;

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
    final isEdit = widget.item.isNutriFilled;
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
                      color: _teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_rounded : Icons.add_chart_rounded,
                      color: _teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Data Nutrisi' : 'Isi Data Nutrisi',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2E2C),
                          ),
                        ),
                        Text(
                          widget.item.foodName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5A7A78),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Info pengaju
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 14, color: _teal),
                    const SizedBox(width: 6),
                    Text(
                      'Diajukan oleh: ${widget.item.userName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

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

              // Grid input
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'Kalori',
                      'kkal',
                      _calCtrl,
                      const Color(0xFFE8F5E9),
                      _teal,
                      Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
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
                    child: _field(
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
                    child: _field(
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

              // Note
              const Text(
                'Catatan Sumber (opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A7A78),
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
                  fillColor: const Color(0xFFF4F6F0),
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

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
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
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEdit
                                    ? Icons.update_rounded
                                    : Icons.save_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEdit
                                    ? 'Update Data Nutrisi'
                                    : 'Simpan Data Nutrisi',
                                style: const TextStyle(
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

  Widget _field(
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
                    color: Color(0xFF1A2E2C),
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
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A7A78)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final cal = double.tryParse(_calCtrl.text.trim());
    final pro = double.tryParse(_proteinCtrl.text.trim());
    final carb = double.tryParse(_carbsCtrl.text.trim());
    final fat = double.tryParse(_fatCtrl.text.trim());

    if (cal == null || pro == null || carb == null || fat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Harap isi semua field nutrisi dengan angka valid',
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await context.read<SubmissionController>().saveNutriData(
      id: widget.item.id,
      calories: cal,
      protein: pro,
      carbs: carb,
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
        backgroundColor: const Color(0xFF00897B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
