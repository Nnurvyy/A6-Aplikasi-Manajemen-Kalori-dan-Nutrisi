import 'package:health/health.dart';

/// Service layer yang berkomunikasi langsung dengan Health Connect.
/// Kompatibel dengan package health ^11.x (Google Fit sudah dihapus di v11+)
class SmartwatchService {
  // ── PENTING: gunakan instance global, bukan dibuat tiap kali ────────────
  final Health _health = Health();

  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BLOOD_OXYGEN,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  // ── WAJIB: configure dulu sebelum pakai apapun ────────────────────────────
  // Panggil ini di initState atau sebelum requestPermissions
  void configure() {
    _health.configure();
  }

  // ── Cek status Health Connect ─────────────────────────────────────────────
  // FIX: isHealthConnectAvailable() sudah dihapus di v10+
  // Ganti dengan getHealthConnectSdkStatus()
  Future<bool> isAvailable() async {
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (_) {
      return false;
    }
  }

  // ── Minta izin ke Health Connect ──────────────────────────────────────────
  Future<bool> requestPermissions() async {
    // 1. Cek dulu apakah Health Connect SDK tersedia
    final available = await isAvailable();
    if (!available) return false;

    // 2. Minta izin
    try {
      return await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
    } catch (_) {
      return false;
    }
  }

  // ── Langkah kaki ──────────────────────────────────────────────────────────
  Future<int?> getSteps(DateTime from, DateTime to) async {
    try {
      return await _health.getTotalStepsInInterval(from, to);
    } catch (_) {
      return null;
    }
  }

  // ── Detak jantung (nilai terakhir hari ini) ───────────────────────────────
  Future<double?> getHeartRate(DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: to,
        types: [HealthDataType.HEART_RATE],
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latest = data.first.value;
      if (latest is NumericHealthValue) return latest.numericValue.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Kalori terbakar (total hari ini) ─────────────────────────────────────
  Future<double?> getCaloriesBurned(DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: to,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      if (data.isEmpty) return null;
      double total = 0;
      for (final d in data) {
        if (d.value is NumericHealthValue) {
          total += (d.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      return total;
    } catch (_) {
      return null;
    }
  }

  // ── Saturasi oksigen / SpO2 (nilai terakhir) ──────────────────────────────
  Future<double?> getSpO2(DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: to,
        types: [HealthDataType.BLOOD_OXYGEN],
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latest = data.first.value;
      if (latest is NumericHealthValue) return latest.numericValue.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }
}
