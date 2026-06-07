import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nutritrack_app/features/general/submission/models/submission_model.dart';

class SubmissionFirebaseService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'submissions';

  static String get _backendUrl => dotenv.env['BACKEND_URL'] ?? '';
  static String get _secretToken => dotenv.env['APP_SECRET_TOKEN'] ?? '';
  static String get _cloudinaryUrl => '$_backendUrl/api/ai/cloudinary/upload';

  static Map<String, dynamic> _toMap(SubmissionModel m) => {
    'id': m.id,
    'userId': m.userId,
    'userName': m.userName,
    'foodName': m.foodName,
    'imagePath': m.imagePath,
    'calories': m.calories,
    'protein': m.protein,
    'carbs': m.carbs,
    'fat': m.fat,
    'status': m.status.name,
    'createdAt': Timestamp.fromDate(m.createdAt),
    'forwardedAt':
        m.forwardedAt != null ? Timestamp.fromDate(m.forwardedAt!) : null,
    'reviewNote': m.reviewNote,
    'nutriNote': m.nutriNote,
  };

  static SubmissionModel _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SubmissionModel(
      id: d['id'] as String,
      userId: d['userId'] as String,
      userName: d['userName'] as String,
      foodName: d['foodName'] as String,
      imagePath: d['imagePath'] as String? ?? '',
      calories: (d['calories'] as num?)?.toDouble(),
      protein: (d['protein'] as num?)?.toDouble(),
      carbs: (d['carbs'] as num?)?.toDouble(),
      fat: (d['fat'] as num?)?.toDouble(),
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == (d['status'] as String? ?? 'pending'),
        orElse: () => SubmissionStatus.pending,
      ),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      forwardedAt:
          d['forwardedAt'] != null
              ? (d['forwardedAt'] as Timestamp).toDate()
              : null,
      reviewNote: d['reviewNote'] as String?,
      nutriNote: d['nutriNote'] as String?,
      isSynced: true,
    );
  }

  /// Upload gambar ke Cloudinary.
  /// Jika [localPath] kosong → kembalikan '' (submission tanpa foto valid).
  static Future<String> uploadImage(
    String localPath,
    String submissionId, {
    void Function(double progress)? onProgress,
    String? folder,
  }) async {
    if (localPath.isEmpty) return '';
    if (localPath.startsWith('http')) return localPath;

    final file = File(localPath);
    if (!file.existsSync()) return '';

    onProgress?.call(0.1);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    onProgress?.call(0.3);

    final response = await http.post(
      Uri.parse(_cloudinaryUrl),
      headers: {'X-App-Secret': _secretToken},
      body: {
        'file': 'data:image/jpeg;base64,$base64Image',
        'folder': folder ?? 'submissions',
      },
    );
    onProgress?.call(0.9);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload via Hono gagal: ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final url = json['secure_url'] as String;
    onProgress?.call(1.0);
    return url;
  }

  static Future<void> add(SubmissionModel model) async {
    await _db.collection(_col).doc(model.id).set(_toMap(model));
  }

  static Future<void> update(String id, Map<String, dynamic> fields) async {
    await _db.collection(_col).doc(id).update(fields);
  }

  static Future<void> delete(String id) async {
    await _db.collection(_col).doc(id).delete();
  }

  /// Simpan hasil isi nutrisi dari ahli gizi ke collection `foods`
  /// agar langsung tersedia sebagai makanan global di database.
  static Future<void> saveNutriToFoods(SubmissionModel item) async {
    if (!item.isNutriFilled) return;

    // ID food mengikuti id submission supaya idempotent
    final foodId = 'sub_${item.id}';

    await _db.collection('foods').doc(foodId).set({
      'id': foodId,
      'name': item.foodName,
      'category': 'Lainnya', // default; bisa diupdate manual di admin food
      'calories': item.calories,
      'protein': item.protein,
      'carbs': item.carbs,
      'fat': item.fat,
      'defaultServingSize': 100.0,
      'isApproved': true,
      'userId': null, // null = global/universal
      'imageUrl': item.imagePath.startsWith('http') ? item.imagePath : null,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'isSynced': true,
    }, SetOptions(merge: true));
  }

  static Stream<List<SubmissionModel>> streamAll() {
    return _db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  static Stream<List<SubmissionModel>> streamByUser(String userId) {
    return _db
        .collection(_col)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }
}
