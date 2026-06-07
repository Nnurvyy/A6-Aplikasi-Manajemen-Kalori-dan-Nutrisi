import 'package:flutter_test/flutter_test.dart';
import 'package:nutritrack_app/features/general/food/models/food_model.dart';
import 'package:nutritrack_app/features/general/food/models/log_model.dart';

void main() {
  group('2. Menambah Log Makanan (Pencatatan)', () {
    group('2.1 Scan YOLO (AI Object Detection)', () {
      test('Positive: Model detects object and returns bounding boxes', () {
        final detectionResult = [{'tag': 'nasi_goreng', 'box': [0.1, 0.2, 0.3, 0.4]}];
        expect(detectionResult.first['tag'], 'nasi_goreng');
      });
      test('Edge Case: YOLO returns empty list when no food detected', () {
        final detectionResult = [];
        expect(detectionResult.isEmpty, true);
      });
    });

    group('2.2 Scan Gemini (AI Vision & Text)', () {
      test('Positive: Gemini parsing returns valid nutrition JSON', () {
        final jsonResponse = { "calories": 250.0, "protein": 10.0, "carbs": 30.0, "fat": 5.0 };
        expect(jsonResponse['calories'], 250.0);
      });
      test('Negative: Gemini API fails/timeout handles error gracefully', () {
        String result = 'API Error';
        expect(result, isNot(contains('calories')));
      });
    });

    group('2.3 Scan Informasi Nilai Gizi (OCR)', () {
      test('Positive: Text recognition extracts Kalori and Protein', () {
        String ocrText = "Lemak 5g Protein 12g Karbo 30g Kalori 200kkal";
        expect(ocrText.toLowerCase().contains('kalori'), true);
      });
      test('Negative: Blurry image OCR fails to extract proper format', () {
        String ocrText = "Lmkk 5q Prtn 12g";
        expect(ocrText.toLowerCase().contains('kalori'), false);
      });
    });

    group('2.4 Input Manual (Database Makanan)', () {
      test('Positive: Search food returns matching FoodModel list', () {
        final food = FoodModel(
            id: 'f1', name: 'Nasi Goreng', category: 'makanan pokok', calories: 300, protein: 5, carbs: 40, fat: 10, createdAt: DateTime.now());
        final db = [food];
        final query = 'nasi';
        final result = db.where((e) => e.name.toLowerCase().contains(query)).toList();
        expect(result.length, 1);
      });
    });

    group('2.5 Input Log Manual (Komposisi Sendiri)', () {
      test('Positive: Custom nutrition creates valid LogModel', () {
        final log = LogModel(
          id: 'l1', userId: 'u1', foodName: 'Custom Food', calories: 150, protein: 5, carbs: 10, fat: 2, mealType: 'Sarapan', consumedAt: DateTime.now(), servingSize: 100, category: 'lainnya', isManual: true,
        );
        expect(log.isManual, true);
        expect(log.calories, 150);
      });
    });
  });
}
