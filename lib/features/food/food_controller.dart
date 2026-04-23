import 'package:flutter/material.dart';
import 'models/food_model.dart';
import '../../services/hive_service.dart';

class FoodController extends ChangeNotifier {
  List<FoodModel> _allFoods = [];
  List<FoodModel> _filtered = [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _isLoading = false;

  List<FoodModel> get foods => _filtered;
  List<FoodModel> get allApproved =>
      _allFoods.where((f) => f.isApproved).toList();
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  static const List<String> categories = [
    'Semua', 'Makanan Pokok', 'Lauk', 'Sayuran', 'Buah', 'Minuman', 'Snack', 'Lainnya'
  ];

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
}
