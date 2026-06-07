import 'package:intl/intl.dart';
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';
import 'package:nutritrack_app/services/hive_service.dart';

class SubscriptionHelper {
  /// Check if the user has an active premium subscription.
  static bool isPremium(UserModel? user) {
    if (user == null) return false;
    // Admins and nutritionists automatically enjoy premium privileges
    if (user.role == 'admin' || user.role == 'nutritionist') return true;
    
    if (user.plan == 'premium') {
      final now = DateTime.now();
      if (user.subscriptionEnd == null || user.subscriptionEnd!.isAfter(now)) {
        return true;
      }
    }
    return false;
  }

  static String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Get total Gemini scans completed today by the user.
  static int getGeminiScanCount(String userId) {
    final key = 'gemini_scan_count_${userId}_$_todayKey';
    return HiveService.settings.get(key, defaultValue: 0) as int;
  }

  /// Increment the Gemini scan counter for today.
  static void incrementGeminiScanCount(String userId) {
    final key = 'gemini_scan_count_${userId}_$_todayKey';
    final current = getGeminiScanCount(userId);
    HiveService.settings.put(key, current + 1);
  }

  /// Get total Groq AI searches completed today by the user.
  static int getGroqSearchCount(String userId) {
    final key = 'groq_search_count_${userId}_$_todayKey';
    return HiveService.settings.get(key, defaultValue: 0) as int;
  }

  /// Increment the Groq AI search counter for today.
  static void incrementGroqSearchCount(String userId) {
    final key = 'groq_search_count_${userId}_$_todayKey';
    final current = getGroqSearchCount(userId);
    HiveService.settings.put(key, current + 1);
  }

  /// Returns true if the user can scan with Gemini (premium or scans < 2).
  static bool canScanGemini(UserModel? user) {
    if (isPremium(user)) return true;
    final userId = user?.id ?? '';
    return getGeminiScanCount(userId) < 2;
  }

  /// Returns true if the next scan triggers the 15-second ad (meaning they have scanned 1 time already).
  static bool shouldShowAdForGemini(UserModel? user) {
    if (isPremium(user)) return false;
    final userId = user?.id ?? '';
    return getGeminiScanCount(userId) == 1; // Count index 1 represents the 2nd scan of the day
  }

  /// Returns true if the user can search with Groq AI (premium or searches < 5).
  static bool canSearchGroq(UserModel? user) {
    if (isPremium(user)) return true;
    final userId = user?.id ?? '';
    return getGroqSearchCount(userId) < 5;
  }

  /// Returns true if the next search triggers the 15-second ad (meaning they are executing their 3rd or 5th search).
  static bool shouldShowAdForGroq(UserModel? user) {
    if (isPremium(user)) return false;
    final userId = user?.id ?? '';
    final count = getGroqSearchCount(userId);
    return count == 2 || count == 4; // 3rd search is count index 2, 5th search is count index 4
  }
}
