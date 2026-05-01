import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../../services/hive_service.dart';
import '../../general/auth/models/user_model.dart';
import '../../general/food/models/log_model.dart';
import './models/weight_log_model.dart';

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
  UserModel? get user => _user;
  StreamSubscription? _logSub;
  StreamSubscription? _weightSub;
  StreamSubscription? _userSub;

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

  // Tahun yang sedang dilihat untuk chart berat badan
  int _viewYearWeight = DateTime.now().year;
  int get viewYearWeight => _viewYearWeight;

  // Bulan/tahun untuk Aktivitas Nutrisi (Grid)
  int _viewMonthActivity = DateTime.now().month;
  int _viewYearActivity = DateTime.now().year;
  int get viewMonthActivity => _viewMonthActivity;
  int get viewYearActivity => _viewYearActivity;

  // Tab nutrisi aktif: 0=Kalori, 1=Protein, 2=Karbohidrat, 3=Lemak
  int _activeNutrientTab = 0;
  int get activeNutrientTab => _activeNutrientTab;

  List<NutritionDataPoint> _nutritionData = [];
  List<NutritionDataPoint> get nutritionData => _nutritionData;

  List<NutritionDataPoint> _activityData = [];
  List<NutritionDataPoint> get activityData => _activityData;

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
    _buildActivityData();

    _logSub?.cancel();
    _logSub = HiveService.logs.watch().listen((_) {
      _buildNutritionData();
      _buildActivityData();
      notifyListeners();
    });

    _weightSub?.cancel();
    _weightSub = HiveService.weightLogs.watch().listen((_) {
      _buildWeightData();
      notifyListeners();
    });

    _userSub?.cancel();
    _userSub = HiveService.users.watch().listen((event) {
      final updated = HiveService.users.get(_user?.id);
      if (updated != null) {
        _user = updated;
        _buildWeightData();
        _checkWeightModalNeeded();
        notifyListeners();
      }
    });

    notifyListeners();
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _weightSub?.cancel();
    _userSub?.cancel();
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
    
    // Simpan ke log berat badan untuk grafik
    final key = _weightLogKey(user.id, month);
    final log = WeightLogModel(
      id: key,
      userId: user.id,
      month: DateTime(month.year, month.month, 1),
      actualWeight: weight,
    );
    await HiveService.weightLogs.put(key, log);

    // SINKRONISASI: Jika yang diinput adalah bulan saat ini, update juga berat di profile user
    final now = DateTime.now();
    if (month.year == now.year && month.month == now.month) {
      user.weight = weight;
      await user.save(); // Simpan perubahan ke box users
    }

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
        (_viewYear == now.year && _viewMonth >= now.month)) {
      return;
    }
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

  void setViewYearWeight(int year) {
    _viewYearWeight = year;
    _buildWeightData();
    notifyListeners();
  }

  void setViewMonthYearActivity(int year, int month) {
    _viewYearActivity = year;
    _viewMonthActivity = month;
    _buildActivityData();
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

  void _buildActivityData() {
    final user = _user;
    if (user == null) {
      _activityData = [];
      return;
    }

    final allLogs = HiveService.logs.values
        .whereType<LogModel>()
        .where((l) => l.userId == user.id)
        .toList();

    final daysInMonth = _daysInMonth(_viewYearActivity, _viewMonthActivity);
    final Map<int, List<LogModel>> byDay = {};
    for (var d = 1; d <= daysInMonth; d++) {
      byDay[d] = [];
    }

    for (final log in allLogs) {
      if (log.consumedAt.year == _viewYearActivity &&
          log.consumedAt.month == _viewMonthActivity) {
        byDay[log.consumedAt.day]?.add(log);
      }
    }

    _activityData = List.generate(daysInMonth, (i) {
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

  void _buildDailyData(List<LogModel> logs) {
    final daysInMonth = _daysInMonth(_viewYear, _viewMonth);
    final Map<int, List<LogModel>> byDay = {};
    for (var d = 1; d <= daysInMonth; d++) {
      byDay[d] = [];
    }

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

    DateTime? accountCreated;
    try {
      final ms = int.parse(user.id.replaceAll('user_', ''));
      accountCreated = DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      accountCreated = DateTime.now();
    }

    final startWeight = user.initialWeight ?? user.weight ?? 60.0;
    final targetHistory = user.targetHistory ?? {};
    final currentTarget = user.targetWeightGainPerMonth ?? 0.0;

    double getTargetForMonth(DateTime month) {
      final key = DateFormat('yyyy-MM').format(month);
      if (targetHistory.containsKey(key)) return targetHistory[key]!;
      final sortedKeys = targetHistory.keys.toList()..sort();
      String latestKey = "";
      for (final k in sortedKeys) {
        if (k.compareTo(key) <= 0) {
          latestKey = k;
        } else {
          break;
        }
      }
      return latestKey.isNotEmpty ? targetHistory[latestKey]! : currentTarget;
    }

    double getProjectionFor(DateTime targetMonth) {
      final refMonth = DateTime(accountCreated!.year, accountCreated.month, 1);
      final targetM = DateTime(targetMonth.year, targetMonth.month, 1);
      double val = startWeight;
      
      if (targetM.isAfter(refMonth)) {
        DateTime curr = refMonth;
        while (curr.isBefore(targetM)) {
          val += getTargetForMonth(curr);
          curr = DateTime(curr.year, curr.month + 1, 1);
        }
      } else if (targetM.isBefore(refMonth)) {
        DateTime curr = refMonth;
        while (curr.isAfter(targetM)) {
          curr = DateTime(curr.year, curr.month - 1, 1);
          val -= getTargetForMonth(curr);
        }
      }
      return val;
    }

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final now = DateTime.now();
    final result = <WeightDataPoint>[];

    for (int m = 1; m <= 12; m++) {
      final monthDate = DateTime(_viewYearWeight, m, 1);
      final systemWeight = getProjectionFor(monthDate);

      final key = _weightLogKey(user.id, monthDate);
      final actual = HiveService.weightLogs.get(key)?.actualWeight;
      final isFuture = monthDate.isAfter(now);

      result.add(WeightDataPoint(
        label: monthNames[m - 1],
        actualWeight: isFuture ? null : actual,
        systemWeight: systemWeight < 0 ? 0 : systemWeight,
      ));
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

  // ─── BMI & IDEAL WEIGHT ─────────────────────────────────────────────────────

  /// BMI saat ini
  double? get currentBMI {
    final user = _user;
    if (user == null) return null;
    final w = user.weight;
    final h = user.height;
    if (w == null || h == null || h == 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  /// Berat badan ideal berdasarkan rumus:
  /// Laki-laki: (Tinggi - 100) - (Tinggi - 100) * 10%
  /// Perempuan: (Tinggi - 100) + (Tinggi - 100) * 15%
  double get idealWeight {
    final user = _user;
    if (user == null || user.height == null || user.height == 0) return 0;
    
    final base = user.height! - 100;
    if (user.gender == 'Laki-laki') {
      return base - (base * 0.10);
    } else {
      // Mengikuti rumus user: + 15%
      return base + (base * 0.15);
    }
  }

  /// Pesan status berat badan ideal
  String get idealWeightStatusMessage {
    final user = _user;
    if (user == null || user.weight == null || user.height == null) return "-";
    final current = user.weight!;
    final ideal = idealWeight;
    final diff = (current - ideal).abs();
    
    // Anggap ideal jika selisih < 0.5kg
    if (diff < 0.5) {
      return "Berat badan kamu sudah ideal! ✨";
    } else if (current < ideal) {
      return "Kurang ${diff.toStringAsFixed(1)} kg untuk berat ideal";
    } else {
      return "Kelebihan ${diff.toStringAsFixed(1)} kg dari berat ideal";
    }
  }

  /// Pesan status BMI
  String get bmiStatusMessage {
    final bmi = currentBMI;
    if (bmi == null) return "-";
    if (bmi >= 18.5 && bmi < 25) {
      return "BMI kamu normal! ✨";
    } else if (bmi < 18.5) {
      return "BMI kamu di bawah normal";
    } else {
      return "BMI kamu di atas normal";
    }
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

  // ─── CALORIE CONTRIBUTION GRID ─────────────────────────────────────────────

  /// Status pencapaian kalori harian untuk grid (0: Gray, 1: Green, 2: Yellow, 3: Red)
  int getCalorieStatus(NutritionDataPoint p) {
    final target = _user?.dailyCalorieNeed ?? 2000;
    final actual = p.calories;
    if (actual == 0) return 0; // Tidak ada data / Lupa tracking
    
    final ratio = actual / target;
    // Berhasil jika dalam rentang 90% - 110% target
    if (ratio >= 0.9 && ratio <= 1.1) return 1;
    // Kurang sedikit/Kelebihan sedikit (70% - 130%)
    if (ratio >= 0.7 && ratio <= 1.3) return 2;
    // Jauh dari target
    return 3;
  }
}
