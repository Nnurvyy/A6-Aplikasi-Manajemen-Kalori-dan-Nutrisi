import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../general/food/food_controller.dart';
import '../../general/food/models/food_model.dart';

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
  late TextEditingController _descCtrl;

  String _selectedCategory = 'Lauk';
  File? _pickedImage;
  String? _existingImageUrl;

  static const List<String> _categories = [
    'Makanan Pokok', 'Lauk', 'Sayuran', 'Buah', 'Minuman', 'Snack', 'Lainnya'
  ];

  static const Color _primary = Color(0xFF4CAF50);
  static const Color _dark = Color(0xFF1B2A1B);
  static const Color _muted = Color(0xFF5A7A5A);
  static const Color _bg = Color(0xFFF4F6F0);

  @override
  void initState() {
    super.initState();
    final f = widget.initialFood;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _caloriesCtrl = TextEditingController(text: f != null ? f.calories.toStringAsFixed(1) : '');
    _proteinCtrl = TextEditingController(text: f != null ? f.protein.toStringAsFixed(1) : '');
    _carbsCtrl = TextEditingController(text: f != null ? f.carbs.toStringAsFixed(1) : '');
    _fatCtrl = TextEditingController(text: f != null ? f.fat.toStringAsFixed(1) : '');
    _servingSizeCtrl = TextEditingController(text: f?.defaultServingSize.toStringAsFixed(0) ?? '100');
    _descCtrl = TextEditingController(text: f?.description ?? '');
    _existingImageUrl = f?.imageUrl;
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
    _descCtrl.dispose();
    super.dispose();
  }

  Color get _categoryColor {
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Pilih Sumber Foto', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_rounded, color: _primary),
              ),
              title: Text('Kamera', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text('Ambil foto langsung', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (img != null) setState(() => _pickedImage = File(img.path));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library_rounded, color: Colors.blue),
              ),
              title: Text('Galeri', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text('Pilih dari galeri foto', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (img != null) setState(() => _pickedImage = File(img.path));
              },
            ),
            if (_pickedImage != null || _existingImageUrl != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                ),
                title: Text('Hapus Foto', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _pickedImage = null;
                    _existingImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final foodCtrl = context.read<FoodController>();

    String? imageUrl = _existingImageUrl;
    if (_pickedImage != null) {
      imageUrl = _pickedImage!.path;
    }

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
      imageUrl: imageUrl,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
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
    final catColor = _categoryColor;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Header ───
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
                onPressed: _save,
                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Simpan',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image / Placeholder
                  if (_pickedImage != null)
                    Image.file(_pickedImage!, fit: BoxFit.cover)
                  else if (_existingImageUrl != null)
                    Image.network(
                      _existingImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(catColor),
                    )
                  else
                    _buildImagePlaceholder(catColor),

                  // Dark overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          catColor.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),

                  // Camera button
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _pickedImage != null || _existingImageUrl != null
                                  ? Icons.edit_rounded
                                  : Icons.add_a_photo_rounded,
                              color: catColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _pickedImage != null || _existingImageUrl != null ? 'Ganti Foto' : 'Tambah Foto',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: catColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Title label at the bottom
                  Positioned(
                    left: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isEdit ? 'Edit Makanan' : 'Tambah Makanan Baru',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _nameCtrl.text.isEmpty ? 'Nama Makanan...' : _nameCtrl.text,
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Form Body ───
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Basic Info Card
                  _buildSectionCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Informasi Dasar',
                    child: Column(
                      children: [
                        _buildField(
                          controller: _nameCtrl,
                          label: 'Nama Makanan',
                          icon: Icons.restaurant_menu_rounded,
                          onChanged: (_) => setState(() {}),
                          validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryPicker(),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _descCtrl,
                          label: 'Deskripsi (opsional)',
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  // Nutrition Card
                  _buildSectionCard(
                    icon: Icons.science_outlined,
                    title: 'Nutrisi per 100g',
                    subtitle: 'Semua nilai dihitung per 100 gram',
                    child: Column(
                      children: [
                        // Calories full width with highlight
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [catColor.withValues(alpha: 0.08), catColor.withValues(alpha: 0.04)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: catColor.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.local_fire_department_rounded, color: catColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _caloriesCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _dark),
                                  decoration: InputDecoration(
                                    labelText: 'Kalori (kcal)',
                                    labelStyle: GoogleFonts.poppins(fontSize: 13, color: catColor),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                                ),
                              ),
                              Text('kcal', style: GoogleFonts.poppins(fontSize: 12, color: _muted, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildNutriField(
                              controller: _proteinCtrl,
                              label: 'Protein',
                              unit: 'g',
                              icon: Icons.fitness_center_rounded,
                              color: const Color(0xFFE53935),
                              bgColor: const Color(0xFFFFEBEE),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _buildNutriField(
                              controller: _carbsCtrl,
                              label: 'Karbohidrat',
                              unit: 'g',
                              icon: Icons.grain_rounded,
                              color: const Color(0xFFF59E0B),
                              bgColor: const Color(0xFFFFF8E1),
                            )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildNutriField(
                              controller: _fatCtrl,
                              label: 'Lemak',
                              unit: 'g',
                              icon: Icons.opacity_rounded,
                              color: const Color(0xFFFF8C00),
                              bgColor: const Color(0xFFFFF3E0),
                            )),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildNutriField(
                                controller: _servingSizeCtrl,
                                label: 'Porsi Default',
                                unit: 'g',
                                icon: Icons.scale_rounded,
                                color: const Color(0xFF1E88E5),
                                bgColor: const Color(0xFFE3F2FD),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Live preview card
                  _buildPreviewCard(catColor),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.fastfood_rounded, size: 80, color: Colors.white.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
                  if (subtitle != null)
                    Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: _dark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: _muted),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildNutriField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _dark),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: GoogleFonts.poppins(color: _muted.withValues(alpha: 0.5), fontSize: 16),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                ),
              ),
              Text(unit, style: GoogleFonts.poppins(fontSize: 12, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: GoogleFonts.poppins(fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            Color catColor;
            switch (cat.toLowerCase()) {
              case 'lauk': catColor = const Color(0xFF4CAF50); break;
              case 'makanan pokok': catColor = const Color(0xFFF59E0B); break;
              case 'sayuran': catColor = const Color(0xFF43A047); break;
              case 'buah': catColor = const Color(0xFFE91E63); break;
              case 'minuman': catColor = const Color(0xFF1E88E5); break;
              case 'snack': catColor = const Color(0xFF9C27B0); break;
              default: catColor = const Color(0xFF78909C);
            }
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? catColor : catColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: catColor.withValues(alpha: isSelected ? 1 : 0.3)),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : catColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(Color catColor) {
    final cal = double.tryParse(_caloriesCtrl.text) ?? 0;
    final prot = double.tryParse(_proteinCtrl.text) ?? 0;
    final carb = double.tryParse(_carbsCtrl.text) ?? 0;
    final fat = double.tryParse(_fatCtrl.text) ?? 0;
    final serv = double.tryParse(_servingSizeCtrl.text) ?? 100;

    // Calculate for serving size
    final ratio = serv / 100;
    final calServ = cal * ratio;
    final protServ = prot * ratio;
    final carbServ = carb * ratio;
    final fatServ = fat * ratio;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [catColor.withValues(alpha: 0.1), catColor.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: catColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview_rounded, color: catColor, size: 18),
              const SizedBox(width: 8),
              Text('Preview per Porsi (${serv.toInt()}g)',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: catColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _previewStat('${calServ.toInt()}', 'kcal', Icons.local_fire_department_rounded, catColor),
              _previewStat('${protServ.toStringAsFixed(1)}g', 'Protein', Icons.fitness_center_rounded, const Color(0xFFE53935)),
              _previewStat('${carbServ.toStringAsFixed(1)}g', 'Karbo', Icons.grain_rounded, const Color(0xFFF59E0B)),
              _previewStat('${fatServ.toStringAsFixed(1)}g', 'Lemak', Icons.opacity_rounded, const Color(0xFFFF8C00)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _dark)),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: _muted)),
      ],
    );
  }
}
