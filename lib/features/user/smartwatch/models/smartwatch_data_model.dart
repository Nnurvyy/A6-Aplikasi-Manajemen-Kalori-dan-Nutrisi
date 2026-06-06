/// Model data yang diterima dari Health Connect / smartwatch
class SmartwatchDataModel {
  final int? steps; // langkah hari ini
  final double? heartRate; // bpm terakhir
  final double? caloriesBurned; // kkal terbakar hari ini
  final double? spO2; // saturasi oksigen % terakhir
  final DateTime recordedAt;

  const SmartwatchDataModel({
    this.steps,
    this.heartRate,
    this.caloriesBurned,
    this.spO2,
    required this.recordedAt,
  });

  // ── Interpretasi detak jantung ────────────────────────────────────────────
  String get heartRateLabel {
    if (heartRate == null) return '-';
    if (heartRate! < 60) return 'Rendah';
    if (heartRate! <= 100) return 'Normal';
    return 'Tinggi';
  }

  // ── Interpretasi SpO2 ─────────────────────────────────────────────────────
  String get spO2Label {
    if (spO2 == null) return '-';
    if (spO2! >= 95) return 'Normal';
    if (spO2! >= 90) return 'Rendah';
    return 'Kritis';
  }

  // ── Target langkah harian (10.000 = standar WHO) ──────────────────────────
  double get stepsProgress => ((steps ?? 0) / 10000).clamp(0.0, 1.0);
}
