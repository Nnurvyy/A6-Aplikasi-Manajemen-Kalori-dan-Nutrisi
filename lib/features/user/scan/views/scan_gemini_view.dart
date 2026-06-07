import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutritrack_app/helpers/app_colors.dart';
import 'package:nutritrack_app/features/user/scan/controllers/scan_gemini_controller.dart';
import './scan_result_detail_view.dart';
import './widgets/cute_loading_widget.dart';
import './widgets/kawaii_apple_painter.dart';
import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'package:nutritrack_app/helpers/subscription_helper.dart';
import 'package:nutritrack_app/features/user/profile/views/premium_upgrade_view.dart';
import 'package:nutritrack_app/features/general/views/ad_screen.dart';

class ScanGeminiView extends StatefulWidget {
  const ScanGeminiView({super.key});

  @override
  State<ScanGeminiView> createState() => _ScanGeminiViewState();
}

class _ScanGeminiViewState extends State<ScanGeminiView> {
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScanGeminiController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (ctrl.isScanning) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CuteLoadingWidget(),
        ),
      );
    }

    if (ctrl.selectedImage == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F0),
        appBar: AppBar(
          title: const Text('Scan Gemini'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: KawaiiApplePainter(),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Pilih Metode Scan',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ambil foto makanan secara langsung menggunakan kamera atau unggah gambar gizi makanan dari galeri.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: _choiceActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Kamera',
                        onTap: () => _handlePickImage(context, ctrl, ImageSource.camera),
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _choiceActionButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeri',
                        onTap: () => _handlePickImage(context, ctrl, ImageSource.gallery),
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Gemini'),
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
          Positioned.fill(
            child: Image.file(
              ctrl.selectedImage!,
              fit: BoxFit.cover,
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

  Widget _buildControlPanel(BuildContext context, ScanGeminiController ctrl, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)
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
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          if (ctrl.selectedImage != null && !ctrl.isScanning && !ctrl.hasResult) ...[
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
                    () => _handlePickImage(context, ctrl, ImageSource.camera),
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
          ],
        ],
      ),
    );
  }

  Future<void> _handlePickImage(BuildContext context, ScanGeminiController ctrl, ImageSource source) async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (!SubscriptionHelper.canScanGemini(user)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Batas Scan Habis', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Batas harian scan makanan gratis Anda telah habis (Maksimal 2 kali sehari).\n\nUpgrade ke Premium sekarang untuk menikmati scan Gemini tanpa batas tanpa iklan!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Nanti Saja', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumUpgradeView()),
                );
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
      return;
    }

    if (SubscriptionHelper.shouldShowAdForGemini(user)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdScreen(durationSeconds: 15),
        ),
      );
    }

    await ctrl.pickImage(source);
    
    if (ctrl.hasResult && ctrl.uniqueMappedFoods.isNotEmpty && context.mounted) {
      if (user != null) {
        SubscriptionHelper.incrementGeminiScanCount(user.id);
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultDetailView(
            food: ctrl.uniqueMappedFoods.first,
            imageFile: ctrl.selectedImage,
            processedImageBytes: ctrl.processedImageBytes,
            initialQuantity: 1, // Gemini scan results are single aggregated food
          ),
        ),
      );
    }
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _choiceActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

