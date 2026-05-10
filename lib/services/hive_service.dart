import 'package:hive_flutter/hive_flutter.dart';
import '../features/general/auth/models/user_model.dart';
import '../features/general/food/models/food_model.dart';
import '../features/general/food/models/log_model.dart';
import '../features/user/progress/models/weight_log_model.dart';
import '../features/general/submission/model/pending_submission_model.dart';

class HiveService {
  static const String userBox = 'users';
  static const String foodBox = 'foods';
  static const String logBox = 'logs';
  static const String settingsBox = 'settings';
  static const String watchlistBox = 'watchlists';
  static const String weightLogBox = 'weight_logs';
  static const String pendingSubBox = 'pending_submissions'; // ← BARU

  static Future<void> initBoxes() async {
    await Hive.openBox<UserModel>(userBox);
    await Hive.openBox<FoodModel>(foodBox);
    await Hive.openBox<LogModel>(logBox);
    await Hive.openBox<dynamic>(settingsBox);
    await Hive.openBox<dynamic>(watchlistBox);
    await Hive.openBox<WeightLogModel>(weightLogBox);
    await Hive.openBox<PendingSubmissionModel>(pendingSubBox); // ← BARU
  }

  static Box<UserModel> get users => Hive.box<UserModel>(userBox);
  static Box<FoodModel> get foods => Hive.box<FoodModel>(foodBox);
  static Box<LogModel> get logs => Hive.box<LogModel>(logBox);
  static Box get settings => Hive.box(settingsBox);
  static Box get watchlists => Hive.box(watchlistBox);
  static Box<WeightLogModel> get weightLogs =>
      Hive.box<WeightLogModel>(weightLogBox);
  static Box<PendingSubmissionModel> get pendingSubs =>
      Hive.box<PendingSubmissionModel>(pendingSubBox); // ← BARU
}
