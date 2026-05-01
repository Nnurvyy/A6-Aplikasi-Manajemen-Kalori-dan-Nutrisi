import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../general/food/food_controller.dart';
import '../../general/food/models/food_model.dart';
import '../../general/widgets/nt_text_field.dart';
import '../../general/widgets/nt_button.dart';

class AdminFoodFormView extends StatefulWidget {
  final FoodModel? initialFood;

  const AdminFoodFormView({super.key, this.initialFood});

  @override
  State<AdminFoodFormView> createState() => _AdminFoodFormViewState();
}

class _AdminFoodFormViewState extends State<AdminFoodFormView> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _caloriesCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatCtrl;
  late TextEditingController _servingSizeCtrl;
  
  String _selectedCategory = 'Lauk';
  final List<String> _categories = ['Makanan Pokok', 'Lauk', 'Sayuran', 'Buah', 'Minuman', 'Snack', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    final f = widget.initialFood;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _caloriesCtrl = TextEditingController(text: f?.calories.toString() ?? '');
    _proteinCtrl = TextEditingController(text: f?.protein.toString() ?? '');
    _carbsCtrl = TextEditingController(text: f?.carbs.toString() ?? '');
    _fatCtrl = TextEditingController(text: f?.fat.toString() ?? '');
    _servingSizeCtrl = TextEditingController(text: f?.defaultServingSize.toString() ?? '100');
    if (f != null && _categories.contains(f.category)) {
      _selectedCategory = f.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _servingSizeCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final foodCtrl = context.read<FoodController>();
    
    final newFood = FoodModel(
      id: widget.initialFood?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      calories: double.tryParse(_caloriesCtrl.text) ?? 0,
      protein: double.tryParse(_proteinCtrl.text) ?? 0,
      carbs: double.tryParse(_carbsCtrl.text) ?? 0,
      fat: double.tryParse(_fatCtrl.text) ?? 0,
      defaultServingSize: double.tryParse(_servingSizeCtrl.text) ?? 100,
      isApproved: true,
      createdAt: widget.initialFood?.createdAt ?? DateTime.now(),
    );

    if (widget.initialFood == null) {
      await foodCtrl.addFood(newFood);
    } else {
      await foodCtrl.updateFood(newFood);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialFood != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Makanan' : 'Tambah Makanan Baru'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Informasi Dasar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              NtTextField(
                hint: 'Nama Makanan',
                controller: _nameCtrl,
                validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 24),
              const Text('Nutrisi per 100g', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NtTextField(
                      hint: 'Kalori (kcal)',
                      controller: _caloriesCtrl,
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NtTextField(
                      hint: 'Protein (g)',
                      controller: _proteinCtrl,
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NtTextField(
                      hint: 'Karbo (g)',
                      controller: _carbsCtrl,
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NtTextField(
                      hint: 'Lemak (g)',
                      controller: _fatCtrl,
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              NtTextField(
                hint: 'Porsi Default (g)',
                controller: _servingSizeCtrl,
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 40),
              NtButton(
                label: isEdit ? 'Simpan Perubahan' : 'Tambah Makanan',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
