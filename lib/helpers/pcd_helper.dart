import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class PCDHelper {
  /// Melakukan preprocessing gambar di background (tanpa UI).
  /// Karena OpenCV dilepas, kita menggunakan library image murni untuk:
  /// 1. Grayscale & Contrast Enhancement
  /// 2. Smart Crop berdasarkan kotak batas estimasi (jika diberikan)
  static Future<String?> autoCropAndEnhance(String imagePath, {Rectangle<int>? cropRect}) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Jika ada ROI (Region of Interest) dari hasil deteksi awal, lakukan Crop
      if (cropRect != null) {
        // Beri margin sedikit agar teks tidak terpotong
        int x = max(0, cropRect.left - 20);
        int y = max(0, cropRect.top - 20);
        int w = min(image.width - x, cropRect.width + 40);
        int h = min(image.height - y, cropRect.height + 40);

        image = img.copyCrop(image, x: x, y: y, width: w, height: h);
      }

      // Preprocessing: Grayscale untuk mempertajam teks
      image = img.grayscale(image);

      // Preprocessing: Adjust Contrast (PCD sederhana untuk memperjelas teks OCR)
      image = img.adjustColor(image, contrast: 1.5);

      final directory = await getTemporaryDirectory();
      String outPath = '${directory.path}/processed_nutrition_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 90));

      return outPath;
    } catch (e) {
      debugPrint("Error in background image processing: $e");
      return imagePath;
    }
  }

  /// Entry point untuk compute() isolate YOLO PCD
  static Future<Uint8List?> _processForYoloIsolate(Uint8List bytes) async {
    try {
      // 1. Decode Image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // 2. Pre-Resizing & Letterboxing (640x640)
      const targetSize = 640;
      
      // Hitung rasio untuk resize (sisi terpanjang max 640)
      double ratio = targetSize / max(image.width, image.height);
      int newWidth = (image.width * ratio).round();
      int newHeight = (image.height * ratio).round();

      // Resize gambar
      img.Image resizedImage = img.copyResize(image, width: newWidth, height: newHeight);

      // Buat canvas abu-abu 640x640 (RGB: 114, 114, 114)
      img.Image canvas = img.Image(width: targetSize, height: targetSize);
      img.fill(canvas, color: img.ColorRgb8(114, 114, 114));

      // Paste gambar resize ke tengah canvas
      int dstX = ((targetSize - newWidth) / 2).round();
      int dstY = ((targetSize - newHeight) / 2).round();
      
      img.compositeImage(canvas, resizedImage, dstX: dstX, dstY: dstY);

      // 3. Denoising: Gaussian Blur (radius: 1)
      img.Image denoised = img.gaussianBlur(canvas, radius: 1);

      // 4. Contrast & Brightness: adjustColor(contrast: 1.2)
      img.Image enhanced = img.adjustColor(denoised, contrast: 1.2);

      // 5. Encode to JPG (quality 75)
      return img.encodeJpg(enhanced, quality: 75);
    } catch (e) {
      debugPrint("Error in YOLO PCD isolate: $e");
      return null;
    }
  }

  /// Memproses gambar untuk YOLOv8 (640x640, Letterbox, Denoise, Contrast) secara asinkron di Isolate.
  static Future<Uint8List?> processForYolo(Uint8List bytes) async {
    return await compute(_processForYoloIsolate, bytes);
  }

  /// Draw highlight rectangles permanently onto an image
  static Future<Uint8List?> drawHighlights(String imagePath, List<Rect> rects) async {
    return await compute((Map<String, dynamic> args) {
      final path = args['path'] as String;
      final rectList = args['rects'] as List<Map<String, double>>;
      
      final bytes = File(path).readAsBytesSync();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return bytes;

      final color = img.ColorRgba8(0, 255, 0, 100); // Semi-transparent green if supported, else solid
      final outlineColor = img.ColorRgb8(0, 255, 0);

      for (var r in rectList) {
        // package:image drawRect draws outline. We use a thick outline.
        img.drawRect(
          image,
          x1: r['left']!.round(),
          y1: r['top']!.round(),
          x2: r['right']!.round(),
          y2: r['bottom']!.round(),
          color: outlineColor,
          thickness: 3,
        );
      }
      return img.encodeJpg(image, quality: 90);
    }, {
      'path': imagePath,
      'rects': rects.map((r) => {'left': r.left, 'top': r.top, 'right': r.right, 'bottom': r.bottom}).toList(),
    });
  }
}
