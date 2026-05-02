import 'package:flutter/material.dart';
import '../../general/submission/submission_model.dart';

/// Controller sederhana untuk state pengajuan yang sudah di-ACC admin.
/// Sumber data: dummy list (bisa diganti Hive/API nantinya).
class NutriSubmissionController extends ChangeNotifier {
  // ─── Data approved dari admin ────────────────────────────────────────────
  final List<SubmissionModel> _items = [
    SubmissionModel(
      id: 's1',
      userId: 'u1',
      userName: 'Budi Santoso',
      foodName: 'Gado-Gado Bandung',
      imagePath: '',
      status: SubmissionStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    SubmissionModel(
      id: 's2',
      userId: 'u2',
      userName: 'Siti Rahayu',
      foodName: 'Es Cendol Dawet',
      imagePath: '',
      status: SubmissionStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SubmissionModel(
      id: 's3',
      userId: 'u1',
      userName: 'Budi Santoso',
      foodName: 'Soto Ayam Lamongan',
      imagePath: '',
      calories: 320,
      protein: 22,
      carbs: 28,
      fat: 11,
      status: SubmissionStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    SubmissionModel(
      id: 's4',
      userId: 'u3',
      userName: 'Andi Pratama',
      foodName: 'Nasi Liwet Solo',
      imagePath: '',
      status: SubmissionStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    SubmissionModel(
      id: 's5',
      userId: 'u4',
      userName: 'Dewi Lestari',
      foodName: 'Rendang Padang',
      imagePath: '',
      calories: 468,
      protein: 34,
      carbs: 6,
      fat: 35,
      status: SubmissionStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  List<SubmissionModel> get all => List.unmodifiable(_items);

  List<SubmissionModel> get belumDiisi =>
      _items.where((s) => !s.isNutriFilled).toList();

  List<SubmissionModel> get sudahDiisi =>
      _items.where((s) => s.isNutriFilled).toList();

  /// Update data nutrisi sebuah pengajuan
  Future<void> saveNutriData({
    required String id,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String? nutriNote,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _items.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      nutriNote: nutriNote,
    );
    notifyListeners();
  }
}
