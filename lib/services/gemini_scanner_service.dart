import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiScannerService {
  static String get _backendUrl => dotenv.env['BACKEND_URL'] ?? '';
  static String get _secretToken => dotenv.env['APP_SECRET_TOKEN'] ?? '';
  static String get _endpoint => '$_backendUrl/api/ai/gemini';

  Future<Map<String, dynamic>?> analyzeImage(Uint8List imageBytes, String mimeType) async {
    final String base64Image = base64Encode(imageBytes);

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Secret': _secretToken,
        },
        body: jsonEncode({
          'image': base64Image,
          'mimeType': mimeType,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        return result;
      } else {
        print('Error Hono Gemini API: ${response.statusCode} - ${response.body}');
        throw Exception('Gagal menganalisis gambar dari Hono Gemini API (Status: ${response.statusCode}).');
      }
    } catch (e) {
      print('Exception di GeminiScannerService: $e');
      throw Exception('Gagal menganalisis gambar dari Hono Gemini API: $e');
    }
  }
}
