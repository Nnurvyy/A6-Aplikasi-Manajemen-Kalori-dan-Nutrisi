import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../helpers/app_colors.dart';
import 'scan_controller.dart';
import 'scan_result_detail_view.dart';
import 'yolo_painter.dart';
import '../shared/widgets/nt_button.dart';

class ScanFoodView extends StatefulWidget {
  const ScanFoodView({super.key});

  @override
  State<ScanFoodView> createState() => _ScanFoodViewState();
}

class _ScanFoodViewState extends State<ScanFoodView> {
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScanController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Makanan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ─── Image Display & Painter ───
          if (ctrl.selectedImage != null)
            Positioned.fill(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: ctrl.uiImage?.width.toDouble() ?? 640,
                    height: ctrl.uiImage?.height.toDouble() ?? 640,
                    child: Stack(
                      children: [
                        Image.file(ctrl.selectedImage!),
                        if (ctrl.hasResult)
                          CustomPaint(
                            size: Size(
                              ctrl.uiImage?.width.toDouble() ?? 640,
                              ctrl.uiImage?.height.toDouble() ?? 640,
                            ),
                            painter: YoloPainter(
                              detections: ctrl.detections,
                              imageHeight: ctrl.uiImage?.height ?? 640,
                              imageWidth: ctrl.uiImage?.width ?? 640,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            const Positioned.fill(
              child: Center(
                child: Icon(Icons.fastfood_outlined, color: Colors.white12, size: 80),
              ),
            ),

          // ─── Scanning Overlay ───
          if (ctrl.isScanning)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryLight),
                    SizedBox(height: 16),
                    Text('Menganalisis Makanan...', 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // ─── Bottom Panel ───
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildControlPanel(context, ctrl, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, ScanController ctrl, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          if (ctrl.hasResult) ...[
            _resultSummary(ctrl, isDark),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ctrl.clearResult(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Batal', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.normal)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final unique = ctrl.uniqueMappedFoods;
                      if (unique.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScanResultDetailView(
                              food: unique.first,
                              imageFile: ctrl.selectedImage,
                              initialQuantity: ctrl.getFoodCount(unique.first.id),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Simpan Log', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else if (ctrl.selectedImage != null && !ctrl.isScanning) ...[
            const Icon(Icons.search_off_rounded, color: Colors.orange, size: 48),
            const SizedBox(height: 12),
            Text(
              'Mohon maaf untuk makanan ini belum bisa terdeteksi',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sistem kami masih belajar mendeteksi berbagai jenis makanan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    Icons.camera_alt_rounded, 'Coba Lagi', 
                    () => ctrl.pickImage(ImageSource.camera),
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _actionButton(
                    Icons.photo_library_rounded, 'Batal', 
                    () => ctrl.clearResult(),
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text('Scan Makanan', 
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Sistem AI akan menghitung kalori makanan secara otomatis',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    Icons.camera_alt_rounded, 'Kamera', 
                    () => ctrl.pickImage(ImageSource.camera),
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _actionButton(
                    Icons.photo_library_rounded, 'Galeri', 
                    () => ctrl.pickImage(ImageSource.gallery),
                    AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultSummary(ScanController ctrl, bool isDark) {
    final uniqueFoods = ctrl.uniqueMappedFoods;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_outlined, color: AppColors.primaryLight, size: 20),
            const SizedBox(width: 8),
            Text('Hasil Deteksi (${ctrl.mappedFoods.length})', 
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        ...uniqueFoods.map((f) {
           final count = ctrl.getFoodCount(f.id);
           final totalCal = (f.calories * f.defaultServingSize / 100) * count;
           
           return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanResultDetailView(
                      food: f,
                      imageFile: ctrl.selectedImage,
                      initialQuantity: count,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fastfood_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        count > 1 ? '${f.name} x$count' : f.name, 
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)
                      )
                    ),
                    Text('${totalCal.toStringAsFixed(0)} kkal', 
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Estimasi Kalori', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${ctrl.totalCalories.toStringAsFixed(0)} kkal', 
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
