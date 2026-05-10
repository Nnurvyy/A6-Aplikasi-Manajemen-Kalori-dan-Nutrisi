import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'submission_model.dart';
import 'model/pending_submission_model.dart';
import '../../../services/submission_firebase_service.dart';
import '../../../services/hive_service.dart';

/// Controller global yang di-share antara User, Admin, dan Nutritionist.
///
/// Offline-first flow:
/// 1. User submit → langsung simpan ke Hive (antrian lokal) + tampil di list
/// 2. Upload gambar ke Cloudinary + simpan data ke Firestore di background
/// 3. Berhasil → hapus dari Hive, item sekarang hidup dari stream Firestore
/// 4. App ditutup sebelum upload selesai → Hive tetap ada
/// 5. Buka app lagi → init() baca Hive, retry upload yang tertunda otomatis
class SubmissionController extends ChangeNotifier {
  List<SubmissionModel> _cloudItems = [];
  List<SubmissionModel> _localItems = [];
  bool _isLoading = false;
  String? _error;

  // ── Public getters ────────────────────────────────────────────────────────

  /// Gabungan: item lokal (belum sync) di depan + item cloud
  List<SubmissionModel> get all {
    final cloudIds = _cloudItems.map((e) => e.id).toSet();
    final onlyLocal = _localItems.where((e) => !cloudIds.contains(e.id));
    return [...onlyLocal, ..._cloudItems];
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<SubmissionModel> byUser(String userId) =>
      all.where((s) => s.userId == userId).toList();

  List<SubmissionModel> get pending =>
      all.where((s) => s.status == SubmissionStatus.pending).toList();

  List<SubmissionModel> get approved =>
      all.where((s) => s.status == SubmissionStatus.approved).toList();

  List<SubmissionModel> get approvedNeedsFill =>
      approved.where((s) => !s.isNutriFilled).toList();

  List<SubmissionModel> get approvedFilled =>
      approved.where((s) => s.isNutriFilled).toList();

  List<SubmissionModel> get canceled =>
      all.where((s) => s.status == SubmissionStatus.canceled).toList();

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init({required String role, required String userId}) async {
    debugPrint('[Controller] init() dipanggil — role: $role, userId: $userId');
    _setLoading(true);
    _loadLocalQueue(userId);

    final stream =
        (role == 'admin' || role == 'nutritionist')
            ? SubmissionFirebaseService.streamAll()
            : SubmissionFirebaseService.streamByUser(userId);

    stream.listen(
      (cloudItems) {
        debugPrint('[Controller] Stream dapat ${cloudItems.length} item');
        _cloudItems = cloudItems;
        _error = null;
        _setLoading(false);
        _cleanSyncedLocalItems();
      },
      onError: (e) {
        debugPrint('[Controller] Stream ERROR: $e');
        _error = 'Gagal memuat data: $e';
        _setLoading(false);
      },
    );

    if (role == 'user') {
      // Retry sequential — satu per satu agar tidak race condition
      _retryPendingUploads(userId);
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // ── Hive queue helpers ────────────────────────────────────────────────────

  void _loadLocalQueue(String userId) {
    _localItems =
        HiveService.pendingSubs.values
            .where((p) => p.userId == userId)
            .map(_pendingToModel)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void _cleanSyncedLocalItems() {
    final cloudIds = _cloudItems.map((e) => e.id).toSet();
    final toDelete =
        HiveService.pendingSubs.values
            .where((p) => cloudIds.contains(p.id))
            .map((p) => p.key)
            .toList();
    for (final key in toDelete) {
      HiveService.pendingSubs.delete(key);
    }
    _localItems.removeWhere((e) => cloudIds.contains(e.id));
    notifyListeners();
  }

  SubmissionModel _pendingToModel(PendingSubmissionModel p) {
    return SubmissionModel(
      id: p.id,
      userId: p.userId,
      userName: p.userName,
      foodName: p.foodName,
      imagePath: p.localImagePath, // path lokal sementara sebelum sync
      status: SubmissionStatus.pending,
      createdAt: p.createdAt,
      isSynced: false,
    );
  }

  // Retry sequential — await satu per satu agar tidak paralel
  Future<void> _retryPendingUploads(String userId) async {
    final pending =
        HiveService.pendingSubs.values
            .where((p) => p.userId == userId)
            .toList();
    for (final p in pending) {
      await _uploadToCloud(p);
    }
  }

  // ── User: ajukan makanan ──────────────────────────────────────────────────

  Future<void> addSubmission({
    required String userId,
    required String userName,
    required String foodName,
    required String localImagePath,
  }) async {
    debugPrint('[addSubmission] Dipanggil: $foodName');
    final id = 'sub_${DateTime.now().millisecondsSinceEpoch}';

    final pending = PendingSubmissionModel(
      id: id,
      userId: userId,
      userName: userName,
      foodName: foodName,
      localImagePath: localImagePath,
      createdAt: DateTime.now(),
    );

    await HiveService.pendingSubs.put(id, pending);
    debugPrint('[addSubmission] Tersimpan di Hive: $id');

    _localItems.insert(0, _pendingToModel(pending));
    notifyListeners();

    // Upload berjalan di background, error ditangkap agar tidak Unhandled Exception
    debugPrint('[addSubmission] Memanggil _uploadToCloud...');
    unawaited(
      _uploadToCloud(pending).catchError((e) {
        debugPrint('[Upload] Background error tertangkap: $e');
      }),
    );
  }

  Future<void> _uploadToCloud(PendingSubmissionModel p) async {
    debugPrint('[Upload] Mulai upload ke Cloudinary: ${p.id} – ${p.foodName}');
    try {
      // Jika file lokal tidak ada, jangan hapus dari Hive
      if (!File(p.localImagePath).existsSync()) {
        debugPrint('[Upload] File tidak ditemukan: ${p.localImagePath}');
        _error =
            'File gambar tidak ditemukan untuk "${p.foodName}". '
            'Silakan coba submit ulang.';
        notifyListeners();
        return;
      }

      // Upload gambar ke Cloudinary — dapat URL permanen
      final imageUrl = await SubmissionFirebaseService.uploadImage(
        p.localImagePath,
        p.id,
        onProgress: (progress) {
          debugPrint('[Upload] Progress: ${(progress * 100).toInt()}%');
        },
      );
      debugPrint('[Upload] Cloudinary berhasil: $imageUrl');

      // Simpan data submission + URL gambar ke Firestore
      final model = SubmissionModel(
        id: p.id,
        userId: p.userId,
        userName: p.userName,
        foodName: p.foodName,
        imagePath: imageUrl, // URL Cloudinary permanen
        status: SubmissionStatus.pending,
        createdAt: p.createdAt,
        isSynced: true,
      );

      await SubmissionFirebaseService.add(model);
      debugPrint('[Upload] Berhasil simpan ke Firestore: ${p.id}');

      // Hapus dari Hive setelah berhasil
      await HiveService.pendingSubs.delete(p.id);
      _localItems.removeWhere((e) => e.id == p.id);
      _error = null;
      notifyListeners();
    } catch (e) {
      // Error ditangkap — item tetap di Hive untuk retry berikutnya
      debugPrint('[Upload] GAGAL: $e');
      _error = 'Upload gagal untuk "${p.foodName}". Akan dicoba ulang.';
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

  // ── Nutritionist: isi data nutrisi ───────────────────────────────────────

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
