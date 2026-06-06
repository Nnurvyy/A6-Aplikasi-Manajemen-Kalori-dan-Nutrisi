import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'package:nutritrack_app/features/general/food/controllers/food_controller.dart';
import 'package:nutritrack_app/features/user/scan/controllers/scan_nutritional_information_controller.dart';

class ScanNutritionalInformationView extends StatefulWidget {
  const ScanNutritionalInformationView({super.key});

  @override
  State<ScanNutritionalInformationView> createState() => _ScanNutritionalInformationViewState();
}

class _ScanNutritionalInformationViewState extends State<ScanNutritionalInformationView> {
  final _formKey = GlobalKey<FormState>();

  void _saveToHistory(ScanNutritionalInformationController ctrl) async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) return;

    final foodCtrl = context.read<FoodController>();

    final success = await ctrl.saveToHistory(
      userId: userId,
      foodController: foodCtrl,
      context: context,
    );

    if (success && mounted) {
      final foodName = ctrl.nameCtrl.text.trim();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$foodName berhasil disimpan ke riwayat!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan ke riwayat'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScanNutritionalInformationController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Pindai Nilai Gizi', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ctrl.isProcessing && ctrl.processedImage == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  const SizedBox(height: 16),
                  Text(ctrl.statusText, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ],
              ),
            )
          : ctrl.originalImage == null
              ? _buildInitialSelection(ctrl)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Area
                      GestureDetector(
                        onTap: () => _showMaximizedImage(ctrl),
                        child: Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD5EDE0), width: 2),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ctrl.processedImage != null
                                    ? CustomPaint(
                                        foregroundPainter: ctrl.imageSize != null
                                            ? HighlightPainter(ctrl.highlightRects, ctrl.imageSize!)
                                            : null,
                                        child: Image.file(ctrl.processedImage!, fit: BoxFit.contain),
                                      )
                                    : Image.file(ctrl.originalImage!, fit: BoxFit.contain),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                                  child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => ctrl.pickAndProcessImage(ImageSource.camera, context),
                              icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                              label: const Text('Foto Ulang', style: TextStyle(color: Colors.white, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => ctrl.pickAndProcessImage(ImageSource.gallery, context),
                              icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF2E7D32), size: 18),
                              label: const Text('Galeri', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF2E7D32)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (ctrl.processedImage != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD5EDE0)),
                            boxShadow: [
                              BoxShadow(color: Colors.green.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hasil Scan (Periksa & Edit)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22))),
                                const SizedBox(height: 16),
                                _buildInputField('Nama Makanan / Minuman', ctrl.nameCtrl, Icons.restaurant, true),
                                const SizedBox(height: 12),
                                _buildInputField('Takaran Saji (Gram)', ctrl.servingSizeCtrl, Icons.scale, true, isNumber: true),
                                const Divider(height: 32),
                                Row(
                                  children: [
                                    Expanded(child: _buildInputField('Kalori (kcal)', ctrl.calCtrl, Icons.local_fire_department, false, isNumber: true, color: Colors.orange)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildInputField('Protein (g)', ctrl.proteinCtrl, Icons.fitness_center, false, isNumber: true, color: Colors.red)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildInputField('Karbo (g)', ctrl.carbsCtrl, Icons.grain, false, isNumber: true, color: Colors.amber)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildInputField('Lemak (g)', ctrl.fatCtrl, Icons.water_drop, false, isNumber: true, color: Colors.orange)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: ctrl.isProcessing ? null : () => _saveToHistory(ctrl),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: ctrl.isProcessing
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Simpan ke Riwayat', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInitialSelection(ScanNutritionalInformationController ctrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.document_scanner_rounded, size: 80, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 40),
            const Text(
              'Pilih Metode Pindai',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Anda bisa memindai Informasi Nilai Gizi secara langsung atau melalui gambar di galeri.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSquareSelectionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  color: const Color(0xFF2E7D32),
                  onTap: () => ctrl.pickAndProcessImage(ImageSource.camera, context),
                ),
                _buildSquareSelectionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  color: Colors.blue,
                  onTap: () => ctrl.pickAndProcessImage(ImageSource.gallery, context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareSelectionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  void _showMaximizedImage(ScanNutritionalInformationController ctrl) {
    if (ctrl.processedImage == null && ctrl.originalImage == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.black.withValues(alpha: 0.9)),
              ),
            ),
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ctrl.processedImage != null
                    ? CustomPaint(
                        foregroundPainter: ctrl.imageSize != null
                            ? HighlightPainter(ctrl.highlightRects, ctrl.imageSize!)
                            : null,
                        child: Image.file(ctrl.processedImage!),
                      )
                    : Image.file(ctrl.originalImage!),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, bool required, {bool isNumber = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF5A7A5A))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: !isNumber && label != 'Nama Makanan / Minuman' && label != 'Takaran Saji (Gram)',
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          validator: required ? (v) => v == null || v.isEmpty ? 'Wajib diisi' : null : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: color ?? const Color(0xFF2E7D32)),
            filled: true,
            fillColor: const Color(0xFFF4F6F0),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class HighlightPainter extends CustomPainter {
  final List<Rect> rects;
  final Size imageSize;

  HighlightPainter(this.rects, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (rects.isEmpty) return;

    // Use fit: BoxFit.contain logic
    double imgRatio = imageSize.width / imageSize.height;
    double canvasRatio = size.width / size.height;

    double renderWidth = size.width;
    double renderHeight = size.height;
    double offsetX = 0;
    double offsetY = 0;

    if (imgRatio > canvasRatio) {
      renderHeight = size.width / imgRatio;
      offsetY = (size.height - renderHeight) / 2;
    } else {
      renderWidth = size.height * imgRatio;
      offsetX = (size.width - renderWidth) / 2;
    }

    final double activeScale = renderWidth / imageSize.width;

    final paint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (var rect in rects) {
      final scaledRect = Rect.fromLTWH(
        (rect.left * activeScale) + offsetX,
        (rect.top * activeScale) + offsetY,
        rect.width * activeScale,
        rect.height * activeScale,
      );
      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) {
    return oldDelegate.rects != rects || oldDelegate.imageSize != imageSize;
  }
}
