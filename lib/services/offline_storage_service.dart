import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../features/general/food/models/log_model.dart';
import 'food_log_firestore_service.dart';
import 'hive_service.dart';

class OfflineStorageService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dxvg4czip';
  static String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'submission_images';
  static String get _cloudinaryUrl => 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Menyimpan file gambar PCD ke lokal secara offline-first
  /// Hanya me-return nama file (contoh: scan_123456789.jpg)
  static Future<String?> saveLocalImage(Uint8List bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${dir.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      return fileName;
    } catch (e) {
      debugPrint("Error saving local image: $e");
      return null;
    }
  }

  /// Merakit path absolut dari nama file secara runtime
  static Future<File?> getLocalFile(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      debugPrint("Error getting local file: $e");
      return null;
    }
  }

  /// Memuat gambar (Prioritas Lokal -> Download jika perlu)
  static Future<File?> getImageFile(String? imagePathOrUrl) async {
    if (imagePathOrUrl == null || imagePathOrUrl.isEmpty) return null;

    try {
      if (imagePathOrUrl.startsWith('http')) {
        // Ekstrak nama file unik dari URL
        final uri = Uri.parse(imagePathOrUrl);
        final fileName = uri.pathSegments.last;
        
        final localFile = await getLocalFile(fileName);
        if (localFile != null) {
          return localFile; // Sudah ada di lokal
        }

        // Jika belum ada, download dan simpan ke lokal
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          return file;
        } else {
          debugPrint("Failed to download image: ${response.statusCode}");
          return null;
        }
      } else {
        // Cek apakah ini absolute path (misal dari ImagePicker / cache)
        if (imagePathOrUrl.startsWith('/') || imagePathOrUrl.startsWith('file://') || imagePathOrUrl.contains(':\\')) {
          final file = File(imagePathOrUrl.replaceFirst('file://', ''));
          if (await file.exists()) return file;
        }
        // Jika bukan absolute path, asumsikan nama file lokal biasa (misal dari PCD)
        return await getLocalFile(imagePathOrUrl);
      }
    } catch (e) {
      debugPrint("Error in getImageFile: $e");
      return null;
    }
  }

  /// Upload file gambar ke Cloudinary (Background) dan update Log
  static Future<void> uploadAndSyncToFirebase(String fileName, String userId, LogModel logData) async {
    try {
      final file = await getLocalFile(fileName);
      if (file == null) {
        debugPrint("Local file not found for upload: $fileName");
        return;
      }

      // Upload ke Cloudinary
      var request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'scans/$userId'; // Optional
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResult = jsonDecode(responseData);
        final secureUrl = jsonResult['secure_url'];

        // Update URL ke LogModel lokal
        logData.imageUrl = secureUrl;
        logData.syncStatus = 'synced';
        await HiveService.logs.put(logData.id, logData);

        // Simpan/Update log ke Firestore
        await FoodLogFirestoreService.upsertLog(logData);
        
        debugPrint("Berhasil sinkron gambar ke Cloudinary dan log: $secureUrl");
      } else {
        debugPrint("Gagal upload ke Cloudinary: ${response.statusCode}");
      }
    } catch (e) {
      // Catch error tanpa mematikan aplikasi, biarkan sync status tetap pending
      debugPrint("Gagal sinkron gambar ke cloud, offline fallback active. Error: $e");
    }
  }
}
