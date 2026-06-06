import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutritrack_app/services/scan_service.dart';
import 'package:nutritrack_app/services/hive_service.dart';
import 'package:nutritrack_app/services/offline_storage_service.dart';
import 'package:nutritrack_app/helpers/pcd_helper.dart';
import 'package:nutritrack_app/features/general/food/models/food_model.dart';
import 'package:nutritrack_app/features/general/food/controllers/food_controller.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class ScanController extends ChangeNotifier {
  final ScanService _scanService = ScanService();
  final ImagePicker _picker = ImagePicker();

  bool _isScanning = false;
  bool _hasResult = false;
  File? _selectedImage;
  List<Map<String, dynamic>> _detections = [];
  List<FoodModel> _mappedFoods = [];
  ui.Image? _uiImage;
  Uint8List? _processedImageBytes;
  int _origWidth = 0;
  int _origHeight = 0;

  bool get isScanning => _isScanning;
  bool get hasResult => _hasResult;
  File? get selectedImage => _selectedImage;
  List<Map<String, dynamic>> get detections => _detections;
  List<FoodModel> get mappedFoods => _mappedFoods;
  ui.Image? get uiImage => _uiImage;
  Uint8List? get processedImageBytes => _processedImageBytes;
  int get origWidth => _origWidth;
  int get origHeight => _origHeight;

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
    final XFile? file = await _picker.pickImage(source: source);
    if (file == null) return;

    _selectedImage = File(file.path);
    _hasResult = false;
    _detections = [];
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
      
      // Decode original image size
      final ui.Codec origCodec = await ui.instantiateImageCodec(rawBytes);
      final ui.FrameInfo origFrame = await origCodec.getNextFrame();
      _origWidth = origFrame.image.width;
      _origHeight = origFrame.image.height;

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

      // Run inference
      final results = await _scanService.detect(
        processedBytes,
        _uiImage!.height, // 640
        _uiImage!.width,  // 640
      );

      _detections = results;
      _mapResultsToFoods();
      
      _hasResult = _mappedFoods.isNotEmpty;
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  void _mapResultsToFoods() {
    _mappedFoods = [];
    for (var det in _detections) {
      final String tag = det['tag'];
      // Cari di Hive dengan nama yang sesuai
      final food = HiveService.foods.values.firstWhere(
        (f) => f.name.toLowerCase() == tag.toLowerCase(),
        orElse: () => FoodModel(
          id: 'unknown',
          name: tag,
          category: 'Unknown',
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          isApproved: false,
          createdAt: DateTime.now(),
        ),
      );
      if (food.id != 'unknown') {
        _mappedFoods.add(food);
      }
    }
  }

  void clearResult() {
    _selectedImage = null;
    _hasResult = false;
    _detections = [];
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
