import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutritrack_app/helpers/app_colors.dart';

class ScanIngredientEditView extends StatefulWidget {
  final String name;
  final double initialGrams;
  final double initialCalories;
  final double initialProtein;
  final double initialCarbs;
  final double initialFat;

  const ScanIngredientEditView({
    super.key,
    required this.name,
    required this.initialGrams,
    required this.initialCalories,
    required this.initialProtein,
    required this.initialCarbs,
    required this.initialFat,
  });

  @override
  State<ScanIngredientEditView> createState() => _ScanIngredientEditViewState();
}

class _ScanIngredientEditViewState extends State<ScanIngredientEditView> {
  late TextEditingController nameCtrl;
  late TextEditingController gramsCtrl;
  late TextEditingController calCtrl;
  late TextEditingController proCtrl;
  late TextEditingController carbCtrl;
  late TextEditingController fatCtrl;

  late double baseGrams;
  late double baseCal;
  late double basePro;
  late double baseCarb;
  late double baseFat;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.name);
    gramsCtrl = TextEditingController(text: _format(widget.initialGrams));
    calCtrl = TextEditingController(text: _format(widget.initialCalories, 0));
    proCtrl = TextEditingController(text: _format(widget.initialProtein));
    carbCtrl = TextEditingController(text: _format(widget.initialCarbs));
    fatCtrl = TextEditingController(text: _format(widget.initialFat));

    baseGrams = widget.initialGrams > 0 ? widget.initialGrams : 100;
    baseCal = widget.initialCalories;
    basePro = widget.initialProtein;
    baseCarb = widget.initialCarbs;
    baseFat = widget.initialFat;
  }

  String _format(double val, [int fractionDigits = 1]) {
    if (val == val.toInt()) return val.toInt().toString();
    return val.toStringAsFixed(fractionDigits);
  }

  void _onWeightChanged(String newText) {
    double? newWeight = double.tryParse(newText);
    if (newWeight != null && baseGrams > 0) {
      double ratio = newWeight / baseGrams;
      calCtrl.text = _format(baseCal * ratio, 0);
      proCtrl.text = _format(basePro * ratio);
      carbCtrl.text = _format(baseCarb * ratio);
      fatCtrl.text = _format(baseFat * ratio);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    gramsCtrl.dispose();
    calCtrl.dispose();
    proCtrl.dispose();
    carbCtrl.dispose();
    fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Edit Ingredient'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField('Nama Ingredient', nameCtrl, Icons.fastfood_rounded, isDark, isNumber: false),
              const SizedBox(height: 16),
              _buildInputField('Gram', gramsCtrl, Icons.scale_rounded, isDark, onChanged: _onWeightChanged),
              const Divider(height: 48),
              Text(
                'Nutrisi',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInputField('Kalori', calCtrl, Icons.local_fire_department_rounded, isDark, color: Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputField('Protein (g)', proCtrl, Icons.fitness_center_rounded, isDark, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInputField('Karbo (g)', carbCtrl, Icons.grain_rounded, isDark, color: Colors.amber)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputField('Lemak (g)', fatCtrl, Icons.opacity_rounded, isDark, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'name': nameCtrl.text,
                      'grams': double.tryParse(gramsCtrl.text) ?? 0,
                      'calories': double.tryParse(calCtrl.text) ?? 0,
                      'protein': double.tryParse(proCtrl.text) ?? 0,
                      'carbs': double.tryParse(carbCtrl.text) ?? 0,
                      'fat': double.tryParse(fatCtrl.text) ?? 0,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Simpan Perubahan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, bool isDark, {bool isNumber = true, Color? color, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          onChanged: onChanged,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color ?? AppColors.primary, size: 20),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF4F6F0),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
