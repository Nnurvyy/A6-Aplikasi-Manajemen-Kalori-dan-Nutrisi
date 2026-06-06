import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nutritrack_app/features/general/food/controllers/food_controller.dart';
import 'package:nutritrack_app/features/general/food/models/food_model.dart';
import 'package:nutritrack_app/features/general/food/views/widgets/ingredient_picker_dialog.dart';
import 'package:nutritrack_app/features/user/manual_food/views/manual_ingredient_input_page.dart';
import 'package:nutritrack_app/features/general/submission/controllers/submission_controller.dart';
import 'package:nutritrack_app/features/general/submission/models/submission_model.dart';
import 'package:nutritrack_app/features/general/submission/views/widgets/submission_image_widget.dart';
import 'dart:convert';

class NutriFoodFormView extends StatefulWidget {
  final SubmissionModel item;
  const NutriFoodFormView({super.key, required this.item});

  @override
  State<NutriFoodFormView> createState() => _NutriFoodFormViewState();
}

class _NutriFoodFormViewState extends State<NutriFoodFormView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _caloriesCtrl;   // total for the serving
  late TextEditingController _proteinCtrl;    // total for the serving
  late TextEditingController _carbsCtrl;      // total for the serving
  late TextEditingController _fatCtrl;        // total for the serving
  late TextEditingController _servingSizeCtrl;
  late TextEditingController _descCtrl;

  String _selectedCategory = 'Lauk';
  List<Map<String, dynamic>> _ingredients = [];
  bool _saving = false;

  static const List<String> _categories = [
    'Makanan Pokok', 'Lauk', 'Sayuran', 'Buah', 'Minuman', 'Snack', 'Lainnya'
  ];

  static const Color _primary = Color(0xFF2E7D32);
  static const Color _dark = Color(0xFF1B2A1B);
  static const Color _muted = Color(0xFF5A7A5A);
  static const Color _bg = Color(0xFFF4F6F0);

  @override
  void initState() {
    super.initState();
    final s = widget.item;
    _nameCtrl = TextEditingController(text: s.foodName);
    _descCtrl = TextEditingController(text: s.nutriNote ?? '');

    // If already has nutritional info (editing a completed submission), 
    // it's stored as per-100g. Default serving size to 100g so total = per-100g.
    if (s.isNutriFilled) {
      _servingSizeCtrl = TextEditingController(text: '100');
      _caloriesCtrl = TextEditingController(text: s.calories?.toStringAsFixed(0) ?? '');
      _proteinCtrl  = TextEditingController(text: s.protein?.toStringAsFixed(1) ?? '');
      _carbsCtrl    = TextEditingController(text: s.carbs?.toStringAsFixed(1) ?? '');
      _fatCtrl      = TextEditingController(text: s.fat?.toStringAsFixed(1) ?? '');
    } else {
      _servingSizeCtrl = TextEditingController(text: '100');
      _caloriesCtrl = TextEditingController();
      _proteinCtrl  = TextEditingController();
      _carbsCtrl    = TextEditingController();
      _fatCtrl      = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _caloriesCtrl, _proteinCtrl, _carbsCtrl, _fatCtrl, _servingSizeCtrl, _descCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Color get _catColor {
    switch (_selectedCategory.toLowerCase()) {
      case 'lauk': return const Color(0xFF4CAF50);
      case 'makanan pokok': return const Color(0xFFF59E0B);
      case 'sayuran': return const Color(0xFF43A047);
      case 'buah': return const Color(0xFFE91E63);
      case 'minuman': return const Color(0xFF1E88E5);
      case 'snack': return const Color(0xFF9C27B0);
      default: return const Color(0xFF78909C);
    }
  }

  void _showImageViewer(BuildContext ctx, String imagePath) {
    if (imagePath.isEmpty) return;
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => _ImageViewerPage(imagePath: imagePath)),
    );
  }

  // ─── INGREDIENT OPTIONS BOTTOM SHEET (2 pilihan) ──────────────────────────

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tambah Bahan Dari', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 20),
            _optionTile(
              ctx: ctx,
              icon: Icons.search_rounded,
              color: Colors.blue,
              title: 'Database Makanan',
              subtitle: 'Cari dari 1000+ data makanan',
              onTap: () async {
                Navigator.pop(ctx);
                final result = await showDialog(
                  context: context,
                  builder: (d) => const IngredientPickerDialog(),
                );
                _handleIngredientResult(result);
              },
            ),
            const SizedBox(height: 12),
            _optionTile(
              ctx: ctx,
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
                _handleIngredientResult(result);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({required BuildContext ctx, required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD5EDE0))),
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
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: _dark)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _muted.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  void _handleIngredientResult(dynamic result) {
    if (result == null || result is! Map) return;
    if (result['isManual'] == true) {
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
      final food = result['food'] as FoodModel;
      final grams = result['grams'] as double;
      final nutri = food.nutritionForAmount(grams);
      setState(() {
        _ingredients.add({
          'id': food.id,
          'name': food.name,
          'grams': grams,
          'calories': nutri['calories'],
          'protein': nutri['protein'],
          'carbs': nutri['carbs'],
          'fat': nutri['fat'],
        });
      });
    }
    _calculateFromIngredients();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final serv = double.tryParse(_servingSizeCtrl.text) ?? 100;
    final ratio = serv > 0 ? 100 / serv : 1.0;

    final calTotal  = double.tryParse(_caloriesCtrl.text) ?? 0;
    final protTotal = double.tryParse(_proteinCtrl.text)  ?? 0;
    final carbTotal = double.tryParse(_carbsCtrl.text)    ?? 0;
    final fatTotal  = double.tryParse(_fatCtrl.text)      ?? 0;

    // Convert total values back to per-100g for storage
    final calPer100  = calTotal * ratio;
    final protPer100 = protTotal * ratio;
    final carbPer100 = carbTotal * ratio;
    final fatPer100  = fatTotal * ratio;

    setState(() => _saving = true);

    try {
      // 1. Save nutrition details in the submission
      await context.read<SubmissionController>().saveNutriData(
        id: widget.item.id,
        foodName: name,
        calories: calPer100,
        protein: protPer100,
        carbs: carbPer100,
        fat: fatPer100,
        nutriNote: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );

      // 2. Add the food item to the universal database
      final newFood = FoodModel(
        id: 'food_sub_${widget.item.id}', // Predictable ID to avoid duplicates
        name: name,
        category: _selectedCategory,
        calories: calPer100,
        protein: protPer100,
        carbs: carbPer100,
        fat: fatPer100,
        defaultServingSize: serv,
        isApproved: true,
        createdAt: DateTime.now(),
        imageUrl: widget.item.imagePath.isNotEmpty ? widget.item.imagePath : null,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        ingredientsJson: _ingredients.isEmpty ? null : jsonEncode(_ingredients),
      );

      await context.read<FoodController>().addFood(newFood);

      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data nutrisi "$name" disimpan ke database universal!',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item.isNutriFilled;
    final catColor = _catColor;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Header ───────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: catColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving 
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                label: Text('Simpan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image / placeholder with tap to zoom
                  if (widget.item.imagePath.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showImageViewer(context, widget.item.imagePath),
                      child: SubmissionImage(
                        imagePath: widget.item.imagePath,
                        fit: BoxFit.cover,
                        placeholder: _placeholder(catColor),
                      ),
                    )
                  else
                    _placeholder(catColor),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, catColor.withValues(alpha: 0.85)],
                      ),
                    ),
                  ),

                  // Zoom Hint
                  if (widget.item.imagePath.isNotEmpty)
                    Positioned(
                      bottom: 16, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Ketuk untuk perbesar',
                              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Name preview at bottom left
                  Positioned(
                    left: 20, bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text(isEdit ? 'Edit Data Nutrisi' : 'Isi Data Nutrisi Baru', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _nameCtrl.text.isEmpty ? 'Nama Makanan...' : _nameCtrl.text,
                          style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Form Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Info dasar
                  _sectionCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Informasi Dasar',
                    child: Column(
                      children: [
                        _field(controller: _nameCtrl, label: 'Nama Makanan', icon: Icons.restaurant_menu_rounded,
                          onChanged: (_) => setState(() {}),
                          validator: (v) => (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null),
                        const SizedBox(height: 14),
                        _categoryPicker(),
                        const SizedBox(height: 14),
                        _field(controller: _descCtrl, label: 'Deskripsi / Catatan (opsional)', icon: Icons.notes_rounded, maxLines: 2),
                      ],
                    ),
                  ),

                  // Nutrisi
                  _sectionCard(
                    icon: Icons.science_outlined,
                    title: 'Berat & Nutrisi',
                    subtitle: 'Input nilai aktual untuk porsi yang ditentukan',
                    child: Column(
                      children: [
                        // Serving size — full width, highlighted
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: catColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.scale_rounded, color: catColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _servingSizeCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _dark),
                                  decoration: InputDecoration(
                                    labelText: 'Berat Porsi',
                                    labelStyle: GoogleFonts.poppins(fontSize: 12, color: catColor),
                                    border: InputBorder.none, isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  readOnly: _ingredients.isNotEmpty,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                                ),
                              ),
                              Text('gram', style: GoogleFonts.poppins(fontSize: 13, color: catColor, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Calories — full width
                        _nutriField(controller: _caloriesCtrl, label: 'Kalori', unit: 'kcal',
                          icon: Icons.local_fire_department_rounded, color: catColor, bgColor: catColor.withValues(alpha: 0.07), fullWidth: true),
                        const SizedBox(height: 10),

                        // Protein + Karbo side by side
                        Row(
                          children: [
                            Expanded(child: _nutriField(controller: _proteinCtrl, label: 'Protein', unit: 'g',
                              icon: Icons.fitness_center_rounded, color: const Color(0xFFE53935), bgColor: const Color(0xFFFFEBEE))),
                            const SizedBox(width: 10),
                            Expanded(child: _nutriField(controller: _carbsCtrl, label: 'Karbohidrat', unit: 'g',
                              icon: Icons.grain_rounded, color: const Color(0xFFF59E0B), bgColor: const Color(0xFFFFF8E1))),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Lemak full width
                        _nutriField(controller: _fatCtrl, label: 'Lemak', unit: 'g',
                          icon: Icons.opacity_rounded, color: const Color(0xFFFF8C00), bgColor: const Color(0xFFFFF3E0), fullWidth: true),
                      ],
                    ),
                  ),

                  // Komposisi Bahan
                  _sectionCard(
                    icon: Icons.kitchen_rounded,
                    title: 'Komposisi Bahan (Opsional)',
                    subtitle: 'Tambah bahan untuk menghitung nutrisi',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showIngredientOptions(context),
                          icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          label: Text('Tambah Bahan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                        if (_ingredients.isNotEmpty) const SizedBox(height: 12),
                        if (_ingredients.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD5EDE0), width: 2),
                              boxShadow: [
                                BoxShadow(color: _primary.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _ingredients.length,
                              separatorBuilder: (_, __) => const Divider(color: Color(0xFFD5EDE0), height: 1),
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
                                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: _dark),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${(item['grams'] as num).round()}g • ${(item['calories'] as num).round()} kcal',
                                              style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                _smallNutriChip('P ${(item['protein'] as num?)?.round() ?? 0}g', const Color(0xFFFFEBEE), const Color(0xFFE53935)),
                                                const SizedBox(width: 4),
                                                _smallNutriChip('K ${(item['carbs'] as num?)?.round() ?? 0}g', const Color(0xFFFFF8E1), const Color(0xFFF59E0B)),
                                                const SizedBox(width: 4),
                                                _smallNutriChip('L ${(item['fat'] as num?)?.round() ?? 0}g', const Color(0xFFFFF3E0), const Color(0xFFFF8C00)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      _ingredientActionBtn(
                                        icon: Icons.edit_note_rounded,
                                        color: Colors.blue,
                                        onTap: () => _editIngredient(idx),
                                      ),
                                      const SizedBox(width: 8),
                                      _ingredientActionBtn(
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
                    ),
                  ),

                  // Live preview
                  _previewCard(catColor),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _placeholder(Color color) => Container(
    decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Center(child: Icon(Icons.fastfood_rounded, size: 70, color: Colors.white.withValues(alpha: 0.4))),
  );

  Widget _sectionCard({required IconData icon, required String title, String? subtitle, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: _primary, size: 17)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                  if (subtitle != null) Text(subtitle, style: GoogleFonts.poppins(fontSize: 10, color: _muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _field({required TextEditingController controller, required String label, required IconData icon,
    TextInputType? keyboardType, String? Function(String?)? validator, int? maxLines, void Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: _dark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: _muted),
        prefixIcon: Icon(icon, color: _primary, size: 19),
        filled: true, fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      validator: validator,
    );
  }

  Widget _nutriField({required TextEditingController controller, required String label,
    required String unit, required IconData icon, required Color color, required Color bgColor, bool fullWidth = false}) {
    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(13), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _dark),
                  decoration: InputDecoration(
                    border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                    hintText: '0', hintStyle: GoogleFonts.poppins(color: _muted.withValues(alpha: 0.4), fontSize: 15),
                  ),
                  readOnly: _ingredients.isNotEmpty,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                ),
              ],
            ),
          ),
          Text(unit, style: GoogleFonts.poppins(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
        ],
      ),
    );
    return fullWidth ? inner : inner;
  }

  Widget _categoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: GoogleFonts.poppins(fontSize: 11, color: _muted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            Color cc;
            switch (cat.toLowerCase()) {
              case 'lauk': cc = const Color(0xFF4CAF50); break;
              case 'makanan pokok': cc = const Color(0xFFF59E0B); break;
              case 'sayuran': cc = const Color(0xFF43A047); break;
              case 'buah': cc = const Color(0xFFE91E63); break;
              case 'minuman': cc = const Color(0xFF1E88E5); break;
              case 'snack': cc = const Color(0xFF9C27B0); break;
              default: cc = const Color(0xFF78909C);
            }
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? cc : cc.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cc.withValues(alpha: isSelected ? 1 : 0.3)),
                ),
                child: Text(cat, style: GoogleFonts.poppins(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : cc)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _previewCard(Color catColor) {
    final cal  = double.tryParse(_caloriesCtrl.text) ?? 0;
    final prot = double.tryParse(_proteinCtrl.text)  ?? 0;
    final carb = double.tryParse(_carbsCtrl.text)    ?? 0;
    final fat  = double.tryParse(_fatCtrl.text)      ?? 0;
    final serv = double.tryParse(_servingSizeCtrl.text) ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [catColor.withValues(alpha: 0.10), catColor.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: catColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview_rounded, color: catColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'Preview — ${serv > 0 ? "${serv.toInt()}g" : "? g"} porsi',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: catColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _prevStat('${cal.round()}', 'kcal', Icons.local_fire_department_rounded, catColor),
              _prevStat('${prot.round()}g', 'Protein', Icons.fitness_center_rounded, const Color(0xFFE53935)),
              _prevStat('${carb.round()}g', 'Karbo', Icons.grain_rounded, const Color(0xFFF59E0B)),
              _prevStat('${fat.round()}g', 'Lemak', Icons.opacity_rounded, const Color(0xFFFF8C00)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prevStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _dark)),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: _muted)),
      ],
    );
  }

  Widget _smallNutriChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _ingredientActionBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
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

  void _editIngredient(int idx) {
    final item = _ingredients[idx];
    final nameCtrl = TextEditingController(text: item['name'].toString());
    final gramCtrl = TextEditingController(text: (item['grams'] as num).round().toString());
    final calCtrl  = TextEditingController(text: (item['calories'] as num).round().toString());
    final proCtrl  = TextEditingController(text: ((item['protein'] as num?)?.round() ?? 0).toString());
    final carbCtrl = TextEditingController(text: ((item['carbs'] as num?)?.round() ?? 0).toString());
    final fatCtrl  = TextEditingController(text: ((item['fat'] as num?)?.round() ?? 0).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: _primary),
            const SizedBox(width: 10),
            Text('Edit Bahan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(label: 'Nama Bahan', ctrl: nameCtrl, icon: Icons.drive_file_rename_outline),
              const SizedBox(height: 12),
              _dialogField(label: 'Jumlah (g)', ctrl: gramCtrl, icon: Icons.scale, isNum: true),
              const SizedBox(height: 12),
              _dialogField(label: 'Kalori (kcal)', ctrl: calCtrl, icon: Icons.local_fire_department, isNum: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dialogField(label: 'Protein (g)', ctrl: proCtrl, icon: Icons.fitness_center, isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _dialogField(label: 'Karbo (g)', ctrl: carbCtrl, icon: Icons.grain, isNum: true)),
                ],
              ),
              const SizedBox(height: 12),
              _dialogField(label: 'Lemak (g)', ctrl: fatCtrl, icon: Icons.water_drop, isNum: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.poppins(color: _muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              final g = double.tryParse(gramCtrl.text) ?? 0;
              if (nameCtrl.text.trim().isNotEmpty && g > 0) {
                setState(() {
                  _ingredients[idx] = {
                    ...item,
                    'name': nameCtrl.text.trim(),
                    'grams': g,
                    'calories': double.tryParse(calCtrl.text) ?? 0,
                    'protein': double.tryParse(proCtrl.text) ?? 0,
                    'carbs': double.tryParse(carbCtrl.text) ?? 0,
                    'fat': double.tryParse(fatCtrl.text) ?? 0,
                  };
                });
                _calculateFromIngredients();
                Navigator.pop(ctx);
              }
            },
            child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField({required String label, required TextEditingController ctrl, required IconData icon, bool isNum = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: GoogleFonts.poppins(fontSize: 14, color: _dark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: _muted),
        prefixIcon: Icon(icon, size: 18, color: _primary),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  void _calculateFromIngredients() {
    if (_ingredients.isEmpty) {
      if (_servingSizeCtrl.text == '0') _servingSizeCtrl.text = '100';
      _caloriesCtrl.clear();
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
      totalGrams += ing['grams'];
    }
    _servingSizeCtrl.text = totalGrams.round().toString();
    _caloriesCtrl.text = cal.round().toString();
    _proteinCtrl.text = pro.round().toString();
    _carbsCtrl.text = car.round().toString();
    _fatCtrl.text = fat.round().toString();
  }
}

// ─── Fullscreen Image Viewer ──────────────────────────────────────────────────
class _ImageViewerPage extends StatelessWidget {
  final String imagePath;
  const _ImageViewerPage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Foto Makanan',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: SubmissionImage(
            imagePath: imagePath,
            fit: BoxFit.contain,
            placeholder: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 64,
                ),
                SizedBox(height: 12),
                Text(
                  'Foto tidak dapat ditampilkan',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
