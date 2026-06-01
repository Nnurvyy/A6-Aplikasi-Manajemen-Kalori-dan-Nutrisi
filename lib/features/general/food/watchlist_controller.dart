import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../services/hive_service.dart';
import '../../../services/watchlist_firestore_service.dart';
import '../../../services/watchlist_sync_service.dart';
import './models/food_model.dart';
import './models/watchlist_model.dart';
import './models/food_combination_model.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';

class WatchlistController extends ChangeNotifier {
  List<WatchlistModel> _items = [];
  List<WatchlistModel> get items => _items;
  List<FoodCombinationModel> _combinations = [];
  List<FoodCombinationModel> get combinations => _combinations;

  void loadWatchlist(String userId) async {
    
    _items = HiveService.watchlists.values
        .whereType<WatchlistModel>()
        .where((item) => item.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final comboBox = await Hive.openBox<FoodCombinationModel>('food_combinations');
    _combinations = comboBox.values
        .where((combo) => combo.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
    notifyListeners();
    
    WatchlistSyncService.syncWatchlist(userId).then((_) {
      _items = HiveService.watchlists.values
          .whereType<WatchlistModel>()
          .where((item) => item.userId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('watchlists')
          .where('userId', isEqualTo: userId)
          .where('isCombination', isEqualTo: true) 
          .get();

      List<FoodCombinationModel> remoteCombos = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        final combo = FoodCombinationModel(
          id: doc.id,
          userId: data['userId'] ?? '',
          title: data['title'] ?? '',
          createdAt: DateTime.parse(data['createdAt']),
          foods: (data['foods'] as List)
              .map((f) => FoodModel.fromMap(f)) 
              .toList(),
          isSynced: true, 
        );
        
        remoteCombos.add(combo);
        
        await comboBox.put(combo.id, combo);
      }

      if (remoteCombos.isNotEmpty) {
        _combinations = remoteCombos..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching remote combinations: $e");
    }
  }


  bool isInWatchlist(String userId, String foodId) {
    return _items.any((item) => item.userId == userId && item.food.id == foodId);
  }

  Future<void> toggleWatchlist(String userId, FoodModel food) async {
    final existingIndex = _items.indexWhere(
      (item) => item.userId == userId && item.food.id == food.id
    );

    if (existingIndex >= 0) {
      // Remove
      final item = _items[existingIndex];
      await HiveService.watchlists.delete(item.id);
      _items.removeAt(existingIndex);
      
      // Try delete from remote
      try {
        await WatchlistFirestoreService.deleteWatchlist(item.id);
      } catch (e) {
        debugPrint("Failed to delete remote watchlist: $e");
      }
    } else {
      // Add
      final newItem = WatchlistModel(
        id: '${userId}_${food.id}',
        userId: userId,
        food: food,
        createdAt: DateTime.now(),
        isSynced: false,
      );
      await HiveService.watchlists.put(newItem.id, newItem);
      _items.insert(0, newItem);
      
      // Try sync immediately
      try {
        await WatchlistFirestoreService.saveWatchlist(newItem);
        newItem.isSynced = true;
        await newItem.save();
      } catch (e) {
        debugPrint("Failed to sync new watchlist item: $e");
      }
    }
    notifyListeners();
  }

  Future<void> loadCombinations(String userId) async {
    final box = await Hive.openBox<FoodCombinationModel>('food_combinations');
    _combinations = box.values
        .where((item) => item.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> addCombination(String userId, String title, List<FoodModel> foods) async {
    final box = await Hive.openBox<FoodCombinationModel>('food_combinations');
    final newCombo = FoodCombinationModel(
      id: 'combo_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      foods: List.from(foods), 
      createdAt: DateTime.now(),
    );
    
    
    newCombo.isSynced = false; 

    
    await box.put(newCombo.id, newCombo);
    _combinations.insert(0, newCombo);
    notifyListeners();
    
    try {
      
      await FirebaseFirestore.instance
          .collection('watchlists') 
          .doc(newCombo.id)
          .set({
        'id': newCombo.id,
        'userId': userId,
        'title': newCombo.title,
        'isCombination': true, 
        'foods': newCombo.foods.map((food) => food.toMap()).toList(), 
        'createdAt': newCombo.createdAt.toIso8601String(),
        'isSynced': true,
      });

      newCombo.isSynced = true;
      await box.put(newCombo.id, newCombo);
      notifyListeners();
      debugPrint("Kombinasi sukses tersimpan ke Firestore root!");
    } catch (e) {
      debugPrint("Gagal sinkronisasi kombinasi ke Firebase: $e");
    }
  }

  
  Future<void> deleteCombination(String comboId) async {
    final box = await Hive.openBox<FoodCombinationModel>('food_combinations');
    
    
    await box.delete(comboId);
    _combinations.removeWhere((c) => c.id == comboId);
    notifyListeners();
    
    try {
      
      await FirebaseFirestore.instance
          .collection('watchlists')
          .doc(comboId)
          .delete();
      debugPrint("Kombinasi sukses dihapus dari Firebase!");
    } catch (e) {
      debugPrint("Gagal menghapus kombinasi di Firebase: $e");
    }
  }

  Future<void> removeFoodFromCombination(String comboId, String foodId) async {
    final box = await Hive.openBox<FoodCombinationModel>('food_combinations');
    final combo = box.get(comboId);
    
    if (combo != null) {
      combo.foods.removeWhere((f) => f.id == foodId);
      
      if (combo.foods.isEmpty) {
      
        await box.delete(comboId);
        _combinations.removeWhere((c) => c.id == comboId);
        notifyListeners();

        try {
          
          await FirebaseFirestore.instance.collection('watchlists').doc(comboId).delete();
        } catch (e) {
          debugPrint("Gagal menghapus paket kosong di Firebase: $e");
        }
      } else {
        
        combo.isSynced = false;
        await box.put(comboId, combo);
        
        int idx = _combinations.indexWhere((c) => c.id == comboId);
        if (idx >= 0) _combinations[idx] = combo;
        notifyListeners();

        
        try {
          
          await FirebaseFirestore.instance
              .collection('watchlists')
              .doc(comboId)
              .update({
            'foods': combo.foods.map((food) => food.toMap()).toList(),
          });
          
          
          combo.isSynced = true;
          await box.put(comboId, combo);
          if (idx >= 0) _combinations[idx] = combo;
          notifyListeners();
        } catch (e) {
          debugPrint("Gagal memperbarui item kombinasi di Firebase: $e");
        }
      }
    }
  }
}
