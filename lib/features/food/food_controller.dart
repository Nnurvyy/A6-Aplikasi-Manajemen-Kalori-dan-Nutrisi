import 'package:flutter/material.dart';
import 'models/food_model.dart';
import 'models/log_model.dart';
import '../../services/hive_service.dart';

class FoodController extends ChangeNotifier {
  List<FoodModel> _allFoods = [];
  List<FoodModel> _filtered = [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _isLoading = false;

  List<LogModel> getUserLogs(String userId) {
    return HiveService.logs.values
        .cast<LogModel>()
        .where((log) => log.userId == userId)
        .toList();
  }
  List<FoodModel> get foods => _filtered;
  List<FoodModel> get allApproved =>
      _allFoods.where((f) => f.isApproved).toList();
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  static const List<String> categories = [
    'Semua', 'Makanan Pokok', 'Lauk', 'Sayuran', 'Buah', 'Minuman', 'Snack', 'Lainnya'
  ];

  double totalCaloriesToday(String userId) {
    return getUserLogs(userId).fold(0, (sum, item) => sum + item.calories);
  }

  void loadFoods({bool approvedOnly = true}) {
    _allFoods = HiveService.foods.values
        .cast<FoodModel>()
        .where((f) => !approvedOnly || f.isApproved)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    _applyFilter();
  }

  void loadAllFoods() => loadFoods(approvedOnly: false);

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilter();
  }

  void _applyFilter() {
    var list = _allFoods;
    if (_selectedCategory != 'Semua') {
      list = list.where((f) => f.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((f) =>
              f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    _filtered = list;
    notifyListeners();
  }

  Future<void> addFood(FoodModel food) async {
    await HiveService.foods.put(food.id, food);
    loadFoods(approvedOnly: false);
  }

  Future<void> updateFood(FoodModel food) async {
    await HiveService.foods.put(food.id, food);
    loadFoods(approvedOnly: false);
  }

  Future<void> deleteFood(String id) async {
    await HiveService.foods.delete(id);
    loadFoods(approvedOnly: false);
  }

  FoodModel? findById(String id) => HiveService.foods.get(id);

  Future<bool> addFoodToDailyLog({
    required String userId,
    required String foodName,
    required String category,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required String mealType,
    required DateTime dateConsumed, 
  }) async {
    //max 3 hari yg lalu
    final now = DateTime.now();
    final threeDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));
    final inputDateOnly = DateTime(dateConsumed.year, dateConsumed.month, dateConsumed.day);

    if (inputDateOnly.isBefore(threeDaysAgo)) {
      // reject >3 hari lalu
      return false; 
    }

    final newLog = LogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      foodName: foodName,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealType: mealType,
      consumedAt: dateConsumed,
      syncStatus: 'pending', 
      servingSize: 100.0,
      category: category,
    );

    await HiveService.logs.put(newLog.id, newLog);
    
    
    notifyListeners();

    final allLogs = HiveService.logs.values.toList();
    print("\n=== ISI DATABASE RIWAYAT SAAT INI ===");
    print("Total data riwayat: ${allLogs.length}");
    for (var log in allLogs) {
      print("- Makanan: ${log.foodName} | Kalori: ${log.calories} | Tanggal: ${log.consumedAt} | Status: ${log.syncStatus} | Kategori: ${log.category}");
    }
    print("===========================================\n");

    return true; 
  }
}
