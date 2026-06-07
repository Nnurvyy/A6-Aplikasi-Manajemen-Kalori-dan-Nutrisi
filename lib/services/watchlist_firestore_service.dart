import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
=======
import 'package:flutter/foundation.dart';
>>>>>>> 5915c665443afba88f8a44ab555e38136bd94a3d
import '../features/general/food/models/watchlist_model.dart';

class WatchlistFirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'watchlists';

  static Future<void> saveWatchlist(WatchlistModel item) async {
    await _db.collection(_collection).doc(item.id).set(item.toMap());
  }

  static Future<void> deleteWatchlist(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  static Future<List<WatchlistModel>> getUserWatchlist(String userId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      List<WatchlistModel> list = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        if (data['isCombination'] == true || doc.id.contains('combo_')) {
          continue; 
        }

        list.add(WatchlistModel.fromMap(data));
      }

      return list;
    } catch (e) {
      debugPrint("Error getUserWatchlist: $e");
      return [];
    }
  }
}
