import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import './submission_controller.dart';

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

  File? _imageFile;
  bool _isSaving = false;
  double _uploadProgress = 0; // 0.0 – 1.0
  String _uploadStatus = ''; // teks keterangan progress

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Pick image dengan kualitas & ukuran dibatasi langsung dari image_picker ──

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: _primary,
                  ),
                  title: const Text('Ambil Foto'),
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 60, // turun dari 80 → 60
                      maxWidth: 1024, // resize lebar max 1024px
                      maxHeight: 1024, // resize tinggi max 1024px
                    );
                    if (picked != null) {
                      setState(() => _imageFile = File(picked.path));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: _primary,
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 60, // turun dari 80 → 60
                      maxWidth: 1024,
                      maxHeight: 1024,
                    );
                    if (picked != null) {
                      setState(() => _imageFile = File(picked.path));
                    }
                  },
                ),
                if (_imageFile != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Hapus Foto',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _imageFile = null);
                    },
                  ),
              ],
            ),
          ),
    );
  }

  // ── Submit: optimistic UI — langsung kembali ke list, upload jalan di background ──

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
      _uploadProgress = 0;
      _uploadStatus = 'Menyiapkan pengajuan...';
    });

    try {
      // Tahap 1 — persiapan (cepat)
      setState(() {
        _uploadProgress = 0.1;
        _uploadStatus = 'Memproses foto...';
      });

      await Future.delayed(const Duration(milliseconds: 300));

      // Tahap 2 — panggil controller (upload berjalan di background)
      setState(() {
        _uploadProgress = 0.3;
        _uploadStatus = 'Mengirim ke server...';
      });

      // addSubmission sekarang pakai optimistic UI:
      // item langsung muncul di list dengan isSynced=false,
      // lalu upload Storage + Firestore jalan di background.
      // Kita tidak perlu await sampai selesai — cukup kick off lalu pop.
      final ctrl = context.read<SubmissionController>();

      // Jalankan tanpa await — upload jalan di background
      ctrl.addSubmission(
        userId: user.id,
        userName: user.name,
        foodName: _nameCtrl.text.trim(),
        localImagePath: _imageFile!.path ?? '',
      );

      // Langsung update progress ke "selesai" dan keluar
      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Pengajuan dikirim!';
      });

      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pengajuan dikirim! Foto sedang diupload di background.',
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _isSaving = false;
          _uploadProgress = 0;
          _uploadStatus = '';
        });
      }
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
          onPressed: _isSaving ? null : () => Navigator.pop(context),
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
      body: Stack(
        children: [
          Form(
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2E7D32),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Data nutrisi akan diisi oleh ahli gizi setelah '
                          'pengajuanmu disetujui admin.',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _buildSubmitButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Overlay progress saat saving ──
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ikon animasi
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_rounded,
                          color: _primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _uploadStatus,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          minHeight: 8,
                          backgroundColor: _primary.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: TextStyle(color: _textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Foto diupload di background,\nkamu bisa lanjut aktivitas.',
                        style: TextStyle(color: _textMuted, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _isSaving ? null : _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: _imageFile != null ? _primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _imageFile != null ? _primary : _border,
            width: _imageFile != null ? 2 : 1.5,
          ),
        ),
        child:
            _imageFile != null
                ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _imageFile!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Info ukuran file
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: FutureBuilder<int>(
                        future: _imageFile!.length(),
                        builder: (_, snap) {
                          if (!snap.hasData) return const SizedBox();
                          final kb = snap.data! / 1024;
                          final label =
                              kb > 1024
                                  ? '${(kb / 1024).toStringAsFixed(1)} MB'
                                  : '${kb.toStringAsFixed(0)} KB';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Ganti',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      'Ketuk untuk tambah foto (Opsional)',
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Otomatis dikompres sebelum dikirim',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: _textDark,
    ),
  );

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
