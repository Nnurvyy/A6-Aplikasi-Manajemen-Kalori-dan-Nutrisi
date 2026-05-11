import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import './hive_service.dart';
import './watchlist_firestore_service.dart';
import '../features/general/food/models/watchlist_model.dart';

class WatchlistSyncService {
  static bool _isSyncing = false;

  static Future<void> syncWatchlist(String userId) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _isSyncing = false;
        return;
      }

      // 1. Upload unsynced local items
      final localItems = HiveService.watchlists.values
          .whereType<WatchlistModel>()
          .where((item) => item.userId == userId && !item.isSynced)
          .toList();

      for (var item in localItems) {
        try {
          await WatchlistFirestoreService.saveWatchlist(item);
          item.isSynced = true;
          await item.save();
        } catch (e) {
          debugPrint("Failed to upload watchlist item ${item.id}: $e");
        }
      }

      // 2. Download from Firestore
      final remoteItems = await WatchlistFirestoreService.getUserWatchlist(userId);
      for (var remote in remoteItems) {
        final local = HiveService.watchlists.get(remote.id);
        if (local == null) {
          await HiveService.watchlists.put(remote.id, remote);
        }
      }
      
      debugPrint("Watchlist sync completed for user $userId");
    } catch (e) {
      debugPrint("Watchlist sync error: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
