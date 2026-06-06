import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutritrack_app/services/gemini_scanner_service.dart';
import 'package:nutritrack_app/services/offline_storage_service.dart';
import 'package:nutritrack_app/helpers/pcd_helper.dart';
import 'dart:convert';
import 'package:nutritrack_app/features/general/food/models/food_model.dart';
import 'package:nutritrack_app/features/general/food/controllers/food_controller.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class ScanGeminiController extends ChangeNotifier {
  final GeminiScannerService _geminiService = GeminiScannerService();
  final ImagePicker _picker = ImagePicker();

  bool _isScanning = false;
  bool _hasResult = false;
  File? _selectedImage;
  Map<String, dynamic>? _detectionResult;
  List<FoodModel> _mappedFoods = [];
  ui.Image? _uiImage;
  Uint8List? _processedImageBytes;

  bool get isScanning => _isScanning;
  bool get hasResult => _hasResult;
  File? get selectedImage => _selectedImage;
  Map<String, dynamic>? get detectionResult => _detectionResult;
  List<FoodModel> get mappedFoods => _mappedFoods;
  ui.Image? get uiImage => _uiImage;
  Uint8List? get processedImageBytes => _processedImageBytes;

  double get totalCalories => _mappedFoods.fold(0, (sum, f) => sum + (f.calories * f.defaultServingSize / 100));

  List<FoodModel> get uniqueMappedFoods {
    final Map<String, FoodModel> unique = {};
    for (var f in _mappedFoods) {
      if (!unique.containsKey(f.id)) {
        unique[f.id] = f;
      }
    }
    return unique.values.toList();
  }

  int getFoodCount(String foodId) {
    return _mappedFoods.where((f) => f.id == foodId).length;
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    _selectedImage = File(file.path);
    _hasResult = false;
    _detectionResult = null;
    _mappedFoods = [];
    _processedImageBytes = null;
    notifyListeners();

    await _processImage();
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    _isScanning = true;
    notifyListeners();

    try {
      final Uint8List rawBytes = await _selectedImage!.readAsBytes();
      
      // Run PCD in Isolate
      final Uint8List? processedBytes = await PCDHelper.processForYolo(rawBytes);
      if (processedBytes == null) {
        throw Exception("PCD Processing failed");
      }
      _processedImageBytes = processedBytes;
      
      // Decode processed image to get dimensions (will be 640x640)
      final ui.Codec codec = await ui.instantiateImageCodec(processedBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      _uiImage = frameInfo.image;

      // Run inference using Gemini
      final mimeType = _selectedImage!.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final result = await _geminiService.analyzeImage(rawBytes, mimeType);

      if (result != null) {
        _detectionResult = result;
        _mapResultsToFoods(result);
      }
      
      _hasResult = _mappedFoods.isNotEmpty;
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  void _mapResultsToFoods(Map<String, dynamic> result) {
    _mappedFoods = [];
    
    final ingredientsJsonString = result['ingredients'] != null 
        ? jsonEncode(result['ingredients']) 
        : null;

    final food = FoodModel(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      name: result['name'] ?? 'Unknown',
      category: result['category'] ?? 'Lainnya',
      calories: (result['total_calories'] as num?)?.toDouble() ?? 0.0,
      protein: (result['total_protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (result['total_carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (result['total_fat'] as num?)?.toDouble() ?? 0.0,
      defaultServingSize: (result['total_weight_grams'] as num?)?.toDouble() ?? 100.0,
      ingredientsJson: ingredientsJsonString,
      isApproved: false,
      createdAt: DateTime.now(),
    );
    
    _mappedFoods.add(food);
  }

  void clearResult() {
    _selectedImage = null;
    _hasResult = false;
    _detectionResult = null;
    _mappedFoods = [];
    _uiImage = null;
    _processedImageBytes = null;
    notifyListeners();
  }

  Future<bool> saveScanResult({
    required String userId,
    required FoodController foodController,
    required BuildContext context,
    required String mealType,
  }) async {
    if ((_selectedImage == null && _processedImageBytes == null) || _mappedFoods.isEmpty) return false;

    try {
      // 1. Simpan gambar lokal secara offline-first (prioritaskan gambar asli)
      final String? localFileName = _selectedImage != null
          ? await OfflineStorageService.saveLocalImage(await _selectedImage!.readAsBytes())
          : await OfflineStorageService.saveLocalImage(_processedImageBytes!);
      
      // 2. Simpan setiap makanan terdeteksi ke Daily Log
      for (var food in _mappedFoods) {
        await foodController.addFoodToDailyLog(
          userId: userId,
          foodName: food.name,
          category: food.category,
          calories: food.calories,
          protein: food.protein,
          carbs: food.carbs,
          fat: food.fat,
          mealType: mealType,
          dateConsumed: DateTime.now(),
          servingSize: food.defaultServingSize,
          isManual: false,
          imageUrl: localFileName, // Sementara simpan nama file, akan diupdate via background sync
          ingredientsJson: food.ingredientsJson,
          context: context,
        );
      }

      // 3. Trigger upload Firebase di background jika gambar berhasil disimpan
      if (localFileName != null) {
        // Karena addFoodToDailyLog membuat banyak log jika ada banyak deteksi,
        // Firebase Storage upload bisa dipanggil untuk log terakhir (atau secara umum)
        // Note: Implementasi detail update logData.imageUrl ke cloud akan ditangani di 
        // dalam service atau logic spesifik jika diperlukan. 
        // Saat ini uploadAndSyncToFirebase butuh LogModel.
        // Kita cukup memanggilnya untuk setiap log baru, atau biarkan SyncService yang handle.
        // Berdasarkan instruksi: "Trigger uploadAndSyncToFirebase berjalan secara terpisah"
        
        // Dapatkan log terbaru yang baru saja ditambahkan untuk user ini (sekadar contoh integrasi)
        final logs = foodController.getUserLogs(userId);
        if (logs.isNotEmpty) {
          final latestLog = logs.last; // Log terakhir dari proses di atas
          OfflineStorageService.uploadAndSyncToFirebase(localFileName, userId, latestLog);
        }
      }

      clearResult();
      return true;
    } catch (e) {
      debugPrint("Error saving scan result: $e");
      return false;
    }
  }

}
