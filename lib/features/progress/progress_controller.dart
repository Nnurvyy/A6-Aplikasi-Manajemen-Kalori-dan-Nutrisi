import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/hive_service.dart';
import '../auth/models/user_model.dart';
import '../food/models/log_model.dart';
import 'models/weight_log_model.dart';

// ── Enum untuk pilihan periode ────────────────────────────────────────────────
enum ChartPeriod { daily, monthly }

// ── Data point untuk chart nutrisi ───────────────────────────────────────────
class NutritionDataPoint {
  final String label; // "1", "2", ..., "30" atau "Jan", "Feb", ...
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  const NutritionDataPoint({
    required this.label,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

// ── Data point untuk chart berat badan ───────────────────────────────────────
class WeightDataPoint {
  final String label; // "Jan", "Feb", ...
  final double? actualWeight; // null = tidak diinput
  final double systemWeight; // perhitungan sistem
  const WeightDataPoint({
    required this.label,
    required this.actualWeight,
    required this.systemWeight,
  });
}

// ─── CONTROLLER ───────────────────────────────────────────────────────────────
class ProgressController extends ChangeNotifier {
  UserModel? _user;
  StreamSubscription? _logSub;
  StreamSubscription? _weightSub;

  ChartPeriod _period = ChartPeriod.daily;
  ChartPeriod get period => _period;

  // Bulan/tahun yang sedang dilihat untuk mode daily
  int _viewMonth = DateTime.now().month;
  int _viewYear = DateTime.now().year;
  int get viewMonth => _viewMonth;
  int get viewYear => _viewYear;

  // Tahun yang sedang dilihat untuk mode monthly
  int _viewYearMonthly = DateTime.now().year;
  int get viewYearMonthly => _viewYearMonthly;

  // Tab nutrisi aktif: 0=Kalori, 1=Protein, 2=Karbohidrat, 3=Lemak
  int _activeNutrientTab = 0;
  int get activeNutrientTab => _activeNutrientTab;

  List<NutritionDataPoint> _nutritionData = [];
  List<NutritionDataPoint> get nutritionData => _nutritionData;

  List<WeightDataPoint> _weightData = [];
  List<WeightDataPoint> get weightData => _weightData;

  // Apakah modal input BB sudah perlu ditampilkan
  bool _shouldShowWeightModal = false;
  bool get shouldShowWeightModal => _shouldShowWeightModal;
  DateTime? _pendingWeightMonth; // bulan yang harus diisi
  DateTime? get pendingWeightMonth => _pendingWeightMonth;

  void init(UserModel user) {
    _user = user;
    _checkWeightModalNeeded();
    _buildNutritionData();
    _buildWeightData();

    _logSub?.cancel();
    _logSub = HiveService.logs.watch().listen((_) {
      _buildNutritionData();
      notifyListeners();
    });

    _weightSub?.cancel();
    _weightSub = HiveService.weightLogs.watch().listen((_) {
      _buildWeightData();
      notifyListeners();
    });

    notifyListeners();
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _weightSub?.cancel();
    super.dispose();
  }

  // ── Pengecekan apakah modal input BB perlu ditampilkan ──────────────────────
  void _checkWeightModalNeeded() {
    final user = _user;
    if (user == null) return;

    final now = DateTime.now();
    final createdAt = user.birthDate; // birthDate dipakai sebagai tanggal lahir
    // Kita simpan account creation date di settings jika ada,
    // tapi kita bisa estimasi dari ID: user_<milliseconds>
    DateTime? accountCreated;
    try {
      final ms = int.parse(user.id.replaceAll('user_', ''));
      accountCreated = DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      accountCreated = createdAt;
    }

    if (accountCreated == null) return;

    // Cari bulan-bulan sejak akun dibuat sampai bulan lalu yang belum ada log
    final startMonth = DateTime(accountCreated.year, accountCreated.month + 1);
    final currentMonth = DateTime(now.year, now.month);

    if (startMonth.isAfter(currentMonth)) return; // belum sebulan

    // Iterasi setiap bulan dari startMonth sampai bulan lalu
    DateTime checkMonth = startMonth;
    while (!checkMonth.isAfter(
      DateTime(currentMonth.year, currentMonth.month - 1),
    )) {
      final key = _weightLogKey(user.id, checkMonth);
      final existing = HiveService.weightLogs.get(key);
      if (existing == null) {
        // Belum ada log untuk bulan ini → tampilkan modal
        _shouldShowWeightModal = true;
        _pendingWeightMonth = checkMonth;
        return;
      }
      checkMonth = DateTime(checkMonth.year, checkMonth.month + 1);
    }

    _shouldShowWeightModal = false;
    _pendingWeightMonth = null;
  }

  String _weightLogKey(String userId, DateTime month) =>
      '${userId}_${month.year}_${month.month}';

  // ── Simpan BB aktual ────────────────────────────────────────────────────────
  Future<void> saveActualWeight({
    required DateTime month,
    required double weight,
  }) async {
    final user = _user;
    if (user == null) return;
    final key = _weightLogKey(user.id, month);
    final log = WeightLogModel(
      id: key,
      userId: user.id,
      month: DateTime(month.year, month.month, 1),
      actualWeight: weight,
    );
    await HiveService.weightLogs.put(key, log);
    _shouldShowWeightModal = false;
    _pendingWeightMonth = null;
    _buildWeightData();
    notifyListeners();
  }

  // ── Lewati input BB ─────────────────────────────────────────────────────────
  Future<void> skipWeightInput({required DateTime month}) async {
    final user = _user;
    if (user == null) return;
    // Simpan entry tanpa actualWeight (null) agar tidak ditanya lagi
    final key = _weightLogKey(user.id, month);
    final log = WeightLogModel(
      id: key,
      userId: user.id,
      month: DateTime(month.year, month.month, 1),
      actualWeight: null,
    );
    await HiveService.weightLogs.put(key, log);
    _shouldShowWeightModal = false;
    _pendingWeightMonth = null;
    _buildWeightData();
    notifyListeners();
  }

  // ─── NAVIGATION ─────────────────────────────────────────────────────────────

  void setPeriod(ChartPeriod p) {
    _period = p;
    _buildNutritionData();
    notifyListeners();
  }

  void setActiveNutrientTab(int i) {
    _activeNutrientTab = i;
    notifyListeners();
  }

  void prevMonth() {
    _viewMonth--;
    if (_viewMonth < 1) {
      _viewMonth = 12;
      _viewYear--;
    }
    _buildNutritionData();
    notifyListeners();
  }

  void nextMonth() {
    final now = DateTime.now();
    if (_viewYear > now.year ||
        (_viewYear == now.year && _viewMonth >= now.month)) return;
    _viewMonth++;
    if (_viewMonth > 12) {
      _viewMonth = 1;
      _viewYear++;
    }
    _buildNutritionData();
    notifyListeners();
  }

  void prevYearMonthly() {
    _viewYearMonthly--;
    _buildNutritionData();
    notifyListeners();
  }

  void nextYearMonthly() {
    if (_viewYearMonthly >= DateTime.now().year) return;
    _viewYearMonthly++;
    _buildNutritionData();
    notifyListeners();
  }

  void setViewMonthYear(int year, int month) {
    _viewYear = year;
    _viewMonth = month;
    _period = ChartPeriod.daily; // Auto switch to daily view
    _buildNutritionData();
    notifyListeners();
  }

  void setViewYearMonthly(int year) {
    _viewYearMonthly = year;
    _buildNutritionData();
    notifyListeners();
  }

  // ─── BUILD DATA ─────────────────────────────────────────────────────────────

  void _buildNutritionData() {
    final user = _user;
    if (user == null) {
      _nutritionData = [];
      return;
    }

    final allLogs = HiveService.logs.values
        .whereType<LogModel>()
        .where((l) => l.userId == user.id)
        .toList();

    if (_period == ChartPeriod.daily) {
      _buildDailyData(allLogs);
    } else {
      _buildMonthlyData(allLogs);
    }
  }

  void _buildDailyData(List<LogModel> logs) {
    final daysInMonth = _daysInMonth(_viewYear, _viewMonth);
    final Map<int, List<LogModel>> byDay = {};
    for (var d = 1; d <= daysInMonth; d++) byDay[d] = [];

    for (final log in logs) {
      if (log.consumedAt.year == _viewYear &&
          log.consumedAt.month == _viewMonth) {
        byDay[log.consumedAt.day]?.add(log);
      }
    }

    _nutritionData = List.generate(daysInMonth, (i) {
      final day = i + 1;
      final dayLogs = byDay[day]!;
      return NutritionDataPoint(
        label: '$day',
        calories: dayLogs.fold(0.0, (s, l) => s + l.calories),
        protein: dayLogs.fold(0.0, (s, l) => s + l.protein),
        carbs: dayLogs.fold(0.0, (s, l) => s + l.carbs),
        fat: dayLogs.fold(0.0, (s, l) => s + l.fat),
      );
    });
  }

  void _buildMonthlyData(List<LogModel> logs) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    final Map<int, List<LogModel>> byMonth = {for (var m = 1; m <= 12; m++) m: []};

    for (final log in logs) {
      if (log.consumedAt.year == _viewYearMonthly) {
        byMonth[log.consumedAt.month]?.add(log);
      }
    }

    _nutritionData = List.generate(12, (i) {
      final month = i + 1;
      final monthLogs = byMonth[month]!;
      return NutritionDataPoint(
        label: monthNames[i],
        calories: monthLogs.fold(0.0, (s, l) => s + l.calories),
        protein: monthLogs.fold(0.0, (s, l) => s + l.protein),
        carbs: monthLogs.fold(0.0, (s, l) => s + l.carbs),
        fat: monthLogs.fold(0.0, (s, l) => s + l.fat),
      );
    });
  }

  void _buildWeightData() {
    final user = _user;
    if (user == null) {
      _weightData = [];
      return;
    }

    // Hitung berat sistem awal
    DateTime? accountCreated;
    try {
      final ms = int.parse(user.id.replaceAll('user_', ''));
      accountCreated = DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      accountCreated = DateTime.now();
    }

    final startWeight = user.weight ?? 60.0;
    final targetDelta = user.targetWeightGainPerMonth ?? 0.0;
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final result = <WeightDataPoint>[];

    for (int m = 1; m <= 12; m++) {
      final monthDate = DateTime(now.year, m, 1);
      // Hitung berapa bulan dari saat akun dibuat ke bulan ini
      final monthsFromStart = _monthsBetween(
        DateTime(accountCreated!.year, accountCreated.month, 1),
        monthDate,
      );
      final systemWeight = startWeight + (targetDelta * monthsFromStart);

      final key = _weightLogKey(user.id, monthDate);
      final log = HiveService.weightLogs.get(key);
      final actual = log?.actualWeight;

      // Jika bulan belum terjadi (masa depan), tidak tampilkan titik aktual
      final isFuture = monthDate.isAfter(now);

      result.add(
        WeightDataPoint(
          label: monthNames[m - 1],
          actualWeight: isFuture ? null : actual,
          systemWeight: systemWeight < 0 ? 0 : systemWeight,
        ),
      );
    }

    _weightData = result;
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  /// Ambil nilai nutrisi yang dipilih dari data point
  double nutrientValue(NutritionDataPoint p) {
    switch (_activeNutrientTab) {
      case 1: return p.protein;
      case 2: return p.carbs;
      case 3: return p.fat;
      default: return p.calories;
    }
  }

  /// Warna sesuai tab nutrisi aktif
  Color get activeNutrientColor {
    switch (_activeNutrientTab) {
      case 1: return const Color(0xFFE53935); // Protein = merah
      case 2: return const Color(0xFFF59E0B); // Karbo = kuning
      case 3: return const Color(0xFFFF8C00); // Lemak = oranye
      default: return const Color(0xFF2E7D32); // Kalori = hijau
    }
  }

  Color get activeNutrientColorLight {
    switch (_activeNutrientTab) {
      case 1: return const Color(0xFFFFCDD2);
      case 2: return const Color(0xFFFFECB3);
      case 3: return const Color(0xFFFFE0B2);
      default: return const Color(0xFFC8E6C9);
    }
  }

  String get activeNutrientUnit {
    return _activeNutrientTab == 0 ? 'kkal' : 'g';
  }

  String get activeNutrientLabel {
    switch (_activeNutrientTab) {
      case 1: return 'Protein';
      case 2: return 'Karbohidrat';
      case 3: return 'Lemak';
      default: return 'Kalori';
    }
  }

  /// Statistik ringkasan untuk nutrisi aktif
  Map<String, double> get nutritionStats {
    if (_nutritionData.isEmpty) return {'avg': 0, 'max': 0, 'total': 0};
    final values = _nutritionData.map(nutrientValue).toList();
    final nonZero = values.where((v) => v > 0).toList();
    final total = values.fold(0.0, (s, v) => s + v);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = nonZero.isEmpty ? 0.0 : total / nonZero.length;
    return {'avg': avg, 'max': max, 'total': total};
  }

  /// Max value untuk skala chart berat
  double get weightChartMax {
    if (_weightData.isEmpty) return 100;
    final allVals = [
      ..._weightData.map((w) => w.systemWeight),
      ..._weightData.where((w) => w.actualWeight != null).map((w) => w.actualWeight!),
    ];
    return (allVals.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();
  }

  double get weightChartMin {
    if (_weightData.isEmpty) return 0;
    final allVals = [
      ..._weightData.map((w) => w.systemWeight),
      ..._weightData.where((w) => w.actualWeight != null).map((w) => w.actualWeight!),
    ];
    final min = allVals.reduce((a, b) => a < b ? a : b);
    return (min * 0.85).floorToDouble().clamp(0, double.infinity);
  }

  /// BMI saat ini
  double? get currentBMI {
    final user = _user;
    if (user == null) return null;
    final w = user.weight;
    final h = user.height;
    if (w == null || h == null || h == 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  String get bmiCategory {
    final bmi = currentBMI;
    if (bmi == null) return '-';
    if (bmi < 18.5) return 'Kekurangan berat badan';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Kelebihan berat badan';
    return 'Obesitas';
  }

  Color get bmiColor {
    final bmi = currentBMI;
    if (bmi == null) return Colors.grey;
    if (bmi < 18.5) return const Color(0xFF1E88E5);
    if (bmi < 25) return const Color(0xFF2E7D32);
    if (bmi < 30) return const Color(0xFFF59E0B);
    return const Color(0xFFE53935);
  }
}
