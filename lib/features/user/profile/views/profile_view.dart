import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';
import 'package:nutritrack_app/helpers/calorie_helper.dart';
import 'package:nutritrack_app/features/general/auth/views/login_view.dart';
import 'package:nutritrack_app/services/hive_service.dart';
import 'package:intl/intl.dart';
import 'package:nutritrack_app/features/user/progress/models/weight_log_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import './qr_scanner_page.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:nutritrack_app/services/submission_firebase_service.dart';
import 'package:nutritrack_app/features/user/notification/views/notification_settings_view.dart';
import 'package:nutritrack_app/features/user/profile/views/widgets/profile_edit_dialogs.dart';
import 'package:nutritrack_app/helpers/subscription_helper.dart';
import 'package:nutritrack_app/features/user/profile/views/premium_upgrade_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // ─── Color Palette ───────────────────────────────────────────────────────
  static const _green = Color(0xFF2E7D32);
  static const _greenLight = Color(0xFF4CAF50);
  static const _bg = Color(0xFFF1F8F1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().fetchMonitors();
    });
  }

  final List<String> _activityLevels = [
    'Sedikit aktif atau tidak berolahraga',
    'Olahraga ringan (1-3 hari/minggu)',
    'Cukup aktif (olahraga sekitar 3-5 hari/minggu)',
    'Sangat aktif (olahraga berat/olahraga 6-7 hari seminggu)',
    'Ekstra aktif (Berolahraga secara berat disertai pekerjaan fisik)',
  ];

  // ─── Helper: Save updated UserModel ──────────────────────────────────────
  Future<void> _saveUser(UserModel updated) async {
    context.read<AuthController>().updateProfile(updated);
  }

  double _recalcCalories({
    required UserModel user,
    double? weight,
    double? height,
    int? age,
    String? gender,
    String? activityLevel,
    double? target,
  }) {
    final w = weight ?? user.weight;
    final h = height ?? user.height;
    final a = age ?? user.age;
    final g = gender ?? user.gender ?? 'Perempuan';
    final act = activityLevel ?? user.activityLevel ?? _activityLevels[0];
    final t = target ?? user.targetWeightGainPerMonth ?? 0;

    if (w != null && h != null && a != null) {
      return CalorieHelper.calculateDailyCalorieNeed(
        weightKg: w,
        heightCm: h,
        age: a,
        gender: g,
        activityLevel: act,
        targetWeightGainPerMonth: t,
      );
    }
    return user.dailyCalorieNeed ?? 2000.0;
  }

  // ─── Edit: Foto Profil ───────────────────────────────────────────────────
  Future<void> _editProfilePhoto(UserModel user) async {
    final picker = ImagePicker();
    final pickedFile = await showDialog<XFile?>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.photo_camera_rounded, color: _green),
                SizedBox(width: 8),
                Text(
                  'Pilih Foto Profil',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: const Color(0xFFF4FAF4),
                  leading: const Icon(Icons.camera_alt_rounded, color: _green),
                  title: const Text(
                    'Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap:
                      () async => Navigator.pop(
                        ctx,
                        await picker.pickImage(source: ImageSource.camera),
                      ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: const Color(0xFFE3F2FD),
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF1976D2),
                  ),
                  title: const Text(
                    'Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap:
                      () async => Navigator.pop(
                        ctx,
                        await picker.pickImage(source: ImageSource.gallery),
                      ),
                ),
              ],
            ),
          ),
    );

    if (pickedFile == null || !mounted) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Foto',
          toolbarColor: _green,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Crop Foto'),
      ],
    );

    if (croppedFile == null || !mounted) return;

    final newFile = File(croppedFile.path);
    String? newUrl = user.profileImageUrl;
    bool isSynced = false;

    try {
      newUrl = await SubmissionFirebaseService.uploadImage(
        newFile.path,
        user.id,
        folder: 'users',
      );
      isSynced = true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline: Foto disimpan lokal')),
        );
      }
    }

    final updated = user.copyWith(
      localProfileImagePath: newFile.path,
      profileImageUrl: newUrl ?? user.profileImageUrl,
      isProfileImageSynced: isSynced,
    );
    await _saveUser(updated);
  }

  // ─── Edit: Nama ──────────────────────────────────────────────────────────
  void _editName(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CuteTextEditModal(
            title: 'Edit Nama',
            label: 'Nama Lengkap',
            initialValue: user.name,
            onSave: (newName) async {
              await _saveUser(user.copyWith(name: newName));
            },
          ),
    );
  }

  // ─── Edit: Jenis Kelamin ─────────────────────────────────────────────────
  void _editGender(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CuteGenderEditModal(
            initialGender: user.gender ?? 'Perempuan',
            onSave: (newGender) async {
              final newCal = _recalcCalories(user: user, gender: newGender);
              await _saveUser(
                user.copyWith(gender: newGender, dailyCalorieNeed: newCal),
              );
            },
          ),
    );
  }

  // ─── Edit: Umur ──────────────────────────────────────────────────────────
  void _editAge(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CuteNumberEditModal(
            title: 'Edit Umur',
            label: 'Seberapa tua kamu? 🎂',
            initialValue: (user.age ?? 20).toDouble(),
            unit: 'tahun',
            step: 1,
            isDecimal: false,
            minValue: 1,
            maxValue: 120,
            onSave: (val) async {
              final newAge = val.round();
              final newCal = _recalcCalories(user: user, age: newAge);
              await _saveUser(
                user.copyWith(age: newAge, dailyCalorieNeed: newCal),
              );
            },
          ),
    );
  }

  // ─── Edit: Tinggi Badan ──────────────────────────────────────────────────
  void _editHeight(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CuteNumberEditModal(
            title: 'Edit Tinggi Badan',
            label: 'Tinggi badanmu saat ini 📏',
            initialValue: user.height ?? 160,
            unit: 'cm',
            step: 1,
            isDecimal: false,
            minValue: 50,
            maxValue: 250,
            onSave: (val) async {
              final newCal = _recalcCalories(user: user, height: val);
              await _saveUser(
                user.copyWith(height: val, dailyCalorieNeed: newCal),
              );
            },
          ),
    );
  }

  // ─── Edit: BB Awal ───────────────────────────────────────────────────────
  void _editInitialWeight(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CuteNumberEditModal(
            title: 'Edit Berat Awal',
            label: 'Berat badan awal perjalananmu ⚖️',
            initialValue: user.initialWeight ?? user.weight ?? 60,
            unit: 'kg',
            step: 0.5,
            isDecimal: true,
            minValue: 20,
            maxValue: 300,
            onSave: (val) async {
              await _saveUser(user.copyWith(initialWeight: val));
            },
          ),
    );
  }

  // ─── Edit: BB Saat Ini ───────────────────────────────────────────────────
  void _editCurrentWeight(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CuteNumberEditModal(
            title: 'Edit Berat Saat Ini',
            label: 'Berat badanmu hari ini ⚡',
            initialValue: user.weight ?? 60,
            unit: 'kg',
            step: 0.5,
            isDecimal: true,
            minValue: 20,
            maxValue: 300,
            onSave: (val) async {
              final newCal = _recalcCalories(user: user, weight: val);
              await _saveUser(
                user.copyWith(weight: val, dailyCalorieNeed: newCal),
              );

              // Sinkronisasi ke log berat bulan ini
              final now = DateTime.now();
              final key = '${user.id}_${now.year}_${now.month}';
              final log = WeightLogModel(
                id: key,
                userId: user.id,
                month: DateTime(now.year, now.month, 1),
                actualWeight: val,
              );
              await HiveService.weightLogs.put(key, log);
            },
          ),
    );
  }

  // ─── Edit: Target BB ─────────────────────────────────────────────────────
  void _editTargetWeight(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CuteNumberEditModal(
            title: 'Edit Target BB/Bulan',
            label: '(- = turun, + = naik) 🎯',
            initialValue: user.targetWeightGainPerMonth ?? 0,
            unit: 'kg/bln',
            step: 0.1,
            isDecimal: true,
            minValue: -10,
            maxValue: 10,
            onSave: (val) async {
              final history = Map<String, double>.from(
                user.targetHistory ?? {},
              );
              if (val != user.targetWeightGainPerMonth) {
                history[DateFormat('yyyy-MM').format(DateTime.now())] = val;
              }
              final newCal = _recalcCalories(user: user, target: val);
              await _saveUser(
                user.copyWith(
                  targetWeightGainPerMonth: val,
                  targetHistory: history,
                  dailyCalorieNeed: newCal,
                ),
              );
            },
          ),
    );
  }

  // ─── Edit: Aktivitas ─────────────────────────────────────────────────────
  void _editActivity(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CuteActivityEditModal(
            initialActivity: user.activityLevel ?? _activityLevels[0],
            activityLevels: _activityLevels,
            onSave: (newActivity) async {
              final newCal = _recalcCalories(
                user: user,
                activityLevel: newActivity,
              );
              await _saveUser(
                user.copyWith(
                  activityLevel: newActivity,
                  dailyCalorieNeed: newCal,
                ),
              );
            },
          ),
    );
  }

  // ─── Parental Control Helpers ─────────────────────────────────────────────
  void _showMyQR(String myId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'QR Code & ID Anda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2E1A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tunjukkan QR ini kepada orang tua agar dapat memantau aktivitas Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                QrImageView(
                  data: myId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final painter = QrPainter(
                        data: myId,
                        version: QrVersions.auto,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        color: const Color(0xFF000000),
                        emptyColor: const Color(0xFFFFFFFF),
                        gapless: true,
                      );
                      const double qrSize = 1024,
                          margin = 100,
                          totalSize = qrSize + margin * 2;
                      final recorder = ui.PictureRecorder();
                      final canvas = Canvas(
                        recorder,
                        const Rect.fromLTWH(0, 0, totalSize, totalSize),
                      );
                      canvas.drawRect(
                        const Rect.fromLTWH(0, 0, totalSize, totalSize),
                        Paint()..color = Colors.white,
                      );
                      canvas.save();
                      canvas.translate(margin, margin);
                      painter.paint(canvas, const Size(qrSize, qrSize));
                      canvas.restore();
                      final img = await recorder.endRecording().toImage(
                        totalSize.toInt(),
                        totalSize.toInt(),
                      );
                      final picData = await img.toByteData(
                        format: ui.ImageByteFormat.png,
                      );
                      if (picData != null) {
                        await Gal.putImageBytes(picData.buffer.asUint8List());
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'QR berhasil disimpan ke Galeri!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: _green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Download QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelectableText(
                        myId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: myId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ID disalin!')),
                          );
                        },
                        child: const Icon(
                          Icons.copy_rounded,
                          color: _green,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  void _showScanOrInput(AuthController auth) {
    final idCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pantau Anak',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2E1A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: idCtrl,
                          decoration: InputDecoration(
                            labelText: 'Masukkan ID Anak',
                            filled: true,
                            fillColor: const Color(0xFFF4FAF4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5A7A5A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () async {
                          final scannedId = await Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => const QRScannerPage(),
                            ),
                          );
                          if (scannedId != null && scannedId is String)
                            idCtrl.text = scannedId;
                        },
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: _green,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (idCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        _confirmStartMonitoring(auth, idCtrl.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Mulai Pantau',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _confirmStartMonitoring(AuthController auth, String childId) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder:
              (context, setS) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Konfirmasi Pantau'),
                content:
                    isLoading
                        ? const SizedBox(
                          height: 50,
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : Text('Pantau akun dengan ID:\n$childId?'),
                actions:
                    isLoading
                        ? []
                        : [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              setS(() => isLoading = true);
                              final success = await auth.startMonitoring(
                                childId,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        auth.errorMessage ?? 'Gagal memantau',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Ya, Pantau',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
              ),
        );
      },
    );
  }

  void _confirmRemoveMonitoredUser(AuthController auth, UserModel child) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Hapus Anak?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text('Berhenti memantau aktivitas ${child.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  auth.removeMonitoredUser(child.id);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final kaloriTarget = user.dailyCalorieNeed ?? 2000.0;
        final macros = user.macroTargets;

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(user, auth),
                  const SizedBox(height: 20),
                  _buildPremiumSection(user, auth),
                  const SizedBox(height: 20),
                  _buildNutrisiTarget(kaloriTarget, macros),
                  const SizedBox(height: 20),
                  _buildPersonalisasi(user, auth),
                  const SizedBox(height: 20),
                  _buildNotificationSettings(),
                  const SizedBox(height: 20),
                  _buildParentalControl(auth),
                  const SizedBox(height: 20),
                  if (!auth.isMonitoring) _buildLogoutSection(auth),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(UserModel user, AuthController auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Top row: Title + (monitoring badge)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                auth.isMonitoring ? '👀 Profil Anak' : '🌿 Profil Saya',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              if (auth.isMonitoring)
                GestureDetector(
                  onTap: () => _confirmStopMonitoring(auth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.exit_to_app_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Kembali',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Profile picture + name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Photo (tappable to edit)
              GestureDetector(
                onTap:
                    auth.isMonitoring
                        ? () => _viewProfilePhoto(user)
                        : () => _editProfilePhoto(user),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(child: _buildAvatarImage(user, 80)),
                    ),
                    if (!auth.isMonitoring)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: _green,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Name + info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name with pencil edit icon
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: SubscriptionHelper.isPremium(user) ? const Color(0xFFFFA000) : Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            SubscriptionHelper.isPremium(user) ? 'PREMIUM' : 'FREE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!auth.isMonitoring) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _editName(user),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.drive_file_rename_outline_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    _headerInfoChip(
                      icon: Icons.wc_rounded,
                      label:
                          '${user.gender ?? '-'} • ${user.age != null ? '${user.age} thn' : '-'}',
                    ),
                    const SizedBox(height: 4),
                    _headerInfoChip(
                      icon: Icons.monitor_weight_rounded,
                      label:
                          '${user.weight != null ? '${user.weight!.toStringAsFixed(1)} kg' : '-'} • ${user.height != null ? '${user.height!.toStringAsFixed(0)} cm' : '-'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _confirmStopMonitoring(AuthController auth) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Kembali ke Profil Utama?'),
            content: const Text(
              'Anda akan berhenti memantau aktivitas anak ini.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  auth.stopMonitoring();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _green),
                child: const Text(
                  'Ya, Kembali',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _viewProfilePhoto(UserModel user) {
    final hasLocal =
        user.localProfileImagePath != null &&
        user.localProfileImagePath!.isNotEmpty &&
        File(user.localProfileImagePath!).existsSync();
    final hasNetwork =
        user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;
    if (!hasLocal && !hasNetwork) return;

    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child:
                        hasLocal
                            ? Image.file(
                              File(user.localProfileImagePath!),
                              fit: BoxFit.contain,
                            )
                            : Image.network(
                              user.profileImageUrl!,
                              fit: BoxFit.contain,
                            ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // ─── Nutrisi Target ───────────────────────────────────────────────────────
  Widget _buildNutrisiTarget(double kaloriTarget, Map<String, double> macros) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🔥 Target Nutrisi Harian'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: _greenLight,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Kebutuhan Kalori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2E1A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${kaloriTarget.toInt()} kkal/hari',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE8F5E9)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _macroCard(
                        'Protein',
                        macros['protein'] ?? 0,
                        const Color(0xFFEF5350),
                        const Color(0xFFFFEBEE),
                        '🥩',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _macroCard(
                        'Lemak',
                        macros['fat'] ?? 0,
                        const Color(0xFFFFA726),
                        const Color(0xFFFFF3E0),
                        '🧈',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _macroCard(
                        'Karbo',
                        macros['carbs'] ?? 0,
                        const Color(0xFF42A5F5),
                        const Color(0xFFE3F2FD),
                        '🍚',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCard(
    String label,
    double val,
    Color color,
    Color bg,
    String emoji,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            '${val.toStringAsFixed(0)}g',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF5A7A5A),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'target/hari',
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  // ─── Personalisasi (per-field editable) ───────────────────────────────────
  Widget _buildPersonalisasi(UserModel user, AuthController auth) {
    final actShort =
        (user.activityLevel ?? '-').length > 22
            ? '${(user.activityLevel ?? '-').substring(0, 20)}…'
            : (user.activityLevel ?? '-');
    final targetStr =
        user.targetWeightGainPerMonth != null
            ? '${user.targetWeightGainPerMonth! >= 0 ? '+' : ''}${user.targetWeightGainPerMonth!.toStringAsFixed(1)} kg/bln'
            : '-';

    final List<_PersonaItem> items = [
      _PersonaItem(
        icon: Icons.wc_rounded,
        label: 'Jenis Kelamin',
        value: user.gender ?? '-',
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF42A5F5),
        onTap: auth.isMonitoring ? null : () => _editGender(user),
      ),
      _PersonaItem(
        icon: Icons.height_rounded,
        label: 'Tinggi Badan',
        value:
            user.height != null ? '${user.height!.toStringAsFixed(0)} cm' : '-',
        iconBg: const Color(0xFFE8F5E9),
        iconColor: _greenLight,
        onTap: auth.isMonitoring ? null : () => _editHeight(user),
      ),
      _PersonaItem(
        icon: Icons.cake_rounded,
        label: 'Umur',
        value: user.age != null ? '${user.age} tahun' : '-',
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFFFA726),
        onTap: auth.isMonitoring ? null : () => _editAge(user),
      ),
      _PersonaItem(
        icon: Icons.monitor_weight_rounded,
        label: 'BB Awal',
        value:
            user.initialWeight != null
                ? '${user.initialWeight!.toStringAsFixed(1)} kg'
                : '-',
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFEF5350),
        onTap: auth.isMonitoring ? null : () => _editInitialWeight(user),
      ),
      _PersonaItem(
        icon: Icons.scale_rounded,
        label: 'BB Saat Ini',
        value:
            user.weight != null ? '${user.weight!.toStringAsFixed(1)} kg' : '-',
        iconBg: const Color(0xFFE8F5E9),
        iconColor: _green,
        onTap: auth.isMonitoring ? null : () => _editCurrentWeight(user),
      ),
      _PersonaItem(
        icon: Icons.directions_run_rounded,
        label: 'Aktivitas',
        value: actShort,
        iconBg: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFFAB47BC),
        onTap: auth.isMonitoring ? null : () => _editActivity(user),
      ),
      _PersonaItem(
        icon: Icons.track_changes_rounded,
        label: 'Target BB/Bulan',
        value: targetStr,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFFF7043),
        onTap: auth.isMonitoring ? null : () => _editTargetWeight(user),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('✏️ Personalisasi'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children:
                  items.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    final isFirst = idx == 0;
                    final isLast = idx == items.length - 1;
                    return Column(
                      children: [
                        _buildPersonaRow(
                          item,
                          isFirst: isFirst,
                          isLast: isLast,
                          isMonitor: auth.isMonitoring,
                        ),
                        if (!isLast)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18),
                            child: Divider(height: 1, color: Color(0xFFF0F4F0)),
                          ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaRow(
    _PersonaItem item, {
    required bool isFirst,
    required bool isLast,
    required bool isMonitor,
  }) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(24) : Radius.zero,
        bottom: isLast ? const Radius.circular(24) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E1A),
                ),
              ),
            ),
            Text(
              item.value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isMonitor ? const Color(0xFF1976D2) : item.iconColor,
              ),
            ),
            if (!isMonitor) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8EBA8E),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Notifikasi ───────────────────────────────────────────────────────────
  Widget _buildNotificationSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🔔 Notifikasi'),
          const SizedBox(height: 12),
          _actionCard(
            icon: Icons.notifications_active_rounded,
            label: 'Atur Pengingat Makan',
            iconBg: const Color(0xFFE8F5E9),
            iconColor: _green,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsView(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // ─── Kontrol Orang Tua ────────────────────────────────────────────────────
  Widget _buildParentalControl(AuthController auth) {
    if (auth.isMonitoring) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('👨‍👩‍👧 Kontrol Orang Tua'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _actionRow(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Tampilkan QR / ID Saya',
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: _green,
                  onTap: () => _showMyQR(auth.mainUser!.id),
                  isFirst: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(height: 1, color: Color(0xFFF0F4F0)),
                ),
                _actionRow(
                  icon: Icons.document_scanner_rounded,
                  label: 'Pantau Aktivitas Anak',
                  iconBg: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF42A5F5),
                  onTap: () => _showScanOrInput(auth),
                  isLast: !auth.hasMonitoredUser && auth.monitors.isEmpty,
                ),
                if (auth.hasMonitoredUser) ...[
                  for (var i = 0; i < auth.monitoredUsersList.length; i++) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Divider(height: 1, color: Color(0xFFF0F4F0)),
                    ),
                    _monitoredChildTile(
                      auth.monitoredUsersList[i],
                      auth,
                      isLast: (i == auth.monitoredUsersList.length - 1) && auth.monitors.isEmpty,
                    ),
                  ],
                ],
                if (auth.monitors.isNotEmpty) ...[
                  for (var i = 0; i < auth.monitors.length; i++) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Divider(height: 1, color: Color(0xFFF0F4F0)),
                    ),
                    _monitoredByParentTile(auth.monitors[i], auth),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monitoredChildTile(
    UserModel child,
    AuthController auth, {
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.face_rounded,
              color: Color(0xFFFF9800),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2E1A),
                  ),
                ),
                Text(
                  'ID: ${child.id}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmRemoveMonitoredUser(auth, child),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => auth.resumeMonitoringById(child.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Pantau',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monitoredByParentTile(UserModel parent, AuthController auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.supervised_user_circle_rounded,
              color: _green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2E1A),
                  ),
                ),
                Text(
                  parent.email,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Memantau',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Logout Section (BARU – di bawah Kontrol Orang Tua) ──────────────────
  Widget _buildLogoutSection(AuthController auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🚪 Keluar Akun'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFE53935),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Konfirmasi Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        content: const Text(
                          'Anda yakin ingin keluar dari akun?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: Color(0xFF5A7A5A)),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Keluar',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  await auth.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                    (route) => false,
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFE53935),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFE53935),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A2E1A),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _actionRow(
        icon: icon,
        label: label,
        iconBg: iconBg,
        iconColor: iconColor,
        onTap: onTap,
        isFirst: true,
        isLast: true,
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(24) : Radius.zero,
        bottom: isLast ? const Radius.circular(24) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E1A),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: iconColor.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(UserModel user, double size) {
    final hasLocal =
        user.localProfileImagePath != null &&
        user.localProfileImagePath!.isNotEmpty &&
        File(user.localProfileImagePath!).existsSync();
    final hasNetwork =
        user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;

    if (hasLocal) {
      return Image.file(
        File(user.localProfileImagePath!),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder:
            (_, __, ___) => Icon(
              Icons.person_rounded,
              color: Colors.white70,
              size: size * 0.5,
            ),
      );
    } else if (hasNetwork) {
      return Image.network(
        user.profileImageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder:
            (_, __, ___) => Icon(
              Icons.person_rounded,
              color: Colors.white70,
              size: size * 0.5,
            ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        color: Colors.white.withOpacity(0.2),
        child: Icon(
          Icons.person_rounded,
          color: Colors.white70,
          size: size * 0.5,
        ),
      );
    }
  }

  Widget _buildPremiumSection(UserModel user, AuthController auth) {
    if (auth.isMonitoring) return const SizedBox.shrink();

    final isPremium = SubscriptionHelper.isPremium(user);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🌟 Keanggotaan'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _actionRow(
              icon: Icons.workspace_premium_rounded,
              label: isPremium ? 'Premium Aktif (Kelola)' : 'Upgrade ke Premium',
              iconBg: isPremium ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
              iconColor: isPremium ? const Color(0xFFFFA000) : _green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumUpgradeView()),
                );
              },
              isFirst: true,
              isLast: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Class untuk baris Personalisasi ────────────────────────────────────
class _PersonaItem {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;

  const _PersonaItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.iconColor,
    this.onTap,
  });
}
