import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/user/progress/models/weight_log_model.dart';

class WeightLogFirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'weight_logs';

  static Future<void> saveWeightLog(WeightLogModel log) async {
    await _db.collection(_collection).doc(log.id).set({
      'id': log.id,
      'userId': log.userId,
      'month': log.month.toIso8601String(),
      'actualWeight': log.actualWeight,
    });
  }

  static Future<List<WeightLogModel>> getUserWeightLogs(String userId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return WeightLogModel(
        id: data['id'],
        userId: data['userId'],
        month: DateTime.parse(data['month']),
        actualWeight: (data['actualWeight'] as num?)?.toDouble(),
      );
    }).toList();
  }
}
