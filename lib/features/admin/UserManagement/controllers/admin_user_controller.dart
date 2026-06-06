import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutritrack_app/services/hive_service.dart';
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';
import 'package:nutritrack_app/helpers/calorie_helper.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AdminUserController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<UserModel> _allUsers = [];
  List<UserModel> _filtered = [];

  int itemsPerPage = 10;
  int currentPage = 0;
  String searchQuery = '';
  bool isSaving = false;
  final Set<String> _downloadingUserIds = {};

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
  Future <void> loadUsers(String currentAdminId) async {
    
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();

      _allUsers = snapshot.docs.map((doc) {
        
        final data = doc.data();
        
        data['id'] = doc.id; 
        data['isSynced'] = true;
        
        return UserModel.fromMap(data);
      }).where((u) => u.id != currentAdminId).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      for (var user in _allUsers) {
        await HiveService.users.put(user.id, user);
      }

    applyFilter();

    } catch (e) {
      debugPrint("Gagal mengambil data user dari Firebase: $e");
    }
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
    final updated = user.copyWith(
      isBlocked: willBlock,
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

    final updated = oldUser.copyWith(
      name: name,
      email: email,
      weight: weight,
      height: height,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      dailyCalorieNeed: newCalorie,
      targetWeightGainPerMonth: target,
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

  // ─── DOWNLOAD & CACHE PROFILE IMAGE (Offline-First) ───
  Future<void> downloadAndCacheProfileImage(UserModel user) async {
    if (user.profileImageUrl == null || user.profileImageUrl!.isEmpty) return;
    
    // Check if it's already downloaded/exists
    if (user.localProfileImagePath != null && File(user.localProfileImagePath!).existsSync()) {
      return;
    }
    
    if (_downloadingUserIds.contains(user.id)) return;
    _downloadingUserIds.add(user.id);
    
    try {
      final response = await http.get(Uri.parse(user.profileImageUrl!));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final tempDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        final updated = user.copyWith(
          localProfileImagePath: file.path,
        );
        
        // Save to Hive
        await HiveService.users.put(updated.id, updated);
        
        // Update in memory list
        final index = _allUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _allUsers[index] = updated;
        }
        applyFilter();
      }
    } catch (e) {
      debugPrint("Gagal mendownload foto profil: $e");
    } finally {
      _downloadingUserIds.remove(user.id);
    }
  }
}