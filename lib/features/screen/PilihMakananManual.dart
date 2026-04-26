import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'food_database_screen.dart';

class PilihMakananManual extends StatefulWidget {
  const PilihMakananManual({super.key});

  @override
  State<PilihMakananManual> createState() => _PilihMakananManualState();
}

class _PilihMakananManualState extends State<PilihMakananManual> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _servingSizeCtrl = TextEditingController(text: '100');
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  String _selectedUnit = 'gram';
  bool _isSaving = false;

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

  // ── Kalkulasi real-time ──────────────────────────────────
  double get _totalMacrosCal {
    final p = double.tryParse(_proteinCtrl.text) ?? 0;
    final c = double.tryParse(_carbsCtrl.text) ?? 0;
    final f = double.tryParse(_fatCtrl.text) ?? 0;
    return (p * 4) + (c * 4) + (f * 9);
  }

  // ── Save ─────────────────────────────────────────────────
  void _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final item = FoodItem(
      name: _nameCtrl.text.trim(),
      servingSize: double.parse(_servingSizeCtrl.text),
      unit: _selectedUnit,
      calories: double.tryParse(_calCtrl.text) ?? 0,
      protein: double.tryParse(_proteinCtrl.text) ?? 0,
      carbs: double.tryParse(_carbsCtrl.text) ?? 0,
      fat: double.tryParse(_fatCtrl.text) ?? 0,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeaderCard(),
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
            const SizedBox(height: 28),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Tambah Bahan Custom',
        style: TextStyle(
          color: _textDark,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: _borderColor),
      ),
    );
  }

  // ── Header Card ──────────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F8EF), Color(0xFFD0F0E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco_rounded, color: _primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buat Bahan Sendiri',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Masukkan informasi nutrisi per sajian untuk bahan makananmu.',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: _textDark,
      ),
    );
  }

  // ── Name field ───────────────────────────────────────────
  Widget _buildNameField() {
    return _styledField(
      controller: _nameCtrl,
      hint: 'Contoh: Nasi Goreng Spesial',
      icon: Icons.restaurant_menu_rounded,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Nama bahan wajib diisi';
        if (v.trim().length < 2) return 'Nama terlalu pendek';
        return null;
      },
    );
  }

  // ── Serving size row ─────────────────────────────────────
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
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Angka tidak valid';
                  }
                  return null;
                },
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
              _buildUnitDropdown(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textMuted,
          ),
          style: const TextStyle(color: _textDark, fontSize: 14),
          items:
              _units.map((u) {
                return DropdownMenuItem(value: u, child: Text(u));
              }).toList(),
          onChanged: (v) => setState(() => _selectedUnit = v!),
        ),
      ),
    );
  }

  // ── Nutrition section ────────────────────────────────────
  Widget _buildNutritionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart_rounded, color: _primary, size: 18),
            const SizedBox(width: 6),
            const Text(
              'Nutrisi per Sajian',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Semua nilai dalam satuan gram (g)',
          style: TextStyle(color: _textMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        // Kalori full width
        _buildNutrientField(
          label: 'Kalori',
          hint: '0',
          unit: 'kcal',
          controller: _calCtrl,
          color: _calColor,
          icon: Icons.local_fire_department_rounded,
        ),
        const SizedBox(height: 12),
        // Protein & Karbohidrat
        Row(
          children: [
            Expanded(
              child: _buildNutrientField(
                label: 'Protein',
                hint: '0',
                unit: 'g',
                controller: _proteinCtrl,
                color: _proteinColor,
                icon: Icons.fitness_center_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutrientField(
                label: 'Karbohidrat',
                hint: '0',
                unit: 'g',
                controller: _carbsCtrl,
                color: _carbsColor,
                icon: Icons.grain_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Lemak half
        SizedBox(
          width: MediaQuery.of(context).size.width / 2 - 26,
          child: _buildNutrientField(
            label: 'Lemak',
            hint: '0',
            unit: 'g',
            controller: _fatCtrl,
            color: _fatColor,
            icon: Icons.water_drop_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientField({
    required String label,
    required String hint,
    required String unit,
    required TextEditingController controller,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: _textMuted.withOpacity(0.5),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(unit, style: TextStyle(color: _textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Live preview card ────────────────────────────────────
  Widget _buildLivePreview() {
    final cal = double.tryParse(_calCtrl.text) ?? 0;
    final p = double.tryParse(_proteinCtrl.text) ?? 0;
    final c = double.tryParse(_carbsCtrl.text) ?? 0;
    final f = double.tryParse(_fatCtrl.text) ?? 0;
    final hasData = cal > 0 || p > 0 || c > 0 || f > 0;

    return AnimatedOpacity(
      opacity: hasData ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview_rounded, color: _primary, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Preview Bahan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Live',
                    style: TextStyle(
                      color: _primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: _primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameCtrl.text.isEmpty
                            ? 'Nama Bahan...'
                            : _nameCtrl.text,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color:
                              _nameCtrl.text.isEmpty ? _textMuted : _textDark,
                        ),
                      ),
                      Text(
                        '${_servingSizeCtrl.text} $_selectedUnit',
                        style: TextStyle(color: _textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _borderColor),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _previewNutriBadge(
                  '${cal.toStringAsFixed(0)}',
                  'kal',
                  _calColor,
                ),
                _previewNutriBadge(
                  '${p.toStringAsFixed(1)}g',
                  'protein',
                  _proteinColor,
                ),
                _previewNutriBadge(
                  '${c.toStringAsFixed(1)}g',
                  'karbo',
                  _carbsColor,
                ),
                _previewNutriBadge(
                  '${f.toStringAsFixed(1)}g',
                  'lemak',
                  _fatColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewNutriBadge(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Text(label, style: TextStyle(color: _textMuted, fontSize: 11)),
      ],
    );
  }

  // ── Save button ──────────────────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveIngredient,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                _isSaving
                    ? [Colors.grey.shade300, Colors.grey.shade400]
                    : [_primary, _primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              _isSaving
                  ? []
                  : [
                    BoxShadow(
                      color: _primary.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
        ),
        child: Center(
          child:
              _isSaving
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                  : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Simpan Bahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  // ── Generic styled field ─────────────────────────────────
  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(color: _textDark, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textMuted.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: _textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        ),
      ),
    );
  }
}
