import 'package:flutter/material.dart';
import '../../services/hive_service.dart';
import 'models/food_model.dart';
import 'models/watchlist_model.dart';

class WatchlistController extends ChangeNotifier {
  List<WatchlistModel> _items = [];
  List<WatchlistModel> get items => _items;

  void loadWatchlist(String userId) {
    _items = HiveService.watchlists.values
        .whereType<WatchlistModel>()
        .where((item) => item.userId == userId)
        .toList();
    notifyListeners();
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
    } else {
      // Add
      final newItem = WatchlistModel(
        id: '${userId}_${food.id}',
        userId: userId,
        food: food,
        createdAt: DateTime.now(),
      );
      await HiveService.watchlists.put(newItem.id, newItem);
      _items.add(newItem);
    }
    notifyListeners();
  }
}
