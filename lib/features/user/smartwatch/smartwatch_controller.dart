import 'package:flutter/material.dart';
import 'smartwatch_service.dart';
import 'smartwatch_data_model.dart';

// FIX 1: Hapus 'import health/health.dart' — tidak dipakai langsung di sini,
// sudah dihandle oleh SmartwatchService

enum SmartwatchStatus { disconnected, connecting, connected, error }

class SmartwatchController extends ChangeNotifier {
  final SmartwatchService _service = SmartwatchService();

  SmartwatchStatus _status = SmartwatchStatus.disconnected;
  SmartwatchDataModel? _latestData;
  String? _errorMessage;
  bool _isLoading = false;
  DateTime? _lastSynced;

  // FIX 2: Tambah constructor — wajib panggil configure() sebelum apapun
  SmartwatchController() {
    _service.configure();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  SmartwatchStatus get status => _status;
  SmartwatchDataModel? get latestData => _latestData;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isConnected => _status == SmartwatchStatus.connected;
  DateTime? get lastSynced => _lastSynced;

  // ── Minta izin & hubungkan Health Connect ─────────────────────────────────
  Future<bool> requestPermissionAndConnect() async {
    _setLoading(true);
    _status = SmartwatchStatus.connecting;
    notifyListeners();

    try {
      // FIX 3: Cek ketersediaan Health Connect dulu sebelum minta izin
      final available = await _service.isAvailable();
      if (!available) {
        _status = SmartwatchStatus.error;
        _errorMessage =
            'Health Connect tidak tersedia di perangkat ini. '
            'Pastikan app Health Connect sudah terinstall.';
        _setLoading(false);
        return false;
      }

      final granted = await _service.requestPermissions();
      if (!granted) {
        _status = SmartwatchStatus.error;
        _errorMessage = 'Izin akses data kesehatan ditolak.';
        _setLoading(false);
        return false;
      }

      await _fetchData();
      _status = SmartwatchStatus.connected;
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _status = SmartwatchStatus.error;
      _errorMessage = 'Gagal terhubung: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // ── Sinkronisasi data ─────────────────────────────────────────────────────
  Future<void> syncData() async {
    if (_status != SmartwatchStatus.connected) return;
    _setLoading(true);
    try {
      await _fetchData();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal sinkronisasi: ${e.toString()}';
      notifyListeners();
    }
    _setLoading(false);
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    final since = DateTime(now.year, now.month, now.day);

    final steps = await _service.getSteps(since, now);
    final heartRate = await _service.getHeartRate(since, now);
    final calories = await _service.getCaloriesBurned(since, now);
    final spo2 = await _service.getSpO2(since, now);

    _latestData = SmartwatchDataModel(
      steps: steps,
      heartRate: heartRate,
      caloriesBurned: calories,
      spO2: spo2,
      recordedAt: now,
    );
    _lastSynced = now;
    notifyListeners();
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  void disconnect() {
    _status = SmartwatchStatus.disconnected;
    _latestData = null;
    _lastSynced = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
