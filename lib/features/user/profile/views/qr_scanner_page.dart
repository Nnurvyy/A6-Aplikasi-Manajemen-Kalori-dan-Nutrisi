import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isFound = false;
  bool _isAnalyzing = false;
  bool _showCamera = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scanFromGallery() async {
    if (_isAnalyzing) return;
    
    // Pastikan kamera mati jika sedang aktif
    if (_showCamera) await _controller.stop();

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // Pastikan kualitas terbaik agar QR tidak buram
    );
    
    if (image != null) {
      setState(() => _isAnalyzing = true);
      try {
        final inputImage = mlkit.InputImage.fromFilePath(image.path);
        final barcodeScanner = mlkit.BarcodeScanner(); 
        
        final List<mlkit.Barcode> barcodes = await barcodeScanner.processImage(inputImage);
        
        String? foundValue;
        for (mlkit.Barcode barcode in barcodes) {
          if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
            foundValue = barcode.rawValue!.trim();
            break;
          }
        }
        
        await barcodeScanner.close();

        if (foundValue != null) {
          _isFound = true;
          if (mounted) {
            Navigator.pop(context, foundValue);
          }
          return;
        }
        
        if (mounted && !_isFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ditemukan QR Code yang valid pada gambar tersebut.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menganalisis gambar: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isAnalyzing = false);
      }
    }

    // Nyalakan kembali kamera jika tadinya aktif
    if (!_isFound && _showCamera) {
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        title: const Text('Pindai QR Anak'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_showCamera)
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_isFound) return;
                for (final barcode in capture.barcodes) {
                  if (barcode.rawValue != null) {
                    _isFound = true;
                    Navigator.pop(context, barcode.rawValue);
                    break;
                  }
                }
              },
            )
          else
            _buildChoiceUI(),

          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Menganalisis QR...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChoiceUI() {
    return Center(
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
              child: const Icon(Icons.qr_code_scanner_rounded, size: 80, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 32),
            Text(
              'Pilih Metode Pindai',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 12),
            Text(
              'Anda bisa memindai QR Code anak secara langsung atau melalui gambar di galeri.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onTap: () => setState(() => _showCamera = true),
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _actionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    onTap: _scanFromGallery,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
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
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

