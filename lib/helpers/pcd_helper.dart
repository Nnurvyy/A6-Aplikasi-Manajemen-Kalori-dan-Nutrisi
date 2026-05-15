import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
}
