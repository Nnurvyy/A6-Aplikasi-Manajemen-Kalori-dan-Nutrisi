import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqNutritionService {
  static String get _backendUrl => dotenv.env['BACKEND_URL'] ?? '';
  static String get _secretToken => dotenv.env['APP_SECRET_TOKEN'] ?? '';
  static String get _endpoint => '$_backendUrl/api/ai/groq';

  Future<Map<String, dynamic>?> fetchNutritionData(String query) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Secret': _secretToken,
        },
        body: jsonEncode({
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> nutritionData = jsonDecode(response.body);
        return nutritionData;
      } else {
        print('Error Hono Groq API: ${response.statusCode} - ${response.body}');
        throw Exception('Gagal mendapatkan data gizi dari Hono Groq API (Status: ${response.statusCode}).');
      }
    } catch (e) {
      print('Exception di GroqNutritionService: $e');
      throw Exception('Gagal mendapatkan data gizi dari Hono Groq API: $e');
    }
  }
}
