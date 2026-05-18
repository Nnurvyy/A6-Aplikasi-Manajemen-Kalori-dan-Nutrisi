import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
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
/// 6. Koneksi kembali → listener connectivity trigger retry otomatis
class SubmissionController extends ChangeNotifier {
  List<SubmissionModel> _cloudItems = [];
  List<SubmissionModel> _localItems = [];
  bool _isLoading = false;
  String? _error;

  // FIX 2: Listener connectivity untuk retry otomatis saat online kembali
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isRetrying = false;
  String? _currentUserId;

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
      // Retry saat init
      _retryPendingUploads(userId);

      // FIX 2: Subscribe connectivity — retry otomatis saat online kembali
      _connectivitySub?.cancel();
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final isOnline = results.any((r) => r != ConnectivityResult.none);
        if (isOnline && !_isRetrying) {
          debugPrint('[Controller] Koneksi kembali — retry pending uploads...');
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

  // FIX 2: Flag _isRetrying supaya tidak paralel
  Future<void> _retryPendingUploads(String userId) async {
    if (_isRetrying) return;
    _isRetrying = true;
    try {
      final pending =
          HiveService.pendingSubs.values
              .where((p) => p.userId == userId)
              .toList();
      debugPrint('[Retry] ${pending.length} item pending ditemukan');
      for (final p in pending) {
        await _uploadToCloud(p);
      }
    } finally {
      _isRetrying = false;
    }
  }

  // ── User: ajukan makanan ──────────────────────────────────────────────────

  Future<void> addSubmission({
    required String userId,
    required String userName,
    required String foodName,
    required String localImagePath, // boleh kosong string jika tanpa foto
  }) async {
    debugPrint('[addSubmission] Dipanggil: $foodName');
    final id = 'sub_${DateTime.now().millisecondsSinceEpoch}';

    final pending = PendingSubmissionModel(
      id: id,
      userId: userId,
      userName: userName,
      foodName: foodName,
      localImagePath: localImagePath, // '' jika tidak ada foto
      createdAt: DateTime.now(),
    );

    await HiveService.pendingSubs.put(id, pending);
    debugPrint('[addSubmission] Tersimpan di Hive: $id');

    _localItems.insert(0, _pendingToModel(pending));
    notifyListeners();

    unawaited(
      _uploadToCloud(pending).catchError((e) {
        debugPrint('[Upload] Background error tertangkap: $e');
      }),
    );
  }

  Future<void> _uploadToCloud(PendingSubmissionModel p) async {
    debugPrint('[Upload] Mulai upload: ${p.id} – ${p.foodName}');
    try {
      String imageUrl = '';

      // FIX 1: Hanya upload gambar kalau path tidak kosong DAN file ada
      // Kalau tanpa foto, lanjutkan saja tanpa upload — tidak crash
      final hasPhoto = p.localImagePath.isNotEmpty;
      final fileExists = hasPhoto && File(p.localImagePath).existsSync();

      if (hasPhoto && !fileExists) {
        // File hilang (misalnya cache image_picker di-clear OS) — lanjut tanpa foto
        debugPrint(
          '[Upload] File tidak ditemukan, lanjut tanpa foto: ${p.localImagePath}',
        );
      }

      if (fileExists) {
        imageUrl = await SubmissionFirebaseService.uploadImage(
          p.localImagePath,
          p.id,
          onProgress: (progress) {
            debugPrint('[Upload] Progress: ${(progress * 100).toInt()}%');
          },
        );
        debugPrint('[Upload] Cloudinary berhasil: $imageUrl');
      }

      // Simpan ke Firestore (dengan atau tanpa foto)
      final model = SubmissionModel(
        id: p.id,
        userId: p.userId,
        userName: p.userName,
        foodName: p.foodName,
        imagePath: imageUrl, // kosong string jika tanpa foto
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
      // Item tetap di Hive — akan di-retry saat online kembali
      _error =
          'Upload gagal untuk "${p.foodName}". Akan dicoba ulang saat online.';
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

  // ── User: hapus pengajuan (hanya jika masih pending & belum di-acc) ───────

  // FIX 3: Fitur delete dari sisi user
  Future<bool> deleteSubmission(SubmissionModel item) async {
    try {
      if (item.status != SubmissionStatus.pending) {
        // Tidak bisa hapus kalau sudah di-review admin
        return false;
      }

      if (!item.isSynced) {
        // Belum di-cloud → hapus dari Hive lokal saja
        await HiveService.pendingSubs.delete(item.id);
        _localItems.removeWhere((e) => e.id == item.id);
        notifyListeners();
      } else {
        // Sudah di-cloud → hapus dari Firestore
        await SubmissionFirebaseService.delete(item.id);
        // _cloudItems akan terupdate otomatis via stream listener
      }
      return true;
    } catch (e) {
      _error = 'Gagal menghapus pengajuan: $e';
      notifyListeners();
      return false;
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
