import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'submission_model.dart';
import 'submission_hive_model.dart';

/// Controller global yang di-share antara Admin dan Nutritionist.
/// Di-provide di main.dart → perubahan dari admin langsung terlihat di nutri.
class SubmissionController extends ChangeNotifier {
  static const _boxName = 'submissions';

  late Box<SubmissionHiveModel> _box;
  List<SubmissionModel> _items = [];

  // ── Public lists ─────────────────────────────────────────────────────────

  List<SubmissionModel> get all => List.unmodifiable(_items);

  /// Semua submission milik user tertentu (untuk tampilan user)
  List<SubmissionModel> byUser(String userId) =>
      _items.where((s) => s.userId == userId).toList();

  /// Pending — menunggu review admin
  List<SubmissionModel> get pending =>
      _items.where((s) => s.status == SubmissionStatus.pending).toList();

  /// Approved — untuk nutritionist isi data nutrisi
  List<SubmissionModel> get approved =>
      _items.where((s) => s.status == SubmissionStatus.approved).toList();

  /// Approved belum diisi nutrisi (tugas nutritionist)
  List<SubmissionModel> get approvedNeedsFill =>
      approved.where((s) => !s.isNutriFilled).toList();

  /// Approved sudah diisi nutrisi
  List<SubmissionModel> get approvedFilled =>
      approved.where((s) => s.isNutriFilled).toList();

  List<SubmissionModel> get canceled =>
      _items.where((s) => s.status == SubmissionStatus.canceled).toList();

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _box = Hive.box<SubmissionHiveModel>(_boxName);
    _loadFromBox();
    // Seed dummy jika box masih kosong (untuk development)
    if (_items.isEmpty) await _seedDummy();
  }

  void _loadFromBox() {
    _items =
        _box.values.map((h) => h.toModel()).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> _seedDummy() async {
    final seeds = [
      SubmissionModel(
        id: 'seed_1',
        userId: 'u1',
        userName: 'Budi Santoso',
        foodName: 'Gado-Gado Bandung',
        imagePath: '',
        status: SubmissionStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SubmissionModel(
        id: 'seed_2',
        userId: 'u2',
        userName: 'Siti Rahayu',
        foodName: 'Es Cendol Dawet',
        imagePath: '',
        status: SubmissionStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      SubmissionModel(
        id: 'seed_3',
        userId: 'u3',
        userName: 'Andi Pratama',
        foodName: 'Nasi Liwet Solo',
        imagePath: '',
        status: SubmissionStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SubmissionModel(
        id: 'seed_4',
        userId: 'u4',
        userName: 'Dewi Lestari',
        foodName: 'Rendang Padang',
        imagePath: '',
        calories: 468,
        protein: 34,
        carbs: 6,
        fat: 35,
        status: SubmissionStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SubmissionModel(
        id: 'seed_5',
        userId: 'u1',
        userName: 'Budi Santoso',
        foodName: 'Soto Ayam Lamongan',
        imagePath: '',
        status: SubmissionStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
    for (final s in seeds) {
      await _box.put(s.id, SubmissionHiveModel.fromModel(s));
    }
    _loadFromBox();
  }

  // ── User: ajukan makanan ──────────────────────────────────────────────────

  Future<SubmissionModel> addSubmission({
    required String userId,
    required String userName,
    required String foodName,
    required String imagePath,
  }) async {
    final model = SubmissionModel(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      foodName: foodName,
      imagePath: imagePath,
      status: SubmissionStatus.pending,
      createdAt: DateTime.now(),
    );
    await _box.put(model.id, SubmissionHiveModel.fromModel(model));
    _loadFromBox();
    return model;
  }

  // ── Admin: terima / tolak ─────────────────────────────────────────────────

  Future<void> reviewSubmission({
    required String id,
    required SubmissionStatus newStatus,
    String? reviewNote,
  }) async {
    final existing = _box.get(id);
    if (existing == null) return;
    final updated = existing.toModel().copyWith(
      status: newStatus,
      reviewNote: reviewNote,
    );
    await _box.put(id, SubmissionHiveModel.fromModel(updated));
    _loadFromBox();
  }

  // ── Nutritionist: isi / update data nutrisi ───────────────────────────────

  Future<void> saveNutriData({
    required String id,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String? nutriNote,
  }) async {
    final existing = _box.get(id);
    if (existing == null) return;
    final updated = existing.toModel().copyWith(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      nutriNote: nutriNote,
    );
    await _box.put(id, SubmissionHiveModel.fromModel(updated));
    _loadFromBox();
  }
}
