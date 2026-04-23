import 'package:flutter/material.dart';
import 'models/user_model.dart';
import '../../services/hive_service.dart';
import '../../helpers/calorie_helper.dart';

class AuthController extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthController() {
    _restoreSession();
  }

  void _restoreSession() {
    final savedId =
        HiveService.settings.get('current_user_id') as String?;
    if (savedId != null) {
      _currentUser = HiveService.users.get(savedId);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    await Future.delayed(const Duration(milliseconds: 500));

    final user = HiveService.users.values.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase() &&
             u.password == password,
      orElse: () => UserModel(
        id: '__not_found__',
        name: '',
        email: '',
        password: '',
        role: '',
      ),
    );
    final found = user.id != '__not_found__';
    if (!found) {
      _errorMessage = 'Email atau password salah';
      _setLoading(false);
      return false;
    }

    if (user.isBlocked) {
      _errorMessage = 'Akun Anda telah diblokir. Hubungi admin.';
      _setLoading(false);
      return false;
    }

    _currentUser = user;
    await HiveService.settings.put('current_user_id', user.id);
    _setLoading(false);
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required String medicalHistory,
    required DateTime birthDate,
    double targetWeightGainPerMonth = 0,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    // Cek email duplikat
    final exists = HiveService.users.values
        .any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) {
      _errorMessage = 'Email sudah terdaftar';
      _setLoading(false);
      return false;
    }

    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final dailyCalorieNeed = CalorieHelper.calculateDailyCalorieNeed(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      targetWeightGainPerMonth: targetWeightGainPerMonth,
    );

    final newUser = UserModel(
      id: id,
      name: name,
      email: email,
      password: password,
      role: 'user',
      weight: weight,
      height: height,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      medicalHistory: medicalHistory,
      birthDate: birthDate,
      dailyCalorieNeed: dailyCalorieNeed,
      targetWeightGainPerMonth: targetWeightGainPerMonth,
    );

    await HiveService.users.put(id, newUser);
    _currentUser = newUser;
    await HiveService.settings.put('current_user_id', id);
    _setLoading(false);
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    await HiveService.settings.delete('current_user_id');
    notifyListeners();
  }

  Future<void> updateProfile(UserModel updated) async {
    await HiveService.users.put(updated.id, updated);
    if (_currentUser?.id == updated.id) {
      _currentUser = updated;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
