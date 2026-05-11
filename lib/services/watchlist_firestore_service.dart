import 'package:cloud_firestore/cloud_firestore.dart';
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
    final snapshot = await _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => WatchlistModel.fromMap(doc.data()))
        .toList();
  }
}
