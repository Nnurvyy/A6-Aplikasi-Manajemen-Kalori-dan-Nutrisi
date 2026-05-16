import 'package:health/health.dart';

/// Service layer yang berkomunikasi langsung dengan Health Connect.
/// Semua method return null jika data tidak tersedia (bukan throw error).
class SmartwatchService {
  final Health _health = Health();

  // Tipe data yang diminta dari Health Connect
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

  // ── Minta izin ke Health Connect ─────────────────────────────────────────
  // ── Minta izin ke Health Connect ─────────────────────────────────────────
  Future<bool> requestPermissions() async {
    // SEBELUM (versi lama — error):
    // final isAvailable = await _health.isHealthConnectAvailable();

    // SESUDAH (versi baru health ^10.x):
    final status = await Health().getHealthConnectSdkStatus();
    final isAvailable = status == HealthConnectSdkStatus.sdkAvailable;
    if (!isAvailable) return false;

    return await _health.requestAuthorization(
      _types,
      permissions: _permissions,
    );
  }

  // ── Langkah kaki ─────────────────────────────────────────────────────────
  Future<int?> getSteps(DateTime from, DateTime to) async {
    try {
      return await _health.getTotalStepsInInterval(from, to);
    } catch (_) {
      return null;
    }
  }

  // ── Detak jantung (ambil nilai terakhir) ──────────────────────────────────
  Future<double?> getHeartRate(DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: to,
        types: [HealthDataType.HEART_RATE],
      );
      if (data.isEmpty) return null;
      // Ambil data paling terbaru
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latest = data.first.value;
      if (latest is NumericHealthValue) return latest.numericValue.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Kalori terbakar ───────────────────────────────────────────────────────
  Future<double?> getCaloriesBurned(DateTime from, DateTime to) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: to,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      if (data.isEmpty) return null;
      // Jumlahkan semua kalori dalam rentang waktu
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

  // ── Saturasi oksigen / SpO2 ───────────────────────────────────────────────
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
