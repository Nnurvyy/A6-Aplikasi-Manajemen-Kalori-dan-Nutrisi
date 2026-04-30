import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import '../food/food_controller.dart';
import '../../helpers/date_controller.dart';

class FormTambahMakananManual extends StatefulWidget {
  const FormTambahMakananManual({super.key});

  @override
  State<FormTambahMakananManual> createState() => _FormTambahMakananManualState();
}

class _FormTambahMakananManualState extends State<FormTambahMakananManual> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _servingSizeCtrl = TextEditingController(text: '100');
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  String _selectedUnit = 'gram';
  String _selectedCategory = 'Makanan Pokok';
  File? _image;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  static const List<String> _categories = [
    'Makanan Pokok',
    'Lauk',
    'Snack',
    'Sayuran',
    'Buah',
  ];

  static const List<String> _units = [
    'gram',
    'ml',
    'butir',
    'porsi',
    'sdm',
    'sdt',
    'mangkuk',
    'gelas',
  ];

  // ── Color palette NutriTrack ──────────────────────────────
  static const Color _primary = Color(0xFF2ECC71);
  static const Color _primaryDark = Color(0xFF27AE60);
  static const Color _bg = Color(0xFFF4FAF6);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF1A2E22);
  static const Color _textMuted = Color(0xFF7A9485);
  static const Color _calColor = Color(0xFFFF6B35);
  static const Color _proteinColor = Color(0xFF2ECC71);
  static const Color _carbsColor = Color(0xFFFFB800);
  static const Color _fatColor = Color(0xFF3498DB);
  static const Color _borderColor = Color(0xFFD5EDE0);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingSizeCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  void _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);

    final foodName = _nameCtrl.text.trim();
    final calories = double.tryParse(_calCtrl.text) ?? 0;
    final protein = double.tryParse(_proteinCtrl.text) ?? 0;
    final carbs = double.tryParse(_carbsCtrl.text) ?? 0;
    final fat = double.tryParse(_fatCtrl.text) ?? 0;
    final servingSize = double.tryParse(_servingSizeCtrl.text) ?? 100.0;

    final success = await context.read<FoodController>().addFoodToDailyLog(
      userId: userId,
      foodName: foodName,
      category: _selectedCategory,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealType: '',
      dateConsumed: context.read<DateController>().selectedDate,
      servingSize: servingSize,
      isManual: true,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$foodName berhasil ditambahkan ke log'),
            backgroundColor: _primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan ke log.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Tambah Log Baru',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildPhotoPicker(),
            const SizedBox(height: 20),
            _buildSectionLabel('Kategori Makanan (Opsional)'),
            const SizedBox(height: 8),
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            _buildSectionLabel('Nama Bahan'),
            const SizedBox(height: 8),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildServingSizeRow(),
            const SizedBox(height: 24),
            _buildNutritionSection(),
            const SizedBox(height: 20),
            _buildLivePreview(),
            const SizedBox(height: 16),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: _image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_rounded, color: _primary, size: 40),
                  const SizedBox(height: 8),
                  const Text('Upload Foto (Opsional)', style: TextStyle(color: _textMuted, fontSize: 13)),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textDark));
  }

  Widget _buildCategoryDropdown() {
    return _styledDropdown(
      value: _selectedCategory,
      items: _categories,
      onChanged: (v) => setState(() => _selectedCategory = v!),
    );
  }

  Widget _buildNameField() {
    return _styledField(
      controller: _nameCtrl,
      hint: 'Contoh: Nasi Goreng Spesial',
      icon: Icons.restaurant_menu_rounded,
      validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
    );
  }

  Widget _buildServingSizeRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('Ukuran Sajian'),
              const SizedBox(height: 8),
              _styledField(
                controller: _servingSizeCtrl,
                hint: '100',
                icon: Icons.straighten_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('Satuan'),
              const SizedBox(height: 8),
              _styledDropdown(
                value: _selectedUnit,
                items: _units,
                onChanged: (v) => setState(() => _selectedUnit = v!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionSection() {
    return Column(
      children: [
        _buildNutrientField(label: 'Kalori', hint: '0', unit: 'kcal', controller: _calCtrl, color: _calColor, icon: Icons.local_fire_department_rounded),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildNutrientField(label: 'Protein', hint: '0', unit: 'g', controller: _proteinCtrl, color: _proteinColor, icon: Icons.fitness_center_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildNutrientField(label: 'Karbo', hint: '0', unit: 'g', controller: _carbsCtrl, color: _carbsColor, icon: Icons.grain_rounded)),
          ],
        ),
        const SizedBox(height: 12),
        _buildNutrientField(label: 'Lemak', hint: '0', unit: 'g', controller: _fatCtrl, color: _fatColor, icon: Icons.water_drop_rounded),
      ],
    );
  }

  Widget _buildNutrientField({required String label, required String hint, required String unit, required TextEditingController controller, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 4), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11))]),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: TextFormField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
              Text(unit, style: const TextStyle(color: _textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildLivePreview() {
    final cal = double.tryParse(_calCtrl.text) ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Estimasi Kalori', style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
          Text('${cal.toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold, color: _calColor, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveIngredient,
        style: ElevatedButton.styleFrom(backgroundColor: _primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan ke Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _styledDropdown({required String value, required List<String> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderColor, width: 1.5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(value: value, isExpanded: true, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged),
      ),
    );
  }

  Widget _styledField({required TextEditingController controller, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderColor, width: 1.5)),
      child: TextFormField(controller: controller, keyboardType: keyboardType, inputFormatters: inputFormatters, validator: validator, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: _textMuted), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14))),
    );
  }
}
