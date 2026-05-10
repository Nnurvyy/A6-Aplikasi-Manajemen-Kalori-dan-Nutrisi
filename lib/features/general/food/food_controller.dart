import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './models/food_model.dart';
import './models/log_model.dart';
import '../../../services/hive_service.dart';

class FoodController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      _allFoods.where((f) => f.isApproved && !f.id.startsWith('manual_')).toList();
  
  List<FoodModel> get manualFoods =>
      _allFoods.where((f) => f.id.startsWith('manual_')).toList();
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  static const List<String> categories = [
    'Semua', 'Makanan Pokok', 'Lauk', 'Sayuran', 'Buah', 'Minuman', 'Snack', 'Lainnya'
  ];

  FoodController() {
    loadFoods();
    loadFromLocal();
    syncWithFirebase();
  }

  void loadFromLocal() {
    _allFoods = HiveService.foods.values.cast<FoodModel>().toList();
    _applyFilter();
  }

  Future<void> syncWithFirebase() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _db.collection('foods').get();
      
      for (var doc in snapshot.docs) {
        final food = FoodModel.fromFirestore(doc.data(), doc.id);
        await HiveService.foods.put(food.id, food);
      }
      
      loadFromLocal(); 
    } catch (e) {
      debugPrint("Sync Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  double totalCaloriesToday(String userId) {
    return getUserLogs(userId).fold(0, (total, item) => total + item.calories);
  }

  void loadFoods({bool approvedOnly = true}) {
    var all = HiveService.foods.values.cast<FoodModel>().toList();
    
    // Ensure Air Putih exists and remove duplicates
    final waterList = all.where((f) => f.name.toLowerCase().trim() == 'air putih').toList();
    if (waterList.isEmpty) {
      final water = FoodModel(
        id: 'default_water',
        name: 'Air Putih',
        category: 'Minuman',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        defaultServingSize: 250, // 1 gelas
        isApproved: true,
        createdAt: DateTime.now(),
      );
      HiveService.foods.put(water.id, water);
      all.add(water);
    } else if (waterList.length > 1) {
      // Remove duplicates, keep only one (prefer default_water)
      final toKeep = waterList.any((f) => f.id == 'default_water') 
          ? waterList.firstWhere((f) => f.id == 'default_water')
          : waterList.first;
      
      for (var f in waterList) {
        if (f.id != toKeep.id) {
          HiveService.foods.delete(f.id);
          all.removeWhere((item) => item.id == f.id);
        }
      }
    }

    _allFoods = all
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

  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'Semua';
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
    
    _allFoods.add(food);
    
    _searchQuery = ''; 
    _applyFilter(); 
    
    await HiveService.foods.put(food.id, food);

    _applyFilter();

    _db.collection('foods').doc(food.id).set(food.toMap()).then((_) {
      
      debugPrint("Berhasil sinkron ke Firebase!");
    }).catchError((error) {
      debugPrint("Gagal sinkron ke Firebase: $error");
    });

  }

  Future<void> updateFood(FoodModel food) async {
    await HiveService.foods.put(food.id, food);
    loadFoods(approvedOnly: false);

    loadFromLocal();

    try {
      //await _db.collection('foods').doc(food.id).update(food.toFirestore());
      await _db.collection('foods').doc(food.id).set(food.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Cloud Update Error: $e");
    }
  }

  Future<void> deleteFood(String id) async {
    await HiveService.foods.delete(id);
    loadFoods(approvedOnly: false);

    loadFromLocal();

    try {
      await _db.collection('foods').doc(id).delete();
    } catch (e) {
      debugPrint("Cloud Delete Error: $e");
    }
  }


  FoodModel? findById(String id) => HiveService.foods.get(id);

  List<LogModel> get allLogs => HiveService.logs.values.toList();

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
    required double servingSize,
    int quantity = 1, // New parameter
    bool isManual = false,
    String? imageUrl,
    String? ingredientsJson,
  }) async {
    final now = DateTime.now();
    final consumedAtWithTime = DateTime(
      dateConsumed.year,
      dateConsumed.month,
      dateConsumed.day,
      now.hour,
      now.minute,
      now.second,
    );

    final newLog = LogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      foodName: foodName,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealType: mealType,
      consumedAt: consumedAtWithTime,
      syncStatus: 'pending', 
      servingSize: servingSize,
      category: category,
      isManual: isManual,
      imageUrl: imageUrl,
      ingredientsJson: ingredientsJson,
      quantity: quantity,
    );

    await HiveService.logs.put(newLog.id, newLog);
    notifyListeners();
    return true; 
  }

  Future<void> updateLog(LogModel log) async {
    await HiveService.logs.put(log.id, log);
    notifyListeners();
  }

  Future<void> deleteManualFood(String userId, String foodName) async {
    final keysToDelete = HiveService.logs.keys.where((key) {
      final log = HiveService.logs.get(key);
      return log is LogModel && 
             log.userId == userId && 
             log.foodName.toLowerCase() == foodName.toLowerCase() && 
             log.isManual;
    }).toList();

    for (var key in keysToDelete) {
      await HiveService.logs.delete(key);
    }
    notifyListeners();
  }

  Future<void> updateManualFood(String userId, String oldName, LogModel updatedTemplate) async {
    final keysToUpdate = HiveService.logs.keys.where((key) {
      final log = HiveService.logs.get(key);
      return log is LogModel && 
             log.userId == userId && 
             log.foodName.toLowerCase() == oldName.toLowerCase() && 
             log.isManual;
    }).toList();

    for (var key in keysToUpdate) {
      final oldLog = HiveService.logs.get(key) as LogModel;
      final newLog = oldLog.copyWith(
        foodName: updatedTemplate.foodName,
        category: updatedTemplate.category,
        calories: updatedTemplate.calories,
        protein: updatedTemplate.protein,
        carbs: updatedTemplate.carbs,
        fat: updatedTemplate.fat,
        servingSize: updatedTemplate.servingSize,
        imageUrl: updatedTemplate.imageUrl,
        ingredientsJson: updatedTemplate.ingredientsJson,
      );
      await HiveService.logs.put(key, newLog);
    }
    notifyListeners();
  }

  Future<void> updateSpecificLog(LogModel updatedLog) async {
    await HiveService.logs.put(updatedLog.id, updatedLog);
    notifyListeners();
  }

  Future<void> deleteLog(String logId) async {
    await HiveService.logs.delete(logId);
    notifyListeners();
  }
}
