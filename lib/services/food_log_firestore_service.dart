import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/general/food/models/log_model.dart';

class FoodLogFirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'food_logs';

  static Future<void> upsertLog(LogModel log) async {
    await _db
        .collection(_collection)
        .doc(log.id)
        .set(log.toJson(), SetOptions(merge: true));
  }

  static Future<void> upsertLogs(List<LogModel> logs) async {
    if (logs.isEmpty) return;

    const int batchLimit = 500;
    for (int i = 0; i < logs.length; i += batchLimit) {
      final batch = _db.batch();
      final chunk = logs.skip(i).take(batchLimit);

      for (final log in chunk) {
        final docRef = _db.collection(_collection).doc(log.id);
        batch.set(docRef, log.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
    }
  }

  static Future<List<LogModel>> getLogsByUserAndDate(
    String userId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => LogModel.fromJson(doc.data()))
        .where((log) => (log.consumedAt.isAtSameMomentAs(startOfDay) || log.consumedAt.isAfter(startOfDay)) && 
                        log.consumedAt.isBefore(endOfDay))
        .toList();
  }

  static Future<List<LogModel>> getLogsByMonth(
    String userId,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);

    final snapshot = await _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => LogModel.fromJson(doc.data()))
        .where((log) => (log.consumedAt.isAtSameMomentAs(startOfMonth) || log.consumedAt.isAfter(startOfMonth)) && 
                        log.consumedAt.isBefore(nextMonth))
        .toList();
  }

  static Future<void> deleteLog(String logId) async {
    await _db.collection(_collection).doc(logId).delete();
  }
}