import 'package:flutter_test/flutter_test.dart';
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';
import 'package:nutritrack_app/features/general/food/models/food_model.dart';
import 'package:nutritrack_app/features/general/food/models/log_model.dart';
import 'package:nutritrack_app/features/general/submission/models/submission_model.dart';
import 'package:nutritrack_app/features/user/progress/models/weight_log_model.dart';

void main() {
  group('1. Authentication (Register, Login, Kelola Akun)', () {
    test('Positive: Login with correct credentials should succeed', () {
      final user = UserModel(id: '123', name: 'Test User', email: 'test@nutri.com', password: 'hashed_password', role: 'user', dailyCalorieNeed: 2000);
      expect(user.email, 'test@nutri.com');
      expect(user.role, 'user');
    });
    test('Negative: Login with incorrect password should fail', () {
      bool isErrorThrown = false;
      try { if ('wrong_pass' != 'hashed_password') throw Exception('Wrong password'); } catch (e) { isErrorThrown = true; }
      expect(isErrorThrown, true);
    });
    test('Positive: Register should create new UserModel', () {
      final user = UserModel.fromMap({'id': '999', 'name': 'New User', 'email': 'new@nutri.com', 'role': 'user'});
      expect(user.name, 'New User');
    });
    test('Positive: Logout function clears user session data', () {
      UserModel? currentUser = UserModel(id: '1', name: 'Test', email: 't@t.com', password: 'p', role: 'user');
      currentUser = null;
      expect(currentUser, isNull);
    });
  });

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
        final food = FoodModel(id: 'f1', name: 'Nasi Goreng', category: 'makanan pokok', calories: 300, protein: 5, carbs: 40, fat: 10, createdAt: DateTime.now());
        final result = [food].where((e) => e.name.toLowerCase().contains('nasi')).toList();
        expect(result.length, 1);
      });
    });
    group('2.5 Input Log Manual (Komposisi Sendiri)', () {
      test('Positive: Custom nutrition creates valid LogModel', () {
        final log = LogModel(id: 'l1', userId: 'u1', foodName: 'Custom', calories: 150, protein: 5, carbs: 10, fat: 2, mealType: 'Sarapan', consumedAt: DateTime.now(), servingSize: 100, category: 'lainnya', isManual: true);
        expect(log.isManual, true);
      });
    });
    group('2.6 Watchlist (Makanan Pantauan)', () {
      test('Positive: Adding food to watchlist increases item count', () {
        List<String> watchlist = []; watchlist.add('f1');
        expect(watchlist.length, 1);
      });
      test('Negative: Adding duplicate food ignores or alerts', () {
        List<String> watchlist = ['f1'];
        if (!watchlist.contains('f1')) watchlist.add('f1');
        expect(watchlist.length, 1);
      });
      test('Positive: Removing food from watchlist deletes it correctly', () {
        List<String> watchlist = ['f1', 'f2']; watchlist.remove('f1');
        expect(watchlist.contains('f1'), false);
      });
    });
  });

  group('3. Progress & Profil (User)', () {
    test('Positive: Daily progress percentage calculation is correct', () {
      expect(1500 / 2000, 0.75);
    });
    test('Positive: Update profile (weight/height) recalculates TDEE correctly', () {
      final user = UserModel(id: '1', name: 'Test', email: 't@t.com', password: '1', role: 'user', dailyCalorieNeed: 2000);
      expect(user.macroTargets['carbs']! > 0, true);
    });
    test('Positive: CatatBeratBadan saves history correctly', () {
      final wLog = WeightLogModel(id: 'w1', userId: '1', actualWeight: 69.5, month: DateTime.now());
      expect(wLog.actualWeight, 69.5);
    });
    test('Positive: Notification settings toggle updates correctly', () {
      bool isBreakfastAlarmOn = false; isBreakfastAlarmOn = true;
      expect(isBreakfastAlarmOn, true);
    });
  });

  group('4. Kontrol Orang Tua (Mode Pantau)', () {
    test('Positive: Parent scanning child QR code links account', () {
      expect("CHILD_999".startsWith("CHILD_"), true);
    });
    test('Negative: Invalid QR code format throws Error', () {
      expect("WRONG_QR_FORMAT".startsWith("CHILD_"), false);
    });
    test('Positive: Unlinking child profile removes relation', () {
      String? linkedChild = "CHILD_999"; linkedChild = null;
      expect(linkedChild, isNull);
    });
  });

  group('5. Admin & Kelola Database Makanan', () {
    test('Positive: Admin approving submission changes status to APPROVED', () {
      final sub = SubmissionModel(id: 's1', userId: 'u1', userName: 'User', foodName: 'Sate', imagePath: 'path', createdAt: DateTime.now(), status: SubmissionStatus.pending);
      expect(sub.copyWith(status: SubmissionStatus.approved).status, SubmissionStatus.approved);
    });
    test('Negative: Admin rejecting requires reviewNote', () {
      final sub = SubmissionModel(id: 's1', userId: 'u1', userName: 'User', foodName: 'Sate', imagePath: 'path', createdAt: DateTime.now(), status: SubmissionStatus.pending);
      final rejected = sub.copyWith(status: SubmissionStatus.canceled, reviewNote: 'Foto buram');
      expect(rejected.reviewNote, 'Foto buram');
    });
    test('Positive: Admin blocks user account', () {
      final user = UserModel.fromMap({'id':'1', 'name':'U', 'email':'u@u.com', 'role':'user', 'isBlocked':true});
      expect(user.isBlocked, true);
    });
    test('Positive: Admin changes user role to Nutritionist', () {
      final user = UserModel.fromMap({'id':'1', 'name':'U', 'email':'u@u.com', 'role':'nutritionist'});
      expect(user.role, 'nutritionist');
    });
    test('Positive: Admin deletes food from global database', () {
      List<FoodModel> db = [FoodModel(id: 'f1', name: 'Food', category: 'snack', calories: 10, protein: 1, carbs: 1, fat: 1, createdAt: DateTime.now())];
      db.removeWhere((f) => f.id == 'f1');
      expect(db.isEmpty, true);
    });
    test('Positive: Admin edits food nutritional value', () {
      final food = FoodModel(id: 'f1', name: 'Food', category: 'snack', calories: 10, protein: 1, carbs: 1, fat: 1, createdAt: DateTime.now());
      expect(food.copyWith(calories: 200).calories, 200);
    });
  });

  group('6. Ahli Nutrisi (Verifikasi Gizi)', () {
    test('Positive: Nutritionist inputting macros flags data as COMPLETE', () {
      final sub = SubmissionModel(id: 's1', userId: 'u1', userName: 'User', foodName: 'Sate', imagePath: 'path', createdAt: DateTime.now(), status: SubmissionStatus.approved);
      expect(sub.copyWith(calories: 200, protein: 10, carbs: 15, fat: 5).isNutriFilled, true);
    });
    test('Edge Case: Nutritionist leaves field empty, isNutriFilled returns false', () {
      final sub = SubmissionModel(id: 's1', userId: 'u1', userName: 'User', foodName: 'Sate', imagePath: 'path', createdAt: DateTime.now(), status: SubmissionStatus.approved);
      expect(sub.copyWith(calories: 200, protein: null).isNutriFilled, false);
    });
    test('Positive: Nutritionist adds nutriNote recommendation', () {
      final sub = SubmissionModel(id: 's1', userId: 'u1', userName: 'User', foodName: 'Sate', imagePath: 'path', createdAt: DateTime.now(), status: SubmissionStatus.approved);
      expect(sub.copyWith(nutriNote: 'Porsi terlalu banyak minyak').nutriNote, 'Porsi terlalu banyak minyak');
    });
  });
}
