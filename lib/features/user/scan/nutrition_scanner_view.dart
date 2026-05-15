import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';

import '../../../helpers/pcd_helper.dart';
import '../../general/auth/auth_controller.dart';
import '../../general/food/food_controller.dart';
import 'dart:math';

class NutritionScannerView extends StatefulWidget {
  const NutritionScannerView({super.key});

  @override
  State<NutritionScannerView> createState() => _NutritionScannerViewState();
}

class _NutritionScannerViewState extends State<NutritionScannerView> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  File? _originalImage;
  File? _processedImage;
  bool _isProcessing = false;
  String _statusText = '';
  List<Rect> _highlightRects = [];
  Size? _imageSize;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _servingSizeCtrl = TextEditingController(text: '100');
  final _calCtrl = TextEditingController(text: '0');
  final _proteinCtrl = TextEditingController(text: '0');
  final _carbsCtrl = TextEditingController(text: '0');
  final _fatCtrl = TextEditingController(text: '0');

  // Base Nutrition Values (per takaran saji asli dari gambar)
  double _baseServingSize = 100.0;
  double _baseCalories = 0.0;
  double _baseProtein = 0.0;
  double _baseCarbs = 0.0;
  double _baseFat = 0.0;

  @override
  void initState() {
    super.initState();
    _servingSizeCtrl.addListener(_updateNutritionValues);
  }

  void _updateNutritionValues() {
    final inputGram = double.tryParse(_servingSizeCtrl.text) ?? 0.0;
    if (_baseServingSize > 0 && inputGram > 0) {
      final ratio = inputGram / _baseServingSize;
      _calCtrl.text = (_baseCalories * ratio).round().toString();
      _proteinCtrl.text = (_baseProtein * ratio).round().toString();
      _carbsCtrl.text = (_baseCarbs * ratio).round().toString();
      _fatCtrl.text = (_baseFat * ratio).round().toString();
    } else {
      _calCtrl.text = '0';
      _proteinCtrl.text = '0';
      _carbsCtrl.text = '0';
      _fatCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _nameCtrl.dispose();
    _servingSizeCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      _originalImage = File(picked.path);
      _processedImage = null;
      _highlightRects.clear();
      _imageSize = null;
      _isProcessing = true;
      _statusText = 'Menemukan area tabel gizi (ROI)...';
    });

    try {
      // 1. Run ML Kit on original image to find Region of Interest (ROI)
      final originalInputImage = InputImage.fromFilePath(picked.path);
      final initialText = await _textRecognizer.processImage(originalInputImage);
      
      // 2. Reconstruct lines with dynamic Y-tolerance dari initial scan
      List<TextElement> allElements = [];
      for (var block in initialText.blocks) {
        for (var line in block.lines) {
          for (var element in line.elements) {
            allElements.add(element);
          }
        }
      }
      allElements.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      List<List<TextElement>> lines = [];
      for (var element in allElements) {
        bool added = false;
        for (var line in lines) {
          double lineCenterY = line.first.boundingBox.top + (line.first.boundingBox.height / 2);
          double elementCenterY = element.boundingBox.top + (element.boundingBox.height / 2);
          double tolerance = line.first.boundingBox.height * 0.5;
          if (tolerance < 20) tolerance = 20;
          
          if ((lineCenterY - elementCenterY).abs() < tolerance) {
            line.add(element);
            added = true;
            break;
          }
        }
        if (!added) {
          lines.add([element]);
        }
      }

      for (var line in lines) {
        line.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      }

      // Cari bounding box presisi HANYA untuk tabel nilai gizi
      int minX = 999999, minY = 999999, maxX = 0, maxY = 0;
      bool tableStarted = false;

      for (int i = 0; i < lines.length; i++) {
        String lineText = lines[i].map((e) => e.text).join(' ').toLowerCase();
        
        if (!tableStarted && (
            lineText.contains('gizi') || 
            lineText.contains('nutrition') || 
            lineText.contains('takaran saji') || 
            lineText.contains('serving size') ||
            lineText.contains('energi total') ||
            lineText.contains('lemak total')
        )) {
          tableStarted = true;
        }

        if (tableStarted) {
          // Berhenti memperluas bounding box jika sudah mencapai keterangan bawah
          if (lineText.contains('persen akg') || lineText.contains('kebutuhan energi') || lineText.contains('% akg') || lineText.contains('daily values') || lineText.contains('kebutuhan kalori')) {
            break;
          }

          for (var e in lines[i]) {
            if (e.boundingBox.left < minX) minX = e.boundingBox.left.toInt();
            if (e.boundingBox.top < minY) minY = e.boundingBox.top.toInt();
            if (e.boundingBox.right > maxX) maxX = e.boundingBox.right.toInt();
            if (e.boundingBox.bottom > maxY) maxY = e.boundingBox.bottom.toInt();
          }
        }
      }

      Rectangle<int>? cropRect;
      if (tableStarted && maxX > minX && maxY > minY) {
        cropRect = Rectangle<int>(minX, minY, maxX - minX, maxY - minY);
      }

      setState(() {
        _statusText = 'Memotong & Preprocessing gambar...';
      });

      // 3. PCD Background: Crop & Enhance (Grayscale + Contrast)
      String? processedPath = await PCDHelper.autoCropAndEnhance(picked.path, cropRect: cropRect);
      
      if (processedPath != null && mounted) {
        final file = File(processedPath);
        final decodedImage = await decodeImageFromList(await file.readAsBytes());
        
        setState(() {
          _imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
          _processedImage = file;
          _statusText = 'Membaca teks (Google Lens mode)...';
        });

        // 4. Run ML Kit AGAIN on the cropped image to get bounding boxes that match the preview
        final inputImage = InputImage.fromFilePath(processedPath);
        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
        
        // 5. Ekstrak data menggunakan metode spatial (nearest right) yang tahan melengkung
        _extractNutritionData(recognizedText);
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memproses gambar')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = '';
        });
      }
    }
  }

  void _extractNutritionData(RecognizedText recognizedText) {
    _highlightRects.clear();
    
    double? findValue(List<String> keywords, {bool excludeEnergiDariLemak = false, bool excludeLemakLain = false, bool excludeFooter = false}) {
      TextLine? bestLabel;
      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          String text = line.text.toLowerCase();
          
          // Filter out footer/disclaimer text
          if (excludeFooter && (text.contains('kebutuhan') || text.contains('akg') || text.contains('berdasarkan') || text.contains('persen'))) {
            continue;
          }

          if (keywords.any((k) => text.contains(k))) {
            if (excludeEnergiDariLemak && text.contains('energi dari')) continue;
            if (excludeLemakLain && (text.contains('jenuh') || text.contains('trans') || text.contains('ganda') || text.contains('tunggal'))) continue;
            
            bestLabel = line;
            break;
          }
        }
        if (bestLabel != null) break;
      }

      if (bestLabel == null) return null;
      _highlightRects.add(bestLabel.boundingBox);

      String lineText = bestLabel.text.toLowerCase();
      for (var k in keywords) lineText = lineText.replaceAll(k, '');
      if (RegExp(r'\d').hasMatch(lineText)) {
        return _parseFirstNumber(lineText);
      }

      double labelCenterY = bestLabel.boundingBox.top + (bestLabel.boundingBox.height / 2);
      double labelRight = bestLabel.boundingBox.right;

      TextLine? nearestNumber;
      double minScore = 999999;

      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          if (line == bestLabel) continue;
          
          double lineCenterY = line.boundingBox.top + (line.boundingBox.height / 2);
          double yDiff = (lineCenterY - labelCenterY).abs();
          
          double yTolerance = max(15.0, bestLabel.boundingBox.height * 2.0);
          
          if (yDiff < yTolerance) {
            if (line.boundingBox.left >= labelRight - 15) { 
              double xDiff = line.boundingBox.left - labelRight;
              
              double score = (yDiff * 5) + xDiff;
              
              if (score < minScore && RegExp(r'\d').hasMatch(line.text)) {
                minScore = score;
                nearestNumber = line;
              }
            }
          }
        }
      }

      if (nearestNumber != null) {
        _highlightRects.add(nearestNumber.boundingBox);
        return _parseFirstNumber(nearestNumber.text, isCalories: keywords.contains('energi') || keywords.contains('energi total'));
      }
      return null;
    }

    _baseServingSize = findValue(['takaran saji', 'serving size', 'takaran'], excludeFooter: true) ?? 100.0;
    _baseCalories = findValue(['energi total', 'kalori total', 'energi'], excludeEnergiDariLemak: true, excludeFooter: true) ?? 0.0;
    _baseProtein = findValue(['protein', 'rotein', 'prot'], excludeFooter: true) ?? 0.0;
    _baseCarbs = findValue(['karbohidrat', 'carbohydrate', 'karbo', 'carbo'], excludeFooter: true) ?? 0.0;
    _baseFat = findValue(['lemak total', 'total fat', 'lemak'], excludeEnergiDariLemak: true, excludeLemakLain: true, excludeFooter: true) ?? 0.0;

    if (_baseServingSize == 0) _baseServingSize = 100.0;

    setState(() {
      _servingSizeCtrl.text = _baseServingSize.round().toString();
      _updateNutritionValues();
    });
  }


  double? _parseFirstNumber(String text, {bool isCalories = false}) {
    // Membersihkan teks dari unit yang sering membuat OCR bingung
    String cleaned = text.toLowerCase()
        .replaceAll('kkal', '')
        .replaceAll('kcal', '')
        .replaceAll('mg', '')
        .replaceAll(RegExp(r'[gG]\b'), '') // Hapus 'g' di akhir kata
        .trim();

    final match = RegExp(r'(\d+[\.,]?\d*)').firstMatch(cleaned);
    if (match != null) {
      String valStr = match.group(1)!.replaceAll(',', '.');
      double? val = double.tryParse(valStr);
      
      if (val != null && !isCalories) {
        // Heuristic: Jika angka > 50 dan diakhiri '9', besar kemungkinan 'g' terbaca '9'
        // Contoh: 7g -> 79, 13g -> 139. 
        // Kita tidak melakukan ini untuk Kalori karena kalori > 50 sangat umum.
        String s = val.round().toString();
        if (val > 50 && s.endsWith('9')) {
          double? stripped = double.tryParse(s.substring(0, s.length - 1));
          if (stripped != null) return stripped;
        }
      }
      return val;
    }
    return null;
  }

  void _saveToHistory() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) return;

    setState(() => _isProcessing = true);

    try {
      final foodName = _nameCtrl.text.trim();
      final calories = double.tryParse(_calCtrl.text) ?? 0;
      final protein = double.tryParse(_proteinCtrl.text) ?? 0;
      final carbs = double.tryParse(_carbsCtrl.text) ?? 0;
      final fat = double.tryParse(_fatCtrl.text) ?? 0;
      final inputGram = double.tryParse(_servingSizeCtrl.text) ?? 100.0;

      final foodCtrl = context.read<FoodController>();
      
      await foodCtrl.addFoodToDailyLog(
        userId: userId,
        foodName: foodName,
        category: 'Lainnya',
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        mealType: 'Snack',
        dateConsumed: DateTime.now(),
        servingSize: inputGram,
        isManual: true,
        imageUrl: _processedImage?.path ?? _originalImage?.path,
        context: context,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$foodName berhasil disimpan ke riwayat!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isProcessing && _processedImage == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  const SizedBox(height: 16),
                  Text(_statusText, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ],
              ),
            )
          : _originalImage == null
              ? _buildInitialSelection()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Image Area
                  GestureDetector(
                    onTap: _showMaximizedImage,
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
                            child: _processedImage != null
                                ? CustomPaint(
                                    foregroundPainter: _imageSize != null ? HighlightPainter(_highlightRects, _imageSize!) : null,
                                    child: Image.file(_processedImage!, fit: BoxFit.contain),
                                  )
                                : Image.file(_originalImage!, fit: BoxFit.contain),
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
                          onPressed: () => _pickAndProcessImage(ImageSource.camera),
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
                          onPressed: () => _pickAndProcessImage(ImageSource.gallery),
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

                  if (_processedImage != null) ...[
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
                            _buildInputField('Nama Makanan / Minuman', _nameCtrl, Icons.restaurant, true),
                            const SizedBox(height: 12),
                            _buildInputField('Takaran Saji (Gram)', _servingSizeCtrl, Icons.scale, true, isNumber: true),
                            const Divider(height: 32),
                            Row(
                              children: [
                                Expanded(child: _buildInputField('Kalori (kcal)', _calCtrl, Icons.local_fire_department, false, isNumber: true, color: Colors.orange)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInputField('Protein (g)', _proteinCtrl, Icons.fitness_center, false, isNumber: true, color: Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildInputField('Karbo (g)', _carbsCtrl, Icons.grain, false, isNumber: true, color: Colors.amber)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInputField('Lemak (g)', _fatCtrl, Icons.water_drop, false, isNumber: true, color: Colors.orange)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : _saveToHistory,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isProcessing 
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

  Widget _buildInitialSelection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
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
                  onTap: () => _pickAndProcessImage(ImageSource.camera),
                ),
                _buildSquareSelectionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  color: Colors.blue,
                  onTap: () => _pickAndProcessImage(ImageSource.gallery),
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

  void _showMaximizedImage() {
    if (_processedImage == null && _originalImage == null) return;
    
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
                child: _processedImage != null
                    ? CustomPaint(
                        foregroundPainter: _imageSize != null ? HighlightPainter(_highlightRects, _imageSize!) : null,
                        child: Image.file(_processedImage!),
                      )
                    : Image.file(_originalImage!),
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
