import 'dart:io';
import 'package:flutter/material.dart';
import 'submission_model.dart';
import '../../../services/submission_firebase_service.dart';

/// Controller global yang di-share antara User, Admin, dan Nutritionist.
/// Data bersumber dari Firestore (realtime stream) — tidak ada Hive di sini.
/// Mendukung offline-first: item langsung muncul di list sebelum upload selesai.
class SubmissionController extends ChangeNotifier {
  List<SubmissionModel> _items = [];
  bool _isLoading = false;
  String? _error;

  // ── Public getters ────────────────────────────────────────────────────────

  List<SubmissionModel> get all => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Semua submission milik user tertentu
  List<SubmissionModel> byUser(String userId) =>
      _items.where((s) => s.userId == userId).toList();

  List<SubmissionModel> get pending =>
      _items.where((s) => s.status == SubmissionStatus.pending).toList();

  List<SubmissionModel> get approved =>
      _items.where((s) => s.status == SubmissionStatus.approved).toList();

  List<SubmissionModel> get approvedNeedsFill =>
      approved.where((s) => !s.isNutriFilled).toList();

  List<SubmissionModel> get approvedFilled =>
      approved.where((s) => s.isNutriFilled).toList();

  List<SubmissionModel> get canceled =>
      _items.where((s) => s.status == SubmissionStatus.canceled).toList();

  // ── Init: panggil setelah user login, tentukan stream sesuai role ─────────

  /// [role] : 'admin' | 'nutritionist' → stream semua submission
  ///          'user'                   → stream milik userId saja
  Future<void> init({required String role, required String userId}) async {
    _setLoading(true);

    final stream =
        (role == 'admin' || role == 'nutritionist')
            ? SubmissionFirebaseService.streamAll()
            : SubmissionFirebaseService.streamByUser(userId);

    stream.listen(
      (cloudItems) {
        // Gabungkan: item cloud yang sudah sync + item lokal yang belum sync
        // (supaya item optimistic tidak hilang saat stream update pertama kali)
        final unsyncedIds =
            _items.where((i) => !i.isSynced).map((i) => i.id).toSet();

        final unsynced = _items.where((i) => !i.isSynced).toList();

        // Buang item unsynced dari cloud jika sudah masuk (replace by stream)
        final merged = [
          ...unsynced.where((u) => !cloudItems.any((c) => c.id == u.id)),
          ...cloudItems,
        ];

        // Sort by createdAt descending
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _items = merged;
        _error = null;
        _setLoading(false);
      },
      onError: (e) {
        _error = 'Gagal memuat data: $e';
        _setLoading(false);
      },
    );
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // ── User: ajukan makanan (offline-first / optimistic UI) ──────────────────

  Future<void> addSubmission({
    required String userId,
    required String userName,
    required String foodName,
    required String localImagePath,
  }) async {
    final id = 'sub_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Langsung tampilkan di list pakai path lokal (optimistic)
    //    isSynced = false → card tampilkan ikon "belum ke cloud"
    final localModel = SubmissionModel(
      id: id,
      userId: userId,
      userName: userName,
      foodName: foodName,
      imagePath: localImagePath,
      status: SubmissionStatus.pending,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    _items.insert(0, localModel);
    notifyListeners();

    try {
      // 2. Upload foto ke Firebase Storage → dapat URL
      final imageUrl = await SubmissionFirebaseService.uploadImage(
        localImagePath,
        id,
      );

      // 3. Simpan ke Firestore dengan URL cloud
      final cloudModel = localModel.copyWith(
        imagePath: imageUrl,
        isSynced: true,
      );
      await SubmissionFirebaseService.add(cloudModel);

      // 4. Update item lokal sementara pakai URL cloud
      //    (stream akan replace ini otomatis, tapi ini buat langsung refresh gambar)
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx != -1) {
        _items[idx] = cloudModel;
        notifyListeners();
      }
    } catch (e) {
      // Gagal → tandai item sebagai belum sync, biarkan tetap tampil di list
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx != -1) {
        _items[idx] = localModel.copyWith(isSynced: false);
        notifyListeners();
      }
      _error = 'Gagal mengirim pengajuan: $e';
      notifyListeners();
    }
  }

  // ── Admin: terima / tolak ─────────────────────────────────────────────────

  Future<void> reviewSubmission({
    required String id,
    required SubmissionStatus newStatus,
    String? reviewNote,
  }) async {
    try {
      await SubmissionFirebaseService.update(id, {
        'status': newStatus.name,
        if (reviewNote != null) 'reviewNote': reviewNote,
      });
    } catch (e) {
      _error = 'Gagal memperbarui status: $e';
      notifyListeners();
    }
  }

  // ── Nutritionist: isi / update data nutrisi ───────────────────────────────

  Future<void> saveNutriData({
    required String id,
    String? foodName,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String? nutriNote,
  }) async {
    try {
      await SubmissionFirebaseService.update(id, {
        if (foodName != null) 'foodName': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        if (nutriNote != null) 'nutriNote': nutriNote,
      });
    } catch (e) {
      _error = 'Gagal menyimpan data nutrisi: $e';
      notifyListeners();
    }
  }
}
