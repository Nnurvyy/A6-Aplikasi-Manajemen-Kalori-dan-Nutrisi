import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/scan_service.dart';
import '../../services/hive_service.dart';
import '../food/models/food_model.dart';
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

  bool get isScanning => _isScanning;
  bool get hasResult => _hasResult;
  File? get selectedImage => _selectedImage;
  List<Map<String, dynamic>> get detections => _detections;
  List<FoodModel> get mappedFoods => _mappedFoods;
  ui.Image? get uiImage => _uiImage;

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
    notifyListeners();

    await _processImage();
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    _isScanning = true;
    notifyListeners();

    try {
      final Uint8List bytes = await _selectedImage!.readAsBytes();
      
      // Decode image to get dimensions
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      _uiImage = frameInfo.image;

      // Run inference
      final results = await _scanService.detect(
        bytes,
        _uiImage!.height,
        _uiImage!.width,
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
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
