import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../features/general/submission/submission_model.dart';

/// Service layer untuk semua operasi Firestore & Storage terkait submission.
class SubmissionFirebaseService {
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static const _col = 'submissions';

  // ── Konversi model ────────────────────────────────────────────────────────

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
      isSynced: true, // data dari Firestore = sudah tersync
    );
  }

  // ── Upload foto ke Firebase Storage ──────────────────────────────────────
  //
  // [onProgress] callback opsional — dipanggil dengan nilai 0.0–1.0
  // supaya controller / UI bisa tampilkan progress bar.

  static Future<String> uploadImage(
    String localPath,
    String submissionId, {
    void Function(double progress)? onProgress,
  }) async {
    if (localPath.isEmpty || localPath.startsWith('http')) return localPath;

    final file = File(localPath);
    if (!file.existsSync()) return localPath;

    final ref = _storage.ref('submissions/$submissionId.jpg');

    // Gunakan putFile dengan UploadTask agar bisa pantau progress
    final task = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    // Pantau progress upload
    task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      }
    });

    // Tunggu selesai
    await task;
    return await ref.getDownloadURL();
  }

  // ── CRUD Firestore ────────────────────────────────────────────────────────

  static Future<void> add(SubmissionModel model) async {
    await _db.collection(_col).doc(model.id).set(_toMap(model));
  }

  static Future<void> update(String id, Map<String, dynamic> fields) async {
    await _db.collection(_col).doc(id).update(fields);
  }

  static Future<void> delete(String id) async {
    await _db.collection(_col).doc(id).delete();
  }

  // ── Stream realtime ───────────────────────────────────────────────────────

  /// Semua submission — untuk Admin & Nutritionist
  static Stream<List<SubmissionModel>> streamAll() {
    return _db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  /// Submission milik user tertentu — untuk User biasa
  static Stream<List<SubmissionModel>> streamByUser(String userId) {
    return _db
        .collection(_col)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }
}
