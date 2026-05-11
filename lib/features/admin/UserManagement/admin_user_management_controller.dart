import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/hive_service.dart';
import '../../../helpers/calorie_helper.dart';
import '../../general/auth/auth_controller.dart';
import '../../general/auth/models/user_model.dart';

/// Controller untuk AdminUserManagementView.
/// Memisahkan seluruh logika bisnis (load, filter, block, delete, edit)
/// dari lapisan tampilan.
class AdminUserManagementController extends ChangeNotifier {
  // ─── State ────────────────────────────────────────────────────────────────
  List<UserModel> allUsers  = [];
  List<UserModel> filtered  = [];
  int currentPage           = 0;

  static const int itemsPerPage = 10;

  // ─── Init ─────────────────────────────────────────────────────────────────

  /// Dipanggil dari initState View, membutuhkan context untuk membaca
  /// AuthController (mengetahui ID admin yang sedang login).
  void init(BuildContext context) {
    loadUsers(context);
  }

  // ─── Load & Filter ────────────────────────────────────────────────────────

  void loadUsers(BuildContext context) {
    final currentAdminId =
        context.read<AuthController>().currentUser?.id ?? '';
    allUsers = HiveService.users.values
        .where((u) => u.role == 'user' && u.id != currentAdminId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    applyFilter('');
  }

  void applyFilter(String query) {
    final q = query.toLowerCase();
    filtered = q.isEmpty
        ? List.from(allUsers)
        : allUsers
            .where((u) =>
                u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q))
            .toList();
    currentPage = 0;
    notifyListeners();
  }

  void setPage(int page) {
    currentPage = page;
    notifyListeners();
  }

  // ─── Pagination helpers ───────────────────────────────────────────────────

  int get totalPages =>
      filtered.isEmpty ? 1 : (filtered.length / itemsPerPage).ceil();

  int get safePage =>
      filtered.isEmpty ? 0 : currentPage.clamp(0, totalPages - 1);

  List<UserModel> get pageItems {
    if (filtered.isEmpty) return [];
    final start = safePage * itemsPerPage;
    final end   = (start + itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  // ─── Block / Unblock ──────────────────────────────────────────────────────

  Future<void> toggleBlock(
      BuildContext context, UserModel user) async {
    final willBlock = !user.isBlocked;

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
    );
    await HiveService.users.put(user.id, updated);
    loadUsers(context);
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteUser(BuildContext context, UserModel user) async {
    // Hapus semua data terkait user
    for (final k in HiveService.logs.keys.toList()) {
      if (HiveService.logs.get(k)?.userId == user.id) {
        await HiveService.logs.delete(k);
      }
    }
    for (final k in HiveService.watchlists.keys.toList()) {
      if (HiveService.watchlists.get(k)?.userId == user.id) {
        await HiveService.watchlists.delete(k);
      }
    }
    for (final k in HiveService.weightLogs.keys.toList()) {
      if (HiveService.weightLogs.get(k)?.userId == user.id) {
        await HiveService.weightLogs.delete(k);
      }
    }
    await HiveService.users.delete(user.id);
    loadUsers(context);
  }

  // ─── Save Edit ────────────────────────────────────────────────────────────

  /// Menyimpan perubahan data user ke Hive.
  /// Mengembalikan pesan error (String) jika validasi gagal, atau null jika sukses.
  Future<String?> saveUser({
    required UserModel original,
    required String name,
    required String email,
    required String? weightText,
    required String? heightText,
    required String? ageText,
    required String gender,
    required String activityLevel,
    required String targetText,
  }) async {
    if (name.isEmpty || email.isEmpty) {
      return 'Nama dan email wajib diisi';
    }
    final emailExists = HiveService.users.values.any(
        (u) => u.email.toLowerCase() == email.toLowerCase() &&
               u.id != original.id);
    if (emailExists) {
      return 'Email sudah digunakan pengguna lain';
    }

    final weight = double.tryParse(weightText ?? '');
    final height = double.tryParse(heightText ?? '');
    final age    = int.tryParse(ageText ?? '');
    final target = double.tryParse(targetText) ?? 0;

    double? newCalorie = original.dailyCalorieNeed;
    if (weight != null && height != null && age != null) {
      newCalorie = CalorieHelper.calculateDailyCalorieNeed(
        weightKg: weight,
        heightCm: height,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        targetWeightGainPerMonth: target,
      );
    }

    final updated = UserModel(
      id: original.id,
      name: name,
      email: email,
      password: original.password,
      role: original.role,
      weight: weight,
      height: height,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      dailyCalorieNeed: newCalorie,
      birthDate: original.birthDate,
      isBlocked: original.isBlocked,
      targetWeightGainPerMonth: target,
      initialWeight: original.initialWeight,
      targetHistory: original.targetHistory,
    );
    await HiveService.users.put(updated.id, updated);
    return null; // sukses
  }
}