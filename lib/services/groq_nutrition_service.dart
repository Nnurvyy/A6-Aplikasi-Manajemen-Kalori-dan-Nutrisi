import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqNutritionService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static const List<String> fallbackModels = [
    'llama-3.1-8b-instant',
    'llama-3.3-70b-versatile',
    'mixtral-8x7b-32768',
    'gemma2-9b-it',
    'llama3-8b-8192',
    'llama3-70b-8192',
  ];

  static const String _systemPrompt =
      "Kamu adalah REST API Database Gizi. Pengguna akan memberikan nama makanan atau minuman. Tugasmu adalah mengembalikan estimasi kandungan nutrisi untuk 1 PORSI MAKAN WAJAR (bukan selalu 100 gram, sesuaikan dengan porsi nyata saat dihidangkan, misal 1 piring nasi goreng = 250 gram, 1 mangkok bakso = 300 gram). Tentukan juga kategorinya (pilih salah satu: 'Makanan Pokok', 'Lauk', 'Sayuran', 'Buah', 'Minuman', 'Snack', 'Lainnya'). DILARANG KERAS memberikan kalimat pembuka, penutup, atau penjelasan. DILARANG menggunakan markdown backticks. KEMBALIKAN HANYA BENTUK JSON VALID dengan struktur persis seperti ini: {\"nama_makanan\": \"String\", \"kategori\": \"String\", \"kalori\": Integer, \"protein\": Integer, \"karbohidrat\": Integer, \"lemak\": Integer, \"porsi_gram\": Integer}";

  Future<Map<String, dynamic>?> fetchNutritionData(String query) async {
    for (String model in fallbackModels) {
      try {
        final response = await http.post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'temperature': 0.1,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': query},
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices'][0]['message']['content'] as String;
          final Map<String, dynamic> nutritionData = jsonDecode(content);
          return nutritionData;
        } else if (response.statusCode == 429 || response.statusCode == 500) {
          // Lanjut ke model berikutnya jika rate limit atau server error
          print('Model $model gagal dengan status ${response.statusCode}. Mencoba model berikutnya...');
          continue;
        } else {
          // Status code lain
          print('Error API: ${response.statusCode} - ${response.body}');
          continue;
        }
      } catch (e) {
        print('Exception dengan model $model: $e');
        // Terus lanjut ke model berikutnya jika terjadi exception (misal timeout)
        continue;
      }
    }
    
    // Jika semua model gagal
    throw Exception('Gagal mendapatkan data nutrisi dari semua fallback models.');
  }
}
