import 'package:flutter/material.dart';
import '../../general/food/models/food_model.dart';

class ManualIngredientInputPage extends StatefulWidget {
  final FoodModel? initialFood;
  const ManualIngredientInputPage({super.key, this.initialFood});

  @override
  State<ManualIngredientInputPage> createState() => _ManualIngredientInputPageState();
}

class _ManualIngredientInputPageState extends State<ManualIngredientInputPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _gramCtrl;
  late TextEditingController _calCtrl;
  late TextEditingController _proCtrl;
  late TextEditingController _carbCtrl;
  late TextEditingController _fatCtrl;

  final Color _primary = const Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialFood?.name ?? '');
    _gramCtrl = TextEditingController(text: widget.initialFood?.defaultServingSize.toInt().toString() ?? '');
    
    if (widget.initialFood != null) {
      final nutrition = widget.initialFood!.nutritionForAmount(widget.initialFood!.defaultServingSize);
      _calCtrl = TextEditingController(text: nutrition['calories']?.round().toString() ?? '');
      _proCtrl = TextEditingController(text: nutrition['protein']?.round().toString() ?? '');
      _carbCtrl = TextEditingController(text: nutrition['carbs']?.round().toString() ?? '');
      _fatCtrl = TextEditingController(text: nutrition['fat']?.round().toString() ?? '');
    } else {
      _calCtrl = TextEditingController();
      _proCtrl = TextEditingController();
      _carbCtrl = TextEditingController();
      _fatCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gramCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.initialFood != null ? 'Edit Bahan Manual' : 'Input Bahan Manual', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildMainForm(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade400]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Masukkan rincian nutrisi bahan makanan Anda sendiri untuk perhitungan yang akurat.',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainForm() {
    return Column(
      children: [
        _inputField(label: 'Nama Bahan', controller: _nameCtrl, icon: Icons.drive_file_rename_outline, hint: 'Contoh: Saus Tiram'),
        const SizedBox(height: 16),
        _inputField(label: 'Jumlah (gram/ml)', controller: _gramCtrl, icon: Icons.scale, hint: '100', isNumber: true),
        const SizedBox(height: 16),
        _inputField(label: 'Kalori (kcal)', controller: _calCtrl, icon: Icons.local_fire_department, hint: '0', isNumber: true, color: Colors.orange),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _inputField(label: 'Protein (g)', controller: _proCtrl, icon: Icons.fitness_center, hint: '0', isNumber: true, color: Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _inputField(label: 'Karbo (g)', controller: _carbCtrl, icon: Icons.grain, hint: '0', isNumber: true, color: Colors.amber)),
          ],
        ),
        const SizedBox(height: 16),
        _inputField(label: 'Lemak (g)', controller: _fatCtrl, icon: Icons.water_drop, hint: '0', isNumber: true, color: Colors.blue),
      ],
    );
  }

  Widget _inputField({required String label, required TextEditingController controller, required IconData icon, required String hint, bool isNumber = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5A7A5A))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200, width: 2)),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: color ?? _primary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final name = _nameCtrl.text.trim();
          final gram = double.tryParse(_gramCtrl.text) ?? 0;
          final cal = double.tryParse(_calCtrl.text) ?? 0;
          final pro = double.tryParse(_proCtrl.text) ?? 0;
          final carb = double.tryParse(_carbCtrl.text) ?? 0;
          final fat = double.tryParse(_fatCtrl.text) ?? 0;

          if (name.isNotEmpty && gram > 0) {
            final result = {
              'isManual': true,
              'name': name,
              'grams': gram,
              'calories': cal,
              'protein': pro,
              'carbs': carb,
              'fat': fat,
            };
            Navigator.pop(context, result);
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: _primary, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text(widget.initialFood != null ? 'Simpan Perubahan' : 'Gunakan Bahan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
