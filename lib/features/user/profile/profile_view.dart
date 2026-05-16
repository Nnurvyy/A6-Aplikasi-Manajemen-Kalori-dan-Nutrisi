import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../general/auth/auth_controller.dart';
import '../../general/auth/models/user_model.dart';
import '../../../helpers/calorie_helper.dart';
import '../../general/auth/login_view.dart';
import '../../../services/hive_service.dart';
import 'package:intl/intl.dart';
import '../progress/models/weight_log_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import './qr_scanner_page.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../services/submission_firebase_service.dart';
import '../notification/notification_settings_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const _green = Color(0xFF2E7D32);
  static const _greenLight = Color(0xFF4CAF50);
  static const _bg = Color(0xFFF4FAF4);

  final List<String> _activityLevels = [
    'Sedikit aktif atau tidak berolahraga',
    'Olahraga ringan (1-3 hari/minggu)',
    'Cukup aktif (olahraga sekitar 3-5 hari/minggu)',
    'Sangat aktif (olahraga berat/olahraga 6-7 hari seminggu)',
    'Ekstra aktif (Berolahraga secara berat disertai pekerjaan fisik)',
  ];



  void _editProfil(UserModel user) {
    final namaCtrl = TextEditingController(text: user.name);
    String jenisKelamin = user.gender ?? 'Perempuan';
    final tinggiCtrl = TextEditingController(
      text: user.height?.toStringAsFixed(0) ?? '',
    );
    final umurCtrl = TextEditingController(text: user.age?.toString() ?? '');
    final beratCtrl = TextEditingController(
      text: user.weight?.toStringAsFixed(1) ?? '',
    );
    final initialBeratCtrl = TextEditingController(
      text: user.initialWeight?.toStringAsFixed(1) ?? '',
    );
    final targetCtrl = TextEditingController(
      text: user.targetWeightGainPerMonth?.toStringAsFixed(1) ?? '0',
    );
    String selectedActivity =
        _activityLevels.contains(user.activityLevel)
            ? user.activityLevel!
            : _activityLevels[0];

    File? newProfileImage;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setModal) => Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Edit Profil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2E1A),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final pickedFile = await showDialog<XFile?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Pilih Foto Profil'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt),
                                        title: const Text('Kamera'),
                                        onTap: () async => Navigator.pop(ctx, await picker.pickImage(source: ImageSource.camera)),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library),
                                        title: const Text('Galeri'),
                                        onTap: () async => Navigator.pop(ctx, await picker.pickImage(source: ImageSource.gallery)),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              if (pickedFile != null) {
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
                                    IOSUiSettings(
                                      title: 'Crop Foto',
                                    ),
                                  ],
                                );
                                if (croppedFile != null) {
                                  setModal(() => newProfileImage = File(croppedFile.path));
                                }
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: newProfileImage != null
                                        ? Image.file(newProfileImage!, fit: BoxFit.cover, width: 80, height: 80)
                                        : (user.localProfileImagePath != null && user.localProfileImagePath!.isNotEmpty && File(user.localProfileImagePath!).existsSync())
                                            ? Image.file(
                                                File(user.localProfileImagePath!),
                                                fit: BoxFit.cover,
                                                width: 80,
                                                height: 80,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey, size: 40),
                                              )
                                            : (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                                                ? Image.network(
                                                    user.profileImageUrl!,
                                                    fit: BoxFit.cover,
                                                    width: 80,
                                                    height: 80,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey, size: 40),
                                                  )
                                                : const Icon(Icons.person, color: Colors.grey, size: 40),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                    ),
                                    child: Icon(
                                      user.isProfileImageSynced ? Icons.cloud_done : Icons.cloud_off,
                                      color: user.isProfileImageSynced ? Colors.green : Colors.orange,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: _green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _inputField('Nama', namaCtrl),
                        const SizedBox(height: 14),
                        const Text(
                          'Jenis Kelamin',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5A7A5A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children:
                              ['Laki-laki', 'Perempuan'].map((g) {
                                final selected = jenisKelamin == g;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => setModal(() => jenisKelamin = g),
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        right: g == 'Laki-laki' ? 8 : 0,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            selected
                                                ? _green
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        g,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              selected
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _inputField(
                                'Tinggi (cm)',
                                tinggiCtrl,
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _inputField(
                                'Umur',
                                umurCtrl,
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _inputField(
                                'BB Awal (kg)',
                                initialBeratCtrl,
                                isDecimal: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _inputField(
                                'BB Saat Ini (kg)',
                                beratCtrl,
                                isDecimal: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          'Target BB/bulan (kg, - = turun)',
                          targetCtrl,
                          isDecimal: true,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tingkat Aktivitas',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5A7A5A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4FAF4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: selectedActivity,
                            isExpanded: true,
                            underline: const SizedBox(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A2E1A),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setModal(() => selectedActivity = val);
                              }
                            },
                            items:
                                _activityLevels
                                    .map(
                                      (a) => DropdownMenuItem(
                                        value: a,
                                        child: Text(
                                          a,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              setModal(() => isSaving = true);
                              final h = double.tryParse(tinggiCtrl.text.trim());
                              final a = int.tryParse(umurCtrl.text.trim());
                              final w = double.tryParse(beratCtrl.text.trim());
                              final initW = double.tryParse(initialBeratCtrl.text.trim());
                              final target =
                                  double.tryParse(targetCtrl.text.trim()) ?? 0;
                              final newCal =
                                  (h != null && a != null && w != null)
                                      ? CalorieHelper.calculateDailyCalorieNeed(
                                        weightKg: w,
                                        heightCm: h,
                                        age: a,
                                        gender: jenisKelamin,
                                        activityLevel: selectedActivity,
                                        targetWeightGainPerMonth: target,
                                      )
                                      : user.dailyCalorieNeed;

                              final history = Map<String, double>.from(user.targetHistory ?? {});
                              if (target != user.targetWeightGainPerMonth) {
                                history[DateFormat('yyyy-MM').format(DateTime.now())] = target;
                              }

                              String? newUrl = user.profileImageUrl;
                              String? newLocalPath = newProfileImage?.path ?? user.localProfileImagePath;
                              bool isImageSynced = newProfileImage == null ? user.isProfileImageSynced : false;

                              if (newProfileImage != null) {
                                try {
                                  newUrl = await SubmissionFirebaseService.uploadImage(
                                    newProfileImage!.path,
                                    user.id,
                                    folder: 'users',
                                  );
                                  isImageSynced = true;
                                } catch (e) {
                                  isImageSynced = false;
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Offline: Foto profil disimpan lokal')),
                                    );
                                  }
                                }
                              }

                              final updated = UserModel(
                                id: user.id,
                                name:
                                    namaCtrl.text.trim().isEmpty
                                        ? user.name
                                        : namaCtrl.text.trim(),
                                email: user.email,
                                password: user.password,
                                role: user.role,
                                gender: jenisKelamin,
                                height: h ?? user.height,
                                age: a ?? user.age,
                                weight: w ?? user.weight,
                                activityLevel: selectedActivity,
                                birthDate: user.birthDate,
                                dailyCalorieNeed: newCal,
                                targetWeightGainPerMonth: target,
                                initialWeight: initW ?? user.initialWeight,
                                targetHistory: history,
                                isBlocked: user.isBlocked,
                                profileImageUrl: newUrl,
                                localProfileImagePath: newLocalPath,
                                isProfileImageSynced: isImageSynced,
                              );
                              context
                                  .read<AuthController>()
                                  .updateProfile(updated);
                              
                              // SINKRONISASI: Update juga di log berat badan bulan ini jika berat diinput
                              if (w != null) {
                                final now = DateTime.now();
                                final key = '${user.id}_${now.year}_${now.month}';
                                final log = WeightLogModel(
                                  id: key,
                                  userId: user.id,
                                  month: DateTime(now.year, now.month, 1),
                                  actualWeight: w,
                                );
                                await HiveService.weightLogs.put(key, log);
                              }

                              if (mounted) Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text(
                                    'Simpan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5A7A5A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
              isDecimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : isNumber
                  ? TextInputType.number
                  : TextInputType.text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A2E1A)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF4FAF4),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() { // ← BARU TAHAP 4
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengingat Makan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2E1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
            child: _chevronAction(
              Icons.notifications_active_rounded,
              'Atur Notifikasi Makan',
              const Color(0xFFE8F5E9),
              _green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsView(),
                ),
              ),
              isFirst: true,
              isLast: true,
            ),
          ),
        ],
      ),
    );
  }
 

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
                  _buildNutrisiTarget(kaloriTarget, macros),
                  const SizedBox(height: 20),
                  _buildPersonalisasi(user, auth),
                  const SizedBox(height: 20),
                  _buildNotificationSettings(),
                  const SizedBox(height: 20),
                  _buildParentalControl(auth),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParentalControl(AuthController auth) {
    if (auth.isMonitoring) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kontrol Orang Tua',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2E1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _chevronAction(
                  Icons.qr_code_2_rounded,
                  'Tampilkan QR / ID Saya',
                  const Color(0xFFE8F5E9),
                  _green,
                  onTap: () => _showMyQR(auth.mainUser!.id),
                  isFirst: true,
                ),
                _divider(),
                _chevronAction(
                  Icons.document_scanner_rounded,
                  'Pantau Aktivitas Anak (Baru)',
                  const Color(0xFFE3F2FD),
                  const Color(0xFF42A5F5),
                  onTap: () => _showScanOrInput(auth),
                  isLast: !auth.hasMonitoredUser,
                ),
                if (auth.hasMonitoredUser) ...[
                  _divider(),
                  _chevronAction(
                    Icons.play_circle_fill_rounded,
                    'Lanjutkan Pantau Anak (Terakhir)',
                    const Color(0xFFFFF3E0),
                    const Color(0xFFFF9800),
                    onTap: () => auth.resumeMonitoring(),
                    isLast: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmStopMonitoring(AuthController auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kembali ke Utama?'),
        content: const Text('Anda akan berhenti memantau aktivitas anak ini dan kembali ke profil Anda sendiri.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              auth.stopMonitoring();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            child: const Text('Ya, Kembali'),
          ),
        ],
      ),
    );
  }

  void _showMyQR(String myId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'QR Code & ID Anda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2E1A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tunjukkan QR ini atau bagikan ID di bawah kepada orang tua Anda agar mereka dapat memantau aktivitas Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            QrImageView(
              data: myId,
              version: QrVersions.auto,
              size: 200.0,
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
                  
                  // Membuat margin putih (Quiet Zone) secara manual agar scanner mudah mendeteksi
                  const double qrSize = 1024.0;
                  const double margin = 100.0;
                  const double totalSize = qrSize + (margin * 2);
                  
                  final recorder = ui.PictureRecorder();
                  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, totalSize, totalSize));
                  
                  // Gambar background putih
                  canvas.drawRect(const Rect.fromLTWH(0, 0, totalSize, totalSize), Paint()..color = Colors.white);
                  
                  // Gambar QR di tengah
                  canvas.save();
                  canvas.translate(margin, margin);
                  painter.paint(canvas, const Size(qrSize, qrSize));
                  canvas.restore();
                  
                  final img = await recorder.endRecording().toImage(totalSize.toInt(), totalSize.toInt());
                  final picData = await img.toByteData(format: ui.ImageByteFormat.png);
                  if (picData != null) {
                    await Gal.putImageBytes(picData.buffer.asUint8List());
                    if (mounted) {
                      Navigator.pop(context); // tutup modal
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white),
                              SizedBox(width: 10),
                              Text('QR Code berhasil disimpan ke Galeri!', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          backgroundColor: const Color(0xFF2E7D32),
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan QR: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              label: const Text('Download QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: myId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ID berhasil disalin!')),
                      );
                    },
                    child: const Icon(Icons.copy_rounded, color: _green, size: 20),
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
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pantau Anak',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2E1A),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _inputField('Masukkan ID Anak', idCtrl)),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: IconButton(
                      onPressed: () async {
                        final scannedId = await Navigator.push(
                          ctx,
                          MaterialPageRoute(builder: (_) => const QRScannerPage()),
                        );
                        if (scannedId != null && scannedId is String) {
                          idCtrl.text = scannedId;
                        }
                      },
                      icon: const Icon(Icons.qr_code_scanner, color: _green, size: 32),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Mulai Pantau', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Konfirmasi Pantau'),
              content: isLoading 
                ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
                : Text('Apakah Anda yakin ingin mulai memantau aktivitas akun dengan ID:\n$childId?'),
              actions: isLoading ? [] : [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() => isLoading = true);
                    final success = await auth.startMonitoring(childId);
                    if (mounted) {
                      Navigator.pop(ctx);
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(auth.errorMessage ?? 'Gagal memantau')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white, // Agar teks putih dan kontras
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ya, Pantau', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _chevronAction(
    IconData icon,
    String label,
    Color iconBg,
    Color iconColor, {
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(20) : Radius.zero,
            bottom: isLast ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A2E1A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8EBA8E),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user, AuthController auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                auth.isMonitoring ? 'Profil Anak' : 'Profil',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  if (!auth.isMonitoring) ...[
                    GestureDetector(
                      onTap: () => _editProfil(user),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'Edit Profil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final authCtrl = context.read<AuthController>();
                        await authCtrl.logout();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginView()),
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.logout, color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'Keluar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final hasLocal = user.localProfileImagePath != null && user.localProfileImagePath!.isNotEmpty && File(user.localProfileImagePath!).existsSync();
                  final hasNetwork = user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;

                  if (hasLocal || hasNetwork) {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            InteractiveViewer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: hasLocal
                                    ? Image.file(File(user.localProfileImagePath!), fit: BoxFit.contain)
                                    : Image.network(user.profileImageUrl!, fit: BoxFit.contain),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: Builder(
                  builder: (context) {
                    final hasLocal = user.localProfileImagePath != null && user.localProfileImagePath!.isNotEmpty && File(user.localProfileImagePath!).existsSync();
                    final hasNetwork = user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;
                    return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white38, width: 2),
                      ),
                      child: ClipOval(
                        child: hasLocal
                            ? Image.file(
                                File(user.localProfileImagePath!),
                                fit: BoxFit.cover,
                                width: 64,
                                height: 64,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 34),
                              )
                            : (hasNetwork
                                ? Image.network(
                                    user.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 34),
                                  )
                                : const Icon(Icons.person, color: Colors.white, size: 34)),
                      ),
                    );
                  }
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.gender ?? '-'} • ${user.age != null ? '${user.age} tahun' : '-'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.weight != null ? '${user.weight!.toStringAsFixed(1)} kg' : '-'} • ${user.height != null ? '${user.height!.toStringAsFixed(0)} cm' : '-'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrisiTarget(double kaloriTarget, Map<String, double> macros) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Nutrisi Harian',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2E1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: _greenLight,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Target Kalori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2E1A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${kaloriTarget.toInt()} kkal/hari',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
                      child: _nutri(
                        'Protein',
                        macros['protein'] ?? 0,
                        const Color(0xFFEF5350),
                        const Color(0xFFFFEBEE),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _nutri(
                        'Lemak',
                        macros['fat'] ?? 0,
                        const Color(0xFFFFA726),
                        const Color(0xFFFFF3E0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _nutri(
                        'Karbo',
                        macros['carbs'] ?? 0,
                        const Color(0xFF42A5F5),
                        const Color(0xFFE3F2FD),
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

  Widget _nutri(String label, double val, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '${val.toStringAsFixed(0)}g',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF5A7A5A)),
          ),
          const SizedBox(height: 4),
          Text(
            'target/hari',
            style: const TextStyle(fontSize: 10, color: Color(0xFF8EBA8E)),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalisasi(UserModel user, AuthController auth) {
    final activity = user.activityLevel ?? '-';
    final actShort =
        activity.length > 20 ? '${activity.substring(0, 18)}...' : activity;
    final target =
        user.targetWeightGainPerMonth != null
            ? '${user.targetWeightGainPerMonth! >= 0 ? '+' : ''}${user.targetWeightGainPerMonth!.toStringAsFixed(1)} kg/bln'
            : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalisasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2E1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _chevron(
                  Icons.wc_rounded,
                  'Jenis Kelamin',
                  user.gender ?? '-',
                  const Color(0xFFE8F5E9),
                  _greenLight,
                  user: user,
                  auth: auth,
                  isFirst: true,
                ),
                _divider(),
                _chevron(
                  Icons.height_rounded,
                  'Tinggi Badan',
                  user.height != null
                      ? '${user.height!.toStringAsFixed(0)} cm'
                      : '-',
                  const Color(0xFFE3F2FD),
                  const Color(0xFF42A5F5),
                  user: user,
                  auth: auth,
                ),
                _divider(),
                _chevron(
                  Icons.cake_rounded,
                  'Umur',
                  user.age != null ? '${user.age} tahun' : '-',
                  const Color(0xFFFFF3E0),
                  const Color(0xFFFFA726),
                  user: user,
                  auth: auth,
                ),
                _divider(),
                _chevron(
                  Icons.monitor_weight_rounded,
                  'BB Awal',
                  user.initialWeight != null
                      ? '${user.initialWeight!.toStringAsFixed(1)} kg'
                      : '-',
                  const Color(0xFFFFEBEE),
                  const Color(0xFFEF5350),
                  user: user,
                  auth: auth,
                ),
                _divider(),
                _chevron(
                  Icons.history_rounded,
                  'BB Saat Ini',
                  user.weight != null
                      ? '${user.weight!.toStringAsFixed(1)} kg'
                      : '-',
                  const Color(0xFFE8F5E9),
                  const Color(0xFF2E7D32),
                  user: user,
                  auth: auth,
                ),
                _divider(),
                _chevron(
                  Icons.directions_run_rounded,
                  'Aktivitas',
                  actShort,
                  const Color(0xFFE8F5E9),
                  _green,
                  user: user,
                  auth: auth,
                ),
                _divider(),
                _chevron(
                  Icons.track_changes_rounded,
                  'Target BB',
                  target,
                  const Color(0xFFF3E5F5),
                  const Color(0xFFAB47BC),
                  user: user,
                  auth: auth,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chevron(
    IconData icon,
    String label,
    String value,
    Color iconBg,
    Color iconColor, {
    required UserModel user,
    required AuthController auth,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isMonitor = auth.isMonitoring;
    return GestureDetector(
      onTap: isMonitor ? null : () => _editProfil(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(20) : Radius.zero,
            bottom: isLast ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A2E1A),
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isMonitor ? const Color(0xFF1976D2) : const Color(0xFF2E7D32),
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

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 18),
    child: Divider(height: 1, color: Color(0xFFE8F5E9)),
  );
}

