import 'package:hive_flutter/hive_flutter.dart';
import '../features/auth/models/user_model.dart';

class HiveService {
  static const String userBox = 'users';


  static Future<void> init() async {
    await Hive.openBox<UserModel>(userBox);
  }

  static Box<UserModel> get users => Hive.box<UserModel>(userBox);
 
}
