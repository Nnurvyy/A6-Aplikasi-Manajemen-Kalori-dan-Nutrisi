import 'package:hive_flutter/hive_flutter.dart';
import '../features/auth/models/user_model.dart';
import '../features/food/models/food_model.dart';


class HiveService {
  static const String userBox = 'users';
  static const String foodBox = 'foods';

  static const String settingsBox = 'settings';

  static Future<void> initBoxes() async {
    await Hive.openBox<UserModel>(userBox);
    await Hive.openBox<FoodModel>(foodBox);

    await Hive.openBox(settingsBox);
  }

  static Box<UserModel> get users => Hive.box<UserModel>(userBox);
  static Box<FoodModel> get foods => Hive.box<FoodModel>(foodBox);

  static Box get settings => Hive.box(settingsBox);
}
