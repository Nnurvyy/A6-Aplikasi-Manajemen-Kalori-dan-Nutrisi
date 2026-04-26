import 'package:hive_flutter/hive_flutter.dart';
import '../features/auth/models/user_model.dart';
import '../features/food/models/food_model.dart';
import '../features/food/models/log_model.dart';


class HiveService {
  static const String userBox = 'users';
  static const String foodBox = 'foods';

  static const String logBox = 'logs';

  static const String settingsBox = 'settings';

  static Future<void> initBoxes() async {

    Hive.registerAdapter(LogModelAdapter());

    await Hive.openBox<UserModel>(userBox);
    await Hive.openBox<FoodModel>(foodBox);
    await Hive.openBox<LogModel>(logBox);
    await Hive.openBox(settingsBox);
  }

  static Box<UserModel> get users => Hive.box<UserModel>(userBox);
  static Box<FoodModel> get foods => Hive.box<FoodModel>(foodBox);
  static Box<LogModel> get logs => Hive.box<LogModel>(logBox);
  static Box get settings => Hive.box(settingsBox);
}
