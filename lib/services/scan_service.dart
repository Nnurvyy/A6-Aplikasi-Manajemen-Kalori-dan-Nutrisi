// SEMENTARA DINONAKTIFKAN — sedang migrasi ke tflite_flutter
// Aktifkan kembali setelah migrasi selesai

/*
import 'dart:typed_data';
import 'package:flutter_vision/flutter_vision.dart';

class ScanService {
  static final ScanService _instance = ScanService._internal();
  factory ScanService() => _instance;
  ScanService._internal();

  late FlutterVision _vision;
  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    _vision = FlutterVision();
    await _vision.loadYoloModel(
      modelPath: 'assets/nutritrack.tflite',
      labels: 'assets/labels.txt',
      modelVersion: 'yolov8',
      numThreads: 2,
      useGpu: false,
    );
    _isLoaded = true;
  }

  Future<List<Map<String, dynamic>>> detect(Uint8List imageBytes, int height, int width) async {
    if (!_isLoaded) await init();
    return await _vision.yoloOnImage(
      bytesList: imageBytes,
      imageHeight: height,
      imageWidth: width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.4,
    );
  }

  Future<void> dispose() async {
    if (_isLoaded) {
      await _vision.closeYoloModel();
      _isLoaded = false;
    }
  }
}
*/

// Stub sementara supaya file lain yang import ScanService tidak error
import 'dart:typed_data';

class ScanService {
  static final ScanService _instance = ScanService._internal();
  factory ScanService() => _instance;
  ScanService._internal();

  Future<void> init() async {}
  Future<List<Map<String, dynamic>>> detect(
    Uint8List imageBytes,
    int height,
    int width,
  ) async => [];
  Future<void> dispose() async {}
}
