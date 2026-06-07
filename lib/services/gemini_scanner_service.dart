import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiScannerService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const List<String> geminiModels = [
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash',
    'gemini-3-flash',
    'gemini-2.5-flash',
  ];

  static const String _prompt = 
      "Kamu adalah AI Ahli Gizi Forensik. Tugasmu adalah membedah gambar makanan/minuman yang diberikan menjadi komponen-komponen penyusunnya (ingredients) secara spesifik HANYA berdasarkan ukuran dan porsi nyata yang terlihat di gambar.\n\n"
      "ATURAN LOGIKA:\n"
      "1. Identifikasi setiap komponen makanan yang ada di gambar (misal: nasi putih, ayam goreng, timun, sambal).\n"
      "2. Estimasikan berat (gram) dan kandungan gizi (kalori, protein, karbohidrat, lemak) untuk MASING-MASING komponen tersebut sesuai porsi yang terlihat.\n"
      "3. Hitung TOTAL keseluruhan (berat dan gizi) dari semua komponen.\n"
      "4. Tentukan NAMA MAKANAN UTAMA menggunakan format '[Komponen Dominan 1] dengan [Komponen Dominan 2]'. Jika hanya ada 1 komponen, gunakan nama komponen itu saja. Komponen 'Dominan' ditentukan dari penyumbang kalori/protein paling besar. Contoh: 'Ayam Goreng dengan Nasi Putih'.\n"
      "5. Tentukan KATEGORI utama hidangan tersebut. HANYA boleh memilih satu dari: 'makanan pokok', 'lauk', 'sayuran', 'buah', 'minuman', 'snack', 'lainnya'.\n\n"
      "KEMBALIKAN HANYA BENTUK JSON VALID dengan struktur eksak seperti ini:\n"
      "{\n"
      "  \"name\": \"String (Nama gabungan dominan)\",\n"
      "  \"category\": \"String (Dari pilihan enum)\",\n"
      "  \"total_calories\": Double,\n"
      "  \"total_protein\": Double,\n"
      "  \"total_carbs\": Double,\n"
      "  \"total_fat\": Double,\n"
      "  \"total_weight_grams\": Double,\n"
      "  \"ingredients\": [\n"
      "    {\n"
      "      \"name\": \"String\",\n"
      "      \"calories\": Double,\n"
      "      \"protein\": Double,\n"
      "      \"carbs\": Double,\n"
      "      \"fat\": Double,\n"
      "      \"weight_grams\": Double\n"
      "    }\n"
      "  ]\n"
      "}";

  Future<Map<String, dynamic>?> analyzeImage(Uint8List imageBytes, String mimeType) async {
    final String base64Image = base64Encode(imageBytes);

    for (String model in geminiModels) {
      final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey';
      
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": _prompt},
                  {
                    "inline_data": {
                      "mime_type": mimeType,
                      "data": base64Image
                    }
                  }
                ]
              }
            ],
            "generationConfig": {
              "temperature": 0.0,
              "responseMimeType": "application/json"
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List;
          if (candidates.isNotEmpty) {
            final content = candidates[0]['content']['parts'][0]['text'] as String;
            return jsonDecode(content) as Map<String, dynamic>;
          }
        } else if (response.statusCode == 429 || response.statusCode == 500) {
          print('Model $model gagal dengan status ${response.statusCode}. Mencoba model berikutnya...');
          continue;
        } else {
          print('Error API Gemini: ${response.statusCode} - ${response.body}');
          continue;
        }
      } catch (e) {
        print('Exception dengan model $model: $e');
        continue;
      }
    }
    
    throw Exception('Gagal mendapatkan analisis gambar dari semua fallback models Gemini.');
  }
}
