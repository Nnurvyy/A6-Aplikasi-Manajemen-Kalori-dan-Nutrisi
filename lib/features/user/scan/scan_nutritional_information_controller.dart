import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../helpers/pcd_helper.dart';
import '../../../services/offline_storage_service.dart';
import '../../general/food/food_controller.dart';

class ScanNutritionalInformationController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  File? _originalImage;
  File? _processedImage;
  bool _isProcessing = false;
  String _statusText = '';
  final List<Rect> _highlightRects = [];
  Size? _imageSize;

  // Getters
  File? get originalImage => _originalImage;
  File? get processedImage => _processedImage;
  bool get isProcessing => _isProcessing;
  String get statusText => _statusText;
  List<Rect> get highlightRects => _highlightRects;
  Size? get imageSize => _imageSize;

  // Form Controllers
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController servingSizeCtrl = TextEditingController(text: '100');
  final TextEditingController calCtrl = TextEditingController(text: '0');
  final TextEditingController proteinCtrl = TextEditingController(text: '0');
  final TextEditingController carbsCtrl = TextEditingController(text: '0');
  final TextEditingController fatCtrl = TextEditingController(text: '0');

  // Base Nutrition Values (per takaran saji asli dari gambar)
  double _baseServingSize = 100.0;
  double _baseCalories = 0.0;
  double _baseProtein = 0.0;
  double _baseCarbs = 0.0;
  double _baseFat = 0.0;

  bool _isDisposed = false;

  ScanNutritionalInformationController() {
    servingSizeCtrl.addListener(_updateNutritionValues);
  }

  void _updateNutritionValues() {
    final inputGram = double.tryParse(servingSizeCtrl.text) ?? 0.0;
    if (_baseServingSize > 0 && inputGram > 0) {
      final ratio = inputGram / _baseServingSize;
      calCtrl.text = (_baseCalories * ratio).round().toString();
      proteinCtrl.text = (_baseProtein * ratio).round().toString();
      carbsCtrl.text = (_baseCarbs * ratio).round().toString();
      fatCtrl.text = (_baseFat * ratio).round().toString();
    } else {
      calCtrl.text = '0';
      proteinCtrl.text = '0';
      carbsCtrl.text = '0';
      fatCtrl.text = '0';
    }
  }

  Future<void> pickAndProcessImage(ImageSource source, BuildContext context) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    _originalImage = File(picked.path);
    _processedImage = null;
    _highlightRects.clear();
    _imageSize = null;
    _isProcessing = true;
    _statusText = 'Menemukan area tabel gizi (ROI)...';
    notifyListeners();

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

      _statusText = 'Memotong & Preprocessing gambar...';
      notifyListeners();

      // 3. PCD Background: Crop & Enhance (Grayscale + Contrast)
      String? processedPath = await PCDHelper.autoCropAndEnhance(picked.path, cropRect: cropRect);
      
      if (processedPath != null && !_isDisposed) {
        final file = File(processedPath);
        final decodedImage = await decodeImageFromList(await file.readAsBytes());
        
        _imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
        _processedImage = file;
        _statusText = 'Membaca teks (Google Lens mode)...';
        notifyListeners();

        // 4. Run ML Kit AGAIN on the cropped image to get bounding boxes that match the preview
        final inputImage = InputImage.fromFilePath(processedPath);
        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
        
        // 5. Ekstrak data menggunakan metode spatial (nearest right) yang tahan melengkung
        _extractNutritionData(recognizedText);
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memproses gambar')),
        );
      }
    } finally {
      if (!_isDisposed) {
        _isProcessing = false;
        _statusText = '';
        notifyListeners();
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
      for (var k in keywords) {
        lineText = lineText.replaceAll(k, '');
      }
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

    servingSizeCtrl.text = _baseServingSize.round().toString();
    _updateNutritionValues();
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

  Future<bool> saveToHistory({
    required String userId,
    required FoodController foodController,
    required BuildContext context,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final foodName = nameCtrl.text.trim();
      final calories = double.tryParse(calCtrl.text) ?? 0;
      final protein = double.tryParse(proteinCtrl.text) ?? 0;
      final carbs = double.tryParse(carbsCtrl.text) ?? 0;
      final fat = double.tryParse(fatCtrl.text) ?? 0;
      final inputGram = double.tryParse(servingSizeCtrl.text) ?? 100.0;

      String? localFileName;
      if (_processedImage != null) {
        final finalBytes = await PCDHelper.drawHighlights(_processedImage!.path, _highlightRects);
        if (finalBytes != null) {
          localFileName = await OfflineStorageService.saveLocalImage(finalBytes);
        }
      } else if (_originalImage != null) {
        localFileName = await OfflineStorageService.saveLocalImage(await _originalImage!.readAsBytes());
      }

      await foodController.addFoodToDailyLog(
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
        imageUrl: localFileName,
        context: context,
      );

      if (localFileName != null) {
        final logs = foodController.getUserLogs(userId);
        if (logs.isNotEmpty) {
          OfflineStorageService.uploadAndSyncToFirebase(localFileName, userId, logs.last);
        }
      }

      return true;
    } catch (e) {
      debugPrint("Error saving to history: $e");
      return false;
    } finally {
      if (!_isDisposed) {
        _isProcessing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _textRecognizer.close();
    nameCtrl.dispose();
    servingSizeCtrl.dispose();
    calCtrl.dispose();
    proteinCtrl.dispose();
    carbsCtrl.dispose();
    fatCtrl.dispose();
    super.dispose();
  }
}
