import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'submission_model.dart';
import '../../../services/submission_firebase_service.dart';

/// Controller global yang di-share antara User, Admin, dan Nutritionist.
/// Data bersumber dari Firestore (realtime stream) — tidak ada Hive di sini.
class SubmissionController extends ChangeNotifier {
  List<SubmissionModel> _items = [];
  bool _isLoading = false;
  String? _error;

  // Stream subscription agar bisa di-cancel saat dispose
  Stream<List<SubmissionModel>>? _activeStream;

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

    // Pilih stream yang tepat
    final stream =
        (role == 'admin' || role == 'nutritionist')
            ? SubmissionFirebaseService.streamAll()
            : SubmissionFirebaseService.streamByUser(userId);

    // Dengarkan perubahan Firestore secara realtime
    stream.listen(
      (items) {
        _items = items;
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

  // ── User: ajukan makanan ──────────────────────────────────────────────────

  Future<void> addSubmission({
    required String userId,
    required String userName,
    required String foodName,
    required String localImagePath, // path file lokal dari kamera/galeri
  }) async {
    _setLoading(true);
    try {
      final id = 'sub_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Upload foto ke Firebase Storage, dapat URL
      final imageUrl = await SubmissionFirebaseService.uploadImage(
        localImagePath,
        id,
      );

      // 2. Simpan dokumen ke Firestore
      final model = SubmissionModel(
        id: id,
        userId: userId,
        userName: userName,
        foodName: foodName,
        imagePath: imageUrl, // URL cloud, bukan path lokal
        status: SubmissionStatus.pending,
        createdAt: DateTime.now(),
      );

      await SubmissionFirebaseService.add(model);
      // Stream akan otomatis update _items — tidak perlu notifyListeners manual
    } catch (e) {
      _error = 'Gagal mengirim pengajuan: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
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
