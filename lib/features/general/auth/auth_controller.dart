import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './models/user_model.dart';
import '../../../services/hive_service.dart';
import '../../../helpers/calorie_helper.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? _monitoredUser; // User yang sedang dipantau (Anak)
  bool _isMonitoringActive = false; // Flag apakah mode pantau sedang aktif
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _isMonitoringActive ? _monitoredUser : _currentUser;
  UserModel? get mainUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isMonitoring => _isMonitoringActive;
  bool get hasMonitoredUser {
    final key = 'monitored_user_id_${_currentUser?.id}';
    return HiveService.settings.get(key) != null;
  }

  Future<bool> startMonitoring(String uid) async {
    _setLoading(true);
    _errorMessage = null;

    if (uid == _currentUser?.id) {
      _errorMessage = 'Anda tidak bisa memantau diri sendiri';
      _setLoading(false);
      return false;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _monitoredUser = UserModel.fromMap(doc.data()!);
        _isMonitoringActive = true;
        await HiveService.users.put(uid, _monitoredUser!);
        // Per-akun: simpan monitored_user_id dengan key yang mengandung id akun utama
        final key = 'monitored_user_id_${_currentUser!.id}';
        await HiveService.settings.put(key, uid);
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Pengguna tidak ditemukan';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }
    _setLoading(false);
    return false;
  }

  void stopMonitoring() {
    _isMonitoringActive = false;
    notifyListeners();
  }

  void resumeMonitoring() {
    if (_monitoredUser != null) {
      _isMonitoringActive = true;
      notifyListeners();
    }
  }

  AuthController() {
    _init();
  }

  void _init() {
    // 1. OFFLINE FIRST: Load dari Hive dulu supaya UI langsung muncul
    _loadFromLocal();

    // 2. Pantau perubahan auth di Firebase
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Coba ambil data terbaru dari cloud untuk sinkronisasi
        await _fetchUserProfile(user.uid);
        
        // Coba perbarui data monitored user juga jika ada
        final key = 'monitored_user_id_${user.uid}';
        final monitoredId = HiveService.settings.get(key) as String?;
        if (monitoredId != null) {
          final mDoc = await _firestore.collection('users').doc(monitoredId).get();
          if (mDoc.exists) {
            _monitoredUser = UserModel.fromMap(mDoc.data()!);
            await HiveService.users.put(monitoredId, _monitoredUser!);
            notifyListeners();
          }
        }
      } else {
        // Jika user logout di Firebase, bersihkan sesi lokal
        if (_currentUser != null) {
          _currentUser = null;
          _monitoredUser = null;
          _isMonitoringActive = false;
          await HiveService.settings.delete('current_user_id');
          await HiveService.settings.delete('monitored_user_id');
          notifyListeners();
        }
      }
    });
  }

  void _loadFromLocal() {
    final savedId = HiveService.settings.get('current_user_id') as String?;
    if (savedId != null) {
      _currentUser = HiveService.users.get(savedId);
    }
    
    // Per-akun: load monitored user hanya untuk akun yang login sekarang
    if (_currentUser != null) {
      final key = 'monitored_user_id_${_currentUser!.id}';
      final monitoredId = HiveService.settings.get(key) as String?;
      if (monitoredId != null) {
        _monitoredUser = HiveService.users.get(monitoredId);
      }
    }
    
    notifyListeners();
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      // Coba fetch dari server dengan timeout pendek
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        // Sinkronisasi ke Hive sebagai cache lokal
        await HiveService.users.put(uid, _currentUser!);
        await HiveService.settings.put('current_user_id', uid);
        
        // RELOAD monitored user untuk akun ini
        final key = 'monitored_user_id_${_currentUser!.id}';
        final monitoredId = HiveService.settings.get(key) as String?;
        if (monitoredId != null) {
          _monitoredUser = HiveService.users.get(monitoredId);
        } else {
          _monitoredUser = null;
          _isMonitoringActive = false;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Offline mode: Fetching from Hive because: $e");
      // Jika offline, data sudah di-load dari lokal di _loadFromLocal()
      // Kita pastikan lagi _currentUser terisi dari Hive jika fetch cloud gagal
      _currentUser ??= HiveService.users.get(uid);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await _fetchUserProfile(userCredential.user!.uid);

        if (_currentUser?.isBlocked ?? false) {
          await logout();
          _errorMessage = 'Akun Anda telah diblokir. Hubungi admin.';
          _setLoading(false);
          return false;
        }

        _setLoading(false);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-disabled') {
        _errorMessage = 'Akun Anda telah dinonaktifkan';
      } else if (e.code == 'too-many-requests') {
        _errorMessage = 'Terlalu banyak percobaan. Coba lagi nanti.';
      } else {
        _errorMessage = 'Login gagal: email atau password salah';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _setLoading(false);
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required DateTime birthDate,
    double targetWeightGainPerMonth = 0,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // 1. Create User di Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // 2. Hitung Kebutuhan Kalori
      final dailyCalorieNeed = CalorieHelper.calculateDailyCalorieNeed(
        weightKg: weight,
        heightCm: height,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        targetWeightGainPerMonth: targetWeightGainPerMonth,
      );

      // 3. Buat Object UserModel dengan password yang di-hash
      final newUser = UserModel(
        id: uid,
        name: name,
        email: email,
        password: _hashPassword(password),
        role: 'user',
        weight: weight,
        height: height,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        birthDate: birthDate,
        dailyCalorieNeed: dailyCalorieNeed,
        targetWeightGainPerMonth: targetWeightGainPerMonth,
        initialWeight: weight,
        targetHistory: {
          DateFormat('yyyy-MM').format(DateTime.now()): targetWeightGainPerMonth,
        },
      );

      // 4. Simpan ke Firestore
      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      // 5. Simpan ke Hive (Cache)
      await HiveService.users.put(uid, newUser);
      await HiveService.settings.put('current_user_id', uid);

      _currentUser = newUser;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'Email sudah terdaftar';
      } else {
        _errorMessage = 'Registrasi gagal: ${e.message}';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await HiveService.settings.delete('current_user_id');
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel updated) async {
    try {
      await _firestore.collection('users').doc(updated.id).update(updated.toMap());
      await HiveService.users.put(updated.id, updated);
      if (_currentUser?.id == updated.id) {
        _currentUser = updated;
      } else if (_monitoredUser?.id == updated.id) {
        _monitoredUser = updated;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating profile: $e");
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
