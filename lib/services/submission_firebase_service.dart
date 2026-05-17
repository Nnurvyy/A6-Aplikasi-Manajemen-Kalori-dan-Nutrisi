import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/general/submission/submission_model.dart';

class SubmissionFirebaseService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'submissions';

  static const _cloudName = 'dxvg4czip';
  static const _uploadPreset = 'submission_images';
  static const _cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

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
    if (!file.existsSync()) return ''; // file hilang → anggap tanpa foto

    onProgress?.call(0.1);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    onProgress?.call(0.3);

    final response = await http.post(
      Uri.parse(_cloudinaryUrl),
      body: {
        'file': 'data:image/jpeg;base64,$base64Image',
        'upload_preset': _uploadPreset,
        'folder': folder ?? 'submissions',
      },
    );
    onProgress?.call(0.9);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload gagal: ${response.statusCode} ${response.body}',
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
