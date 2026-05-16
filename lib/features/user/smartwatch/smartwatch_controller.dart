import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'smartwatch_service.dart';
import 'smartwatch_data_model.dart';

enum SmartwatchStatus { disconnected, connecting, connected, error }

class SmartwatchController extends ChangeNotifier {
  final SmartwatchService _service = SmartwatchService();

  SmartwatchStatus _status = SmartwatchStatus.disconnected;
  SmartwatchDataModel? _latestData;
  String? _errorMessage;
  bool _isLoading = false;
  DateTime? _lastSynced;

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
      final granted = await _service.requestPermissions();
      if (!granted) {
        _status = SmartwatchStatus.error;
        _errorMessage = 'Izin akses data kesehatan ditolak.';
        _setLoading(false);
        return false;
      }

      // Langsung ambil data setelah izin diberikan
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

  // ── Ambil data terbaru dari Health Connect ────────────────────────────────
  Future<void> syncData() async {
    if (_status != SmartwatchStatus.connected) return;
    _setLoading(true);
    try {
      await _fetchData();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal sinkronisasi: ${e.toString()}';
    }
    _setLoading(false);
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    final since = DateTime(now.year, now.month, now.day); // mulai tengah malam

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
