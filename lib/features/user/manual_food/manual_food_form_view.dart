import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../general/auth/auth_controller.dart';
import '../../general/food/food_controller.dart';


import '../../general/food/widgets/ingredient_picker_dialog.dart';
import '../../general/food/models/food_model.dart';
import '../../general/food/models/log_model.dart';
import 'dart:convert';
import './saved_compositions_page.dart';
import './manual_ingredient_input_page.dart';

class FormTambahMakananManual extends StatefulWidget {
  final LogModel? initialLog;
  final FoodModel? initialFood; // NEW
  final bool isHistoricalEdit;
  const FormTambahMakananManual({super.key, this.initialLog, this.initialFood, this.isHistoricalEdit = false});

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
  
  int _quantity = 1;

  String _selectedUnit = 'gram';
  String _selectedCategory = 'Makanan Pokok';
  File? _image;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> _ingredients = [];

  static const List<String> _categories = [
    'Makanan Pokok',
    'Lauk',
    'Snack',
    'Sayuran',
    'Buah',
    'Minuman',
  ];

  static const List<String> _units = [
    'gram',
    'ml',
  ];

  // ── Color palette NutriTrack ──────────────────────────────
  static const Color _primary = Color(0xFF2E7D32); // Progress Green
  static const Color _primaryDark = Color(0xFF1B5E20);
  static const Color _bg = Color(0xFFF4FAF6);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF1A2E22);
  static const Color _textMuted = Color(0xFF7A9485);
  static const Color _calColor = Color(0xFF2E7D32); // Hijau
  static const Color _proteinColor = Color(0xFFE53935); // Merah
  static const Color _carbsColor = Color(0xFFFFB300); // Kuning/Amber
  static const Color _fatColor = Color(0xFFFF9800); // Oren
  static const Color _borderColor = Color(0xFFD5EDE0);

  @override
  void initState() {
    super.initState();
    if (widget.initialLog != null) {
      final log = widget.initialLog!;
      _nameCtrl.text = log.foodName;
      _servingSizeCtrl.text = log.servingSize.toInt().toString();
      _calCtrl.text = log.calories.round().toString();
      _proteinCtrl.text = log.protein.round().toString();
      _carbsCtrl.text = log.carbs.round().toString();
      _fatCtrl.text = log.fat.round().toString();
      
      if (_categories.contains(log.category)) _selectedCategory = log.category;
      if (log.imageUrl != null) _image = File(log.imageUrl!);

      if (log.ingredientsJson != null) {
        try {
          final List dynamicList = jsonDecode(log.ingredientsJson!);
          _ingredients = dynamicList.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (_) {}
      }
    } else if (widget.initialFood != null) {
      final food = widget.initialFood!;
      _nameCtrl.text = food.name;
      _servingSizeCtrl.text = food.defaultServingSize.toInt().toString();
      // FoodModel nutrition is per 100g, convert back to serving size for display
      final factor = food.defaultServingSize / 100;
      _calCtrl.text = (food.calories * factor).round().toString();
      _proteinCtrl.text = (food.protein * factor).round().toString();
      _carbsCtrl.text = (food.carbs * factor).round().toString();
      _fatCtrl.text = (food.fat * factor).round().toString();
      
      if (_categories.contains(food.category)) _selectedCategory = food.category;
      if (food.imageUrl != null) _image = File(food.imageUrl!);

      if (food.ingredientsJson != null) {
        try {
          final List dynamicList = jsonDecode(food.ingredientsJson!);
          _ingredients = dynamicList.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (_) {}
      }
    }
  }

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

  void _save() async {
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

    final foodCtrl = context.read<FoodController>();
    if (widget.initialLog != null && widget.isHistoricalEdit) {
      // MODE EDIT RIWAYAT (Update log yang sudah ada)
      await foodCtrl.updateSpecificLog(
        widget.initialLog!.copyWith(
          foodName: foodName,
          category: _selectedCategory,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          servingSize: servingSize,
          imageUrl: _image?.path,
          ingredientsJson: _ingredients.isEmpty ? null : jsonEncode(_ingredients),
        ),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, true);
      }
    } else {
      // MODE TAMBAH BARU atau EDIT DEFINISI (Save ke Food database)
      final foodId = widget.initialFood?.id ?? 'manual_${DateTime.now().millisecondsSinceEpoch}';
      final newFood = FoodModel(
        id: foodId,
        name: foodName,
        category: _selectedCategory,
        calories: (calories / servingSize) * 100, // stored per 100g
        protein: (protein / servingSize) * 100,
        carbs: (carbs / servingSize) * 100,
        fat: (fat / servingSize) * 100,
        defaultServingSize: servingSize,
        isApproved: true,
        createdAt: widget.initialFood?.createdAt ?? DateTime.now(),
        imageUrl: _image?.path,
        ingredientsJson: _ingredients.isEmpty ? null : jsonEncode(_ingredients),
        userId: userId, // ← TAMBAHKAN INI
      );

      if (widget.initialFood != null) {
        await foodCtrl.updateFood(newFood);
      } else {
        await foodCtrl.addFood(newFood);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$foodName berhasil disimpan'),
            backgroundColor: _primary,
            duration: const Duration(seconds: 2),
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
        title: Text(
          (widget.initialLog == null && widget.initialFood == null) ? 'Tambah Log Baru' : 'Edit Makanan',
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
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
            if (_ingredients.isEmpty) ...[
              _buildServingSizeRow(),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            _buildIngredientsSection(),
            const SizedBox(height: 24),
            _buildNutritionSection(),
            const SizedBox(height: 24),
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



  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('Komposisi Bahan'),
            ElevatedButton.icon(
              onPressed: () => _showIngredientOptions(context),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('Tambah', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
        if (_ingredients.isNotEmpty) const SizedBox(height: 16),
        if (_ingredients.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor, width: 2),
              boxShadow: [
                BoxShadow(color: _primary.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredients.length,
              separatorBuilder: (_, __) => Divider(color: _borderColor, height: 1),
              itemBuilder: (ctx, idx) {
                final item = _ingredients[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.restaurant_menu, color: Color(0xFF4CAF50), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item['grams'].round()}g • ${item['calories'].round()} kcal',
                              style: const TextStyle(fontSize: 12, color: _textMuted),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _smallNutriChip('P ${item['protein']?.round()}g', Colors.red.shade50, Colors.red.shade700),
                                const SizedBox(width: 4),
                                _smallNutriChip('K ${item['carbs']?.round()}g', Colors.amber.shade50, Colors.amber.shade800),
                                const SizedBox(width: 4),
                                _smallNutriChip('L ${item['fat']?.round()}g', Colors.orange.shade50, Colors.orange.shade800),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _actionButton(
                        icon: Icons.edit_note_rounded,
                        color: Colors.blue,
                        onTap: () => _editIngredient(idx),
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.red,
                        onTap: () {
                          setState(() => _ingredients.removeAt(idx));
                          _calculateFromIngredients();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }



  void _calculateFromIngredients() {
    if (_ingredients.isEmpty) {
      _calCtrl.clear();
      _proteinCtrl.clear();
      _carbsCtrl.clear();
      _fatCtrl.clear();
      return;
    }
    double cal = 0, pro = 0, car = 0, fat = 0, totalGrams = 0;
    for (var ing in _ingredients) {
      cal += ing['calories'];
      pro += ing['protein'];
      car += ing['carbs'];
      fat += ing['fat'];
      totalGrams += (ing['grams'] ?? 0);
    }
    _calCtrl.text = cal.round().toString();
    _proteinCtrl.text = pro.round().toString();
    _carbsCtrl.text = car.round().toString();
    _fatCtrl.text = fat.round().toString();
    _servingSizeCtrl.text = totalGrams.round().toString();
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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 4), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11))]),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: TextFormField(controller: controller, readOnly: _ingredients.isNotEmpty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
              Text(unit, style: const TextStyle(color: _textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }



  void _editIngredient(int idx) {
    final item = _ingredients[idx];
    final nameCtrl = TextEditingController(text: item['name']);
    final gramCtrl = TextEditingController(text: item['grams'].round().toString());
    final calCtrl = TextEditingController(text: item['calories'].round().toString());
    final proCtrl = TextEditingController(text: item['protein'].round().toString());
    final carbCtrl = TextEditingController(text: item['carbs'].round().toString());
    final fatCtrl = TextEditingController(text: item['fat'].round().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: _primary),
            const SizedBox(width: 12),
            const Text('Edit Bahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogInputField(label: 'Nama Bahan', controller: nameCtrl, icon: Icons.drive_file_rename_outline, hint: 'Nama Bahan'),
              const SizedBox(height: 16),
              _dialogInputField(label: 'Jumlah (g)', controller: gramCtrl, icon: Icons.scale, hint: '100', isNumber: true),
              const SizedBox(height: 16),
              _dialogInputField(label: 'Kalori (kcal)', controller: calCtrl, icon: Icons.local_fire_department, hint: '0', isNumber: true, color: Colors.orange),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _dialogInputField(label: 'Protein', controller: proCtrl, icon: Icons.fitness_center, hint: '0', isNumber: true, color: Colors.red)),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogInputField(label: 'Karbo', controller: carbCtrl, icon: Icons.grain, hint: '0', isNumber: true, color: Colors.amber)),
                ],
              ),
              const SizedBox(height: 16),
              _dialogInputField(label: 'Lemak', controller: fatCtrl, icon: Icons.water_drop, hint: '0', isNumber: true, color: Colors.orange),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final gram = double.tryParse(gramCtrl.text) ?? 0;
              final cal = double.tryParse(calCtrl.text) ?? 0;
              final pro = double.tryParse(proCtrl.text) ?? 0;
              final carb = double.tryParse(carbCtrl.text) ?? 0;
              final fat = double.tryParse(fatCtrl.text) ?? 0;

              if (name.isNotEmpty && gram > 0) {
                setState(() {
                  _ingredients[idx] = {
                    'id': item['id'],
                    'name': name,
                    'grams': gram,
                    'calories': cal,
                    'protein': pro,
                    'carbs': carb,
                    'fat': fat,
                  };
                });
                _calculateFromIngredients();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogInputField({required String label, required TextEditingController controller, required IconData icon, required String hint, bool isNumber = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF5A7A5A))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF4F6F0), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: color ?? _primary, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(backgroundColor: _primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showIngredientOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tambah Bahan Dari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
              const SizedBox(height: 20),
              _optionTile(
                icon: Icons.search_rounded,
                color: Colors.blue,
                title: 'Database Makanan',
                subtitle: 'Cari dari 1000+ data makanan',
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await showDialog(
                    context: context,
                    builder: (ctx) => const IngredientPickerDialog(),
                  );
                  _handleIngredientResult(result);
                },
              ),
              const SizedBox(height: 12),
              _optionTile(
                icon: Icons.bookmark_added_rounded,
                color: Colors.orange,
                title: 'Komposisi Tersimpan',
                subtitle: 'Pilih dari bahan tunggal yang tersimpan',
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedCompositionsPage(title: 'Komposisi Tersimpan')),
                  );
                  _handleIngredientResult(result);
                },
              ),
              const SizedBox(height: 12),
              _optionTile(
                icon: Icons.edit_note_rounded,
                color: Colors.green,
                title: 'Input Manual',
                subtitle: 'Masukkan rincian bahan baru',
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManualIngredientInputPage()),
                  );
                  _handleIngredientResult(result, saveToDb: true);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textDark)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: _textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _textMuted.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  void _handleIngredientResult(dynamic result, {bool saveToDb = false}) async {
    if (result != null && result is Map) {
      if (result['isManual'] == true) {
        // From ManualIngredientInputPage
        if (saveToDb) {
          final foodCtrl = context.read<FoodController>();
          final foodId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
          final newIngredient = FoodModel(
            id: foodId,
            name: result['name'],
            category: 'Lainnya',
            calories: ((result['calories'] as num) / (result['grams'] as num)) * 100,
            protein: ((result['protein'] as num) / (result['grams'] as num)) * 100,
            carbs: ((result['carbs'] as num) / (result['grams'] as num)) * 100,
            fat: ((result['fat'] as num) / (result['grams'] as num)) * 100,
            defaultServingSize: (result['grams'] as num).toDouble(),
            isApproved: true,
            createdAt: DateTime.now(), // ← KEMBALIKAN INI
            imageUrl: null,
            ingredientsJson: null,
            isManualIngredient: true,
            userId: context.read<AuthController>().currentUser?.id,
          );
          await foodCtrl.addFood(newIngredient);
        }

        setState(() {
          _ingredients.add({
            'id': 'manual_${DateTime.now().millisecondsSinceEpoch}',
            'name': result['name'],
            'grams': result['grams'],
            'calories': result['calories'],
            'protein': result['protein'],
            'carbs': result['carbs'],
            'fat': result['fat'],
          });
        });
      } else {
        final FoodModel food = result['food'];
        final double grams = (result['grams'] ?? food.defaultServingSize).toDouble();
        final nutrition = food.nutritionForAmount(grams);
        
        setState(() {
          _ingredients.add({
            'id': food.id,
            'name': food.name,
            'grams': grams,
            'calories': nutrition['calories'],
            'protein': nutrition['protein'],
            'carbs': nutrition['carbs'],
            'fat': nutrition['fat'],
          });
        });
      }
      _calculateFromIngredients();
    }
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

  Widget _smallNutriChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

