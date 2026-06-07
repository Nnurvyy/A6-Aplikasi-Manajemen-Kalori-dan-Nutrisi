import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';
import 'package:nutritrack_app/helpers/subscription_helper.dart';
import 'package:nutritrack_app/services/hive_service.dart';

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox(HiveService.settingsBox);
  });

  group('Subscription & Ad Control (SubscriptionHelper)', () {
    final freeUser = UserModel(
      id: 'free_1',
      name: 'Free User',
      email: 'free@nutri.com',
      password: 'pass',
      role: 'user',
      plan: 'free',
    );

    final premiumUser = UserModel(
      id: 'prem_1',
      name: 'Premium User',
      email: 'prem@nutri.com',
      password: 'pass',
      role: 'user',
      plan: 'premium',
      subscriptionEnd: DateTime.now().add(const Duration(days: 30)),
    );

    final expiredPremiumUser = UserModel(
      id: 'prem_exp',
      name: 'Expired Premium User',
      email: 'exp@nutri.com',
      password: 'pass',
      role: 'user',
      plan: 'premium',
      subscriptionEnd: DateTime.now().subtract(const Duration(days: 1)),
    );

    final adminUser = UserModel(
      id: 'admin_1',
      name: 'Admin User',
      email: 'admin@nutri.com',
      password: 'pass',
      role: 'admin',
    );

    group('isPremium tests', () {
      test('Positive: isPremium returns true for Admin and Nutritionist', () {
        expect(SubscriptionHelper.isPremium(adminUser), true);
        
        final nutritionistUser = UserModel(
          id: 'nutri_1', name: 'Nutri User', email: 'nutri@nutri.com', password: 'p', role: 'nutritionist',
        );
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
    });

    group('Gemini Scan Limits tests', () {
      setUp(() async {
        await HiveService.settings.clear();
      });

      test('Positive: canScanGemini is always true for Premium', () {
        expect(SubscriptionHelper.canScanGemini(premiumUser), true);
      });

      test('Positive: canScanGemini allows free user up to 2 scans', () {
        expect(SubscriptionHelper.canScanGemini(freeUser), true);
        
        SubscriptionHelper.incrementGeminiScanCount(freeUser.id); // 1st scan
        expect(SubscriptionHelper.canScanGemini(freeUser), true);
        
        SubscriptionHelper.incrementGeminiScanCount(freeUser.id); // 2nd scan
        expect(SubscriptionHelper.canScanGemini(freeUser), false); // 3rd scan blocked
      });

      test('Positive: shouldShowAdForGemini triggers on second scan', () {
        expect(SubscriptionHelper.shouldShowAdForGemini(freeUser), false);
        
        SubscriptionHelper.incrementGeminiScanCount(freeUser.id); // 1st scan completed
        expect(SubscriptionHelper.shouldShowAdForGemini(freeUser), true); // 2nd scan will show ad
        
        SubscriptionHelper.incrementGeminiScanCount(freeUser.id); // 2nd scan completed
        expect(SubscriptionHelper.shouldShowAdForGemini(freeUser), false);
      });
    });

    group('Groq Search Limits tests', () {
      setUp(() async {
        await HiveService.settings.clear();
      });

      test('Positive: canSearchGroq is always true for Premium', () {
        expect(SubscriptionHelper.canSearchGroq(premiumUser), true);
      });

      test('Positive: canSearchGroq allows free user up to 5 searches', () {
        expect(SubscriptionHelper.canSearchGroq(freeUser), true);
        
        for (int i = 0; i < 4; i++) {
          SubscriptionHelper.incrementGroqSearchCount(freeUser.id);
          expect(SubscriptionHelper.canSearchGroq(freeUser), true);
        }
        
        SubscriptionHelper.incrementGroqSearchCount(freeUser.id); // 5th search completed
        expect(SubscriptionHelper.canSearchGroq(freeUser), false); // 6th search blocked
      });

      test('Positive: shouldShowAdForGroq triggers on 3rd (count 2) and 5th (count 4) searches', () {
        expect(SubscriptionHelper.shouldShowAdForGroq(freeUser), false); // count = 0
        
        SubscriptionHelper.incrementGroqSearchCount(freeUser.id); // count = 1
        expect(SubscriptionHelper.shouldShowAdForGroq(freeUser), false);
        
        SubscriptionHelper.incrementGroqSearchCount(freeUser.id); // count = 2
        expect(SubscriptionHelper.shouldShowAdForGroq(freeUser), true); // 3rd search shows ad
        
        SubscriptionHelper.incrementGroqSearchCount(freeUser.id); // count = 3
        expect(SubscriptionHelper.shouldShowAdForGroq(freeUser), false);
        
        SubscriptionHelper.incrementGroqSearchCount(freeUser.id); // count = 4
        expect(SubscriptionHelper.shouldShowAdForGroq(freeUser), true); // 5th search shows ad
      });
    });
  });
}
