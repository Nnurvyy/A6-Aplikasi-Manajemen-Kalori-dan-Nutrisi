import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:nutritrack_app/features/general/submission/models/submission_model.dart';
import 'package:nutritrack_app/features/general/submission/models/pending_submission_model.dart';
import 'package:nutritrack_app/services/submission_firebase_service.dart';
import 'package:nutritrack_app/services/hive_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Controller global yang di-share antara User, Admin, dan Nutritionist.
///
/// Offline-first flow:
/// 1. User submit → simpan ke Hive (antrian lokal) + tampil di list
/// 2. Upload gambar (jika ada) ke Cloudinary + simpan data ke Firestore di background
/// 3. Berhasil → hapus dari Hive, item sekarang hidup dari stream Firestore
/// 4. App ditutup sebelum upload selesai → Hive tetap ada
/// 5. Buka app lagi → init() baca Hive, retry upload yang tertunda otomatis
/// 6. Saat offline → item tetap di Hive; listener konektivitas otomatis retry saat online lagi
class SubmissionController extends ChangeNotifier {
  List<SubmissionModel> _cloudItems = [];
  List<SubmissionModel> _localItems = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isRetrying = false;

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
    _currentUserId = userId;
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
      _retryPendingUploads(userId);

      _connectivitySub?.cancel();
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final isOnline = results.any((r) => r != ConnectivityResult.none);
        if (isOnline && !_isRetrying) {
          debugPrint('[Connectivity] Kembali online — retry pending uploads');
          _retryPendingUploads(userId);
        }
      });
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
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
      imagePath: p.localImagePath,
      status: SubmissionStatus.pending,
      createdAt: p.createdAt,
      isSynced: false,
    );
  }

  Future<void> _retryPendingUploads(String userId) async {
    if (_isRetrying) return;
    _isRetrying = true;
    final pending =
        HiveService.pendingSubs.values
            .where((p) => p.userId == userId)
            .toList();
    for (final p in pending) {
      await _uploadToCloud(p);
    }
    _isRetrying = false;
  }

  // ── User: ajukan makanan ──────────────────────────────────────────────────

  Future<void> addSubmission({
    required String userId,
    required String userName,
    required String foodName,
    String localImagePath = '',
  }) async {
    debugPrint('[addSubmission] Dipanggil: $foodName');
    final id = 'sub_${DateTime.now().millisecondsSinceEpoch}';

    final pendingModel = PendingSubmissionModel(
      id: id,
      userId: userId,
      userName: userName,
      foodName: foodName,
      localImagePath: localImagePath,
      createdAt: DateTime.now(),
    );

    await HiveService.pendingSubs.put(id, pendingModel);
    debugPrint('[addSubmission] Tersimpan di Hive: $id');

    _localItems.insert(0, _pendingToModel(pendingModel));
    notifyListeners();

    unawaited(
      _uploadToCloud(pendingModel).catchError((e) {
        debugPrint('[Upload] Background error tertangkap: $e');
      }),
    );
  }

  Future<void> _uploadToCloud(PendingSubmissionModel p) async {
    debugPrint('[Upload] Mulai upload: ${p.id} – ${p.foodName}');
    try {
      final imageUrl = await SubmissionFirebaseService.uploadImage(
        p.localImagePath,
        p.id,
        onProgress: (progress) {
          debugPrint('[Upload] Progress: ${(progress * 100).toInt()}%');
        },
      );
      debugPrint('[Upload] imageUrl: "$imageUrl"');

      final model = SubmissionModel(
        id: p.id,
        userId: p.userId,
        userName: p.userName,
        foodName: p.foodName,
        imagePath: imageUrl,
        status: SubmissionStatus.pending,
        createdAt: p.createdAt,
        isSynced: true,
      );

      await SubmissionFirebaseService.add(model);
      debugPrint('[Upload] Berhasil simpan ke Firestore: ${p.id}');

      await HiveService.pendingSubs.delete(p.id);
      _localItems.removeWhere((e) => e.id == p.id);
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[Upload] GAGAL: $e');
      _error =
          'Upload gagal untuk "${p.foodName}". Akan dicoba ulang saat online.';
      notifyListeners();
    }
  }

  // ── User: hapus pengajuan yang masih pending ──────────────────────────────

  Future<void> deleteSubmission(SubmissionModel item) async {
    debugPrint('[deleteSubmission] Hapus: ${item.id}');
    try {
      if (!item.isSynced) {
        await HiveService.pendingSubs.delete(item.id);
        _localItems.removeWhere((e) => e.id == item.id);
        notifyListeners();
      } else {
        await SubmissionFirebaseService.delete(item.id);
      }
    } catch (e) {
      _error = 'Gagal menghapus pengajuan: $e';
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
      final updates = <String, dynamic>{
        'status': newStatus.name,
        if (reviewNote != null) 'reviewNote': reviewNote,
      };

      // Catat waktu admin meneruskan ke ahli gizi
      if (newStatus == SubmissionStatus.approved) {
        updates['forwardedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await SubmissionFirebaseService.update(id, updates);
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

      // Cari item di cloud untuk simpan ke collection foods
      final item = _cloudItems.where((s) => s.id == id).firstOrNull;
      if (item != null) {
        final updatedItem = item.copyWith(
          foodName: foodName,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          nutriNote: nutriNote,
        );
        // Simpan ke collection foods agar langsung masuk database global
        await SubmissionFirebaseService.saveNutriToFoods(updatedItem);
        debugPrint(
          '[saveNutriData] Berhasil simpan ke foods: ${updatedItem.foodName}',
        );
      }
    } catch (e) {
      _error = 'Gagal menyimpan data nutrisi: $e';
      notifyListeners();
    }
  }
}
