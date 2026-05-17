import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/hive_service.dart';
import '../../general/auth/models/user_model.dart';
import '../../../helpers/calorie_helper.dart';

class AdminUserController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<UserModel> _allUsers = [];
  List<UserModel> _filtered = [];

  int itemsPerPage = 10;
  int currentPage = 0;
  String searchQuery = '';
  bool isSaving = false;

  List<UserModel> get filteredUsers => _filtered;
  int get totalPages => (_filtered.length / itemsPerPage).ceil();
  int get safePage => _filtered.isEmpty ? 0 : currentPage.clamp(0, totalPages - 1);
  
  List<UserModel> get pageItems {
    if (_filtered.isEmpty) return [];
    final start = safePage * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  // ─── LOAD DATA ───
  void loadUsers(String currentAdminId) {
    _allUsers = HiveService.users.values
        .where((u) => u.role == 'user' && u.id != currentAdminId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    applyFilter();
  }

  // ─── SEARCH & PAGINATION ───
  void search(String query) {
    searchQuery = query;
    currentPage = 0;
    applyFilter();
  }

  void setPage(int page) {
    currentPage = page;
    notifyListeners();
  }

  void applyFilter() {
    final q = searchQuery.toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_allUsers);
    } else {
      _filtered = _allUsers.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q)).toList();
    }
    notifyListeners();
  }

  // ─── BLOCK/UNBLOCK (Offline-First) ───
  Future<void> toggleBlock(UserModel user, bool willBlock) async {
    final updated = UserModel(
      id: user.id, 
      name: user.name, 
      email: user.email,
      password: user.password, 
      role: user.role,
      weight: user.weight, 
      height: user.height, 
      age: user.age,
      gender: user.gender, 
      activityLevel: user.activityLevel,
      dailyCalorieNeed: user.dailyCalorieNeed, 
      birthDate: user.birthDate,
      isBlocked: willBlock,
      targetWeightGainPerMonth: user.targetWeightGainPerMonth,
      initialWeight: user.initialWeight, 
      targetHistory: user.targetHistory,
      isSynced: false,
    );
    
    await HiveService.users.put(user.id, updated);
    final index = _allUsers.indexWhere((u) => u.id == user.id);
    if (index != -1) _allUsers[index] = updated;
    applyFilter();

    _db.collection('users').doc(user.id).set({'isBlocked': willBlock}, SetOptions(merge: true))

      .then((_) async {
          
          updated.isSynced = true; 
          await HiveService.users.put(updated.id, updated); 
          
          final idx = _allUsers.indexWhere((u) => u.id == updated.id);
          if (idx != -1) _allUsers[idx] = updated;
          applyFilter(); 
        })

        .catchError((e) {
          debugPrint("Firebase error: $e");
        });
  }

  // ─── DELETE USER (Offline-First) ───
  Future<void> deleteUser(UserModel user) async {
    for (final k in HiveService.logs.keys.toList()) {
      if (HiveService.logs.get(k)?.userId == user.id) await HiveService.logs.delete(k);
    }
    for (final k in HiveService.watchlists.keys.toList()) {
      if (HiveService.watchlists.get(k)?.userId == user.id) await HiveService.watchlists.delete(k);
    }
    for (final k in HiveService.weightLogs.keys.toList()) {
      if (HiveService.weightLogs.get(k)?.userId == user.id) await HiveService.weightLogs.delete(k);
    }
    await HiveService.users.delete(user.id);

    _allUsers.removeWhere((u) => u.id == user.id);
    currentPage = 0;
    applyFilter();

    _db.collection('users').doc(user.id).delete()
        .catchError((e) {
          debugPrint("Firebase error: $e");
        });
  }

  // ─── UPDATE USER (Offline-First) ───
  Future<String?> updateUser(UserModel oldUser, {
    required String name, required String email, required double? weight,
    required double? height, required int? age, required double target,
    required String gender, required String activityLevel,
  }) async {
    final emailExists = HiveService.users.values.any((u) =>
        u.email.toLowerCase() == email.toLowerCase() && u.id != oldUser.id);
    if (emailExists) return 'Email sudah digunakan pengguna lain';

    isSaving = true;
    notifyListeners();

    double? newCalorie = oldUser.dailyCalorieNeed;
    if (weight != null && height != null && age != null) {
      newCalorie = CalorieHelper.calculateDailyCalorieNeed(
        weightKg: weight, heightCm: height, age: age,
        gender: gender, activityLevel: activityLevel,
        targetWeightGainPerMonth: target,
      );
    }

    final updated = UserModel(
      id: oldUser.id, name: name, email: email,
      password: oldUser.password, role: oldUser.role,
      weight: weight, height: height, age: age,
      gender: gender, activityLevel: activityLevel,
      dailyCalorieNeed: newCalorie, birthDate: oldUser.birthDate,
      isBlocked: oldUser.isBlocked,
      targetWeightGainPerMonth: target,
      initialWeight: oldUser.initialWeight,
      targetHistory: oldUser.targetHistory,
      isSynced: false,
    );

    await HiveService.users.put(updated.id, updated);
    final index = _allUsers.indexWhere((u) => u.id == oldUser.id);
    if (index != -1) _allUsers[index] = updated;
    applyFilter();

    
    _db.collection('users').doc(updated.id).set(updated.toMap(), SetOptions(merge: true))

      .then((_) async {
          updated.isSynced = true;
          await HiveService.users.put(updated.id, updated);
          
          final idx = _allUsers.indexWhere((u) => u.id == updated.id);
          if (idx != -1) _allUsers[idx] = updated;
          applyFilter(); 
        })

        .catchError((e) {
          debugPrint("Firebase error: $e");
        });

    isSaving = false;
    notifyListeners();
    return null; 
  }
}