import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/submission_model.dart';

class AddSubmissionScreen extends StatefulWidget {
  const AddSubmissionScreen({super.key});

  @override
  State<AddSubmissionScreen> createState() => _AddSubmissionScreenState();
}

class _AddSubmissionScreenState extends State<AddSubmissionScreen> {
  static const _primary = Color(0xFF2ECC71);
  static const _primaryDark = Color(0xFF27AE60);
  static const _bg = Color(0xFFF4FAF6);
  static const _textDark = Color(0xFF1A2E22);
  static const _textMuted = Color(0xFF7A9485);
  static const _border = Color(0xFFD5EDE0);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  bool _hasImage = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  void _pickImage() {
    setState(() => _hasImage = true);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih foto makanan terlebih dahulu'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final result = SubmissionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'u1',
      userName: 'Nuri',
      foodName: _nameCtrl.text.trim(),
      imagePath: 'assets/placeholder.png',
      calories: double.tryParse(_calCtrl.text),
      protein: double.tryParse(_proteinCtrl.text),
      carbs: double.tryParse(_carbsCtrl.text),
      fat: double.tryParse(_fatCtrl.text),
      createdAt: DateTime.now(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajukan Makanan',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            _label('Nama Makanan'),
            const SizedBox(height: 8),
            _field(
              ctrl: _nameCtrl,
              hint: 'Contoh: Gado-Gado Bandung',
              icon: Icons.fastfood_rounded,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
            ),
            const SizedBox(height: 20),
            _sectionHeader(
              'Perkiraan Nutrisi',
              '(opsional — isi jika kamu tahu)',
            ),
            const SizedBox(height: 12),
            _nutriGrid(),
            const SizedBox(height: 28),
            _buildSubmitButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: _hasImage ? _primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasImage ? _primary : _border,
            width: _hasImage ? 2 : 1.5,
          ),
        ),
        child:
            _hasImage
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _primary,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Foto dipilih (simulasi)',
                      style: TextStyle(color: _primaryDark, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ketuk untuk ganti',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_rounded,
                        color: _primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ketuk untuk tambah foto',
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Format: JPG, PNG  •  Maks. 5MB',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: _textDark,
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Icon(Icons.bar_chart_rounded, color: _primary, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: _textDark,
          ),
        ),
        const SizedBox(width: 6),
        Text(subtitle, style: TextStyle(color: _textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _nutriGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _nutriField(
                ctrl: _calCtrl,
                label: 'Kalori',
                unit: 'kal',
                color: const Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _nutriField(
                ctrl: _proteinCtrl,
                label: 'Protein',
                unit: 'g',
                color: _primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _nutriField(
                ctrl: _carbsCtrl,
                label: 'Karbohidrat',
                unit: 'g',
                color: const Color(0xFFFFB800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _nutriField(
                ctrl: _fatCtrl,
                label: 'Lemak',
                unit: 'g',
                color: const Color(0xFF3498DB),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _nutriField({
    required TextEditingController ctrl,
    required String label,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'opsional',
                    hintStyle: TextStyle(
                      color: _textMuted.withOpacity(0.5),
                      fontSize: 13,
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

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: TextFormField(
        controller: ctrl,
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
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _submit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                _isSaving
                    ? [Colors.grey.shade300, Colors.grey.shade400]
                    : [_primary, _primaryDark],
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
                      Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Kirim Pengajuan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
