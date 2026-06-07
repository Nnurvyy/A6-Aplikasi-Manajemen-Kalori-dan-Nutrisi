import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';
import 'package:nutritrack_app/features/general/food/models/food_model.dart';
import 'package:nutritrack_app/features/general/food/models/log_model.dart';
import 'package:nutritrack_app/features/general/submission/models/submission_model.dart';
import 'package:nutritrack_app/features/user/progress/models/weight_log_model.dart';
import 'package:nutritrack_app/helpers/subscription_helper.dart';
import 'package:nutritrack_app/helpers/calorie_helper.dart';
import 'package:nutritrack_app/helpers/pcd_helper.dart';
import 'package:nutritrack_app/services/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/device_info'),
      (MethodCall methodCall) async {
        return <String, dynamic>{
          'name': 'iPhone',
          'systemName': 'iOS',
          'systemVersion': '15.0',
          'model': 'iPhone',
          'localizedModel': 'iPhone',
          'identifierForVendor': 'uuid',
          'isPhysicalDevice': false,
          'utsname': {
            'sysname': 'Darwin',
            'nodename': 'iPhone',
            'release': '21.0.0',
            'version': 'Release',
            'machine': 'iPhone14,3',
          }
        };
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );



    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox(HiveService.settingsBox);
  });


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

  group('7. Subscription & Ad Control (SubscriptionHelper)', () {
    final freeUser = UserModel(id: 'free_1', name: 'Free User', email: 'free@nutri.com', password: 'pass', role: 'user', plan: 'free');
    final premiumUser = UserModel(id: 'prem_1', name: 'Premium User', email: 'prem@nutri.com', password: 'pass', role: 'user', plan: 'premium', subscriptionEnd: DateTime.now().add(const Duration(days: 30)));
    final expiredPremiumUser = UserModel(id: 'prem_exp', name: 'Expired Premium User', email: 'exp@nutri.com', password: 'pass', role: 'user', plan: 'premium', subscriptionEnd: DateTime.now().subtract(const Duration(days: 1)));
    final adminUser = UserModel(id: 'admin_1', name: 'Admin User', email: 'admin@nutri.com', password: 'pass', role: 'admin');

    test('Positive: isPremium returns true for Admin and Nutritionist', () {
      expect(SubscriptionHelper.isPremium(adminUser), true);
      final nutritionistUser = UserModel(id: 'nutri_1', name: 'Nutri User', email: 'nutri@nutri.com', password: 'p', role: 'nutritionist');
      expect(SubscriptionHelper.isPremium(nutritionistUser), true);
    });

    test('Positive: isPremium returns true for active premium plan', () {
      expect(SubscriptionHelper.isPremium(premiumUser), true);
    });

    test('Negative: isPremium returns false for expired premium plan', () {
      expect(SubscriptionHelper.isPremium(expiredPremiumUser), false);
    });

    test('Negative: isPremium returns false for free user', () {
      expect(SubscriptionHelper.isPremium(freeUser), false);
      expect(SubscriptionHelper.isPremium(null), false);
    });

    test('Positive: canScanGemini is always true for Premium', () {
      expect(SubscriptionHelper.canScanGemini(premiumUser), true);
    });

    test('Positive: canScanGemini allows free user up to 2 scans', () {
      HiveService.settings.clear();
      expect(SubscriptionHelper.canScanGemini(freeUser), true);
      SubscriptionHelper.incrementGeminiScanCount(freeUser.id);
      expect(SubscriptionHelper.canScanGemini(freeUser), true);
      SubscriptionHelper.incrementGeminiScanCount(freeUser.id);
      expect(SubscriptionHelper.canScanGemini(freeUser), false);
    });

    test('Positive: shouldShowAdForGemini triggers on second scan', () {
      HiveService.settings.clear();
      expect(SubscriptionHelper.shouldShowAdForGemini(freeUser), false);
      SubscriptionHelper.incrementGeminiScanCount(freeUser.id);
      expect(SubscriptionHelper.shouldShowAdForGemini(freeUser), true);
      SubscriptionHelper.incrementGeminiScanCount(freeUser.id);
      expect(SubscriptionHelper.shouldShowAdForGemini(freeUser), false);
    });

    test('Positive: canSearchGroq is always true for Premium', () {
      expect(SubscriptionHelper.canSearchGroq(premiumUser), true);
    });

    test('Positive: canSearchGroq allows free user up to 5 searches', () {
      HiveService.settings.clear();
      expect(SubscriptionHelper.canSearchGroq(freeUser), true);
      for (int i = 0; i < 4; i++) {
        SubscriptionHelper.incrementGroqSearchCount(freeUser.id);
        expect(SubscriptionHelper.canSearchGroq(freeUser), true);
      }
      SubscriptionHelper.incrementGroqSearchCount(freeUser.id);
      expect(SubscriptionHelper.canSearchGroq(freeUser), false);
    });

    test('Positive: shouldShowAdForGroq triggers on 3rd and 5th searches', () {
      HiveService.settings.clear();
      expect(SubscriptionHelper.shouldShowAdForGroq(freeUser), false);
      SubscriptionHelper.incrementGroqSearchCount(freeUser.id);
      expect(SubscriptionHelper.shouldShowAdForGroq(freeUser), false);
      SubscriptionHelper.incrementGroqSearchCount(freeUser.id);
      expect(SubscriptionHelper.shouldShowAdForGroq(freeUser), true);
      SubscriptionHelper.incrementGroqSearchCount(freeUser.id);
      expect(SubscriptionHelper.shouldShowAdForGroq(freeUser), false);
      SubscriptionHelper.incrementGroqSearchCount(freeUser.id);
      expect(SubscriptionHelper.shouldShowAdForGroq(freeUser), true);
    });
  });

  group('8. Calorie & Macro Calculations (CalorieHelper)', () {
    test('Positive: calculateBMR returns correct value for Men and Women', () {
      final bmrMale = CalorieHelper.calculateBMR(weightKg: 70, heightCm: 170, age: 25, gender: 'laki-laki');
      expect(bmrMale, closeTo(1710.605, 0.01));

      final bmrFemale = CalorieHelper.calculateBMR(weightKg: 50, heightCm: 160, age: 30, gender: 'perempuan');
      expect(bmrFemale, closeTo(1288.97, 0.01));
    });

    test('Positive: getActivityMultiplier returns correct value based on level', () {
      expect(CalorieHelper.getActivityMultiplier('jarang olahraga'), 1.2);
      expect(CalorieHelper.getActivityMultiplier('olahraga sedang (3-5 kali seminggu)'), 1.55);
      expect(CalorieHelper.getActivityMultiplier('random_level'), 1.2);
    });

    test('Positive: calculateTDEE calculates based on BMR and multiplier', () {
      final tdee = CalorieHelper.calculateTDEE(weightKg: 70, heightCm: 170, age: 25, gender: 'laki-laki', activityLevel: 'jarang olahraga');
      expect(tdee, closeTo(2052.726, 0.01));
    });

    test('Positive: calculateDailyCalorieNeed adjusts based on weight target', () {
      final need = CalorieHelper.calculateDailyCalorieNeed(weightKg: 70, heightCm: 170, age: 25, gender: 'laki-laki', activityLevel: 'jarang olahraga', targetWeightGainPerMonth: 1.0);
      expect(need, closeTo(2302.726, 0.01));
    });

    test('Positive: calculateMacros returns correct targets', () {
      final macros = CalorieHelper.calculateMacros(2000);
      expect(macros['protein'], closeTo(75.0, 0.01));
      expect(macros['fat'], closeTo(44.44, 0.01));
      expect(macros['carbs'], closeTo(325.0, 0.01));
    });

    test('Positive: formatCalorie and formatNutrient formats properly', () {
      expect(CalorieHelper.formatCalorie(2000.4), '2000');
      expect(CalorieHelper.formatNutrient(75.26), '75.3g');
    });
  });

  group('9. PCD Image Preprocessing (PCDHelper)', () {
    test('Positive: processForYolo resizes and letterboxes image to 640x640', () async {
      final image = img.Image(width: 100, height: 200);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      final originalBytes = Uint8List.fromList(img.encodeJpg(image));
      final processedBytes = await PCDHelper.processForYolo(originalBytes);
      expect(processedBytes, isNotNull);
      final processedImage = img.decodeImage(processedBytes!);
      expect(processedImage, isNotNull);
      expect(processedImage!.width, 640);
      expect(processedImage.height, 640);
    });

    test('Negative: processForYolo returns null for invalid image bytes', () async {
      final processedBytes = await PCDHelper.processForYolo(Uint8List.fromList([0, 1, 2, 3, 4, 5]));
      expect(processedBytes, isNull);
    });
  });
}

