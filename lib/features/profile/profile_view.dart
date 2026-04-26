import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import '../auth/models/user_model.dart';
import '../../helpers/calorie_helper.dart';
import '../auth/login_view.dart';

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
    'Jarang olahraga',
    'Olahraga ringan (1-3 kali seminggu)',
    'Olahraga sedang (3-5 kali seminggu)',
    'Olahraga berat (6-7 hari seminggu / ngegym)',
    'Sangat berat (latihan fisik ekstra / atlet)',
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
    final targetCtrl = TextEditingController(
      text: user.targetWeightGainPerMonth?.toStringAsFixed(1) ?? '0',
    );
    String selectedActivity =
        _activityLevels.contains(user.activityLevel)
            ? user.activityLevel!
            : _activityLevels[0];

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
                            const SizedBox(width: 12),
                            Expanded(
                              child: _inputField(
                                'Berat (kg)',
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
                            onPressed: () async {
                              final h = double.tryParse(tinggiCtrl.text.trim());
                              final a = int.tryParse(umurCtrl.text.trim());
                              final w = double.tryParse(beratCtrl.text.trim());
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
                                medicalHistory: user.medicalHistory,
                                birthDate: user.birthDate,
                                dailyCalorieNeed: newCal,
                                targetWeightGainPerMonth: target,
                                isBlocked: user.isBlocked,
                              );
                              await context
                                  .read<AuthController>()
                                  .updateProfile(updated);
                              if (mounted) Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
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
        final kaloriTarget = user.dailyCalorieNeed ?? 2000;
        final macros = user.macroTargets;

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(user),
                  const SizedBox(height: 20),
                  _buildNutrisiTarget(kaloriTarget, macros),
                  const SizedBox(height: 20),
                  _buildPersonalisasi(user),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserModel user) {
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
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _editProfil(user),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Edit',
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
                      final auth = context.read<AuthController>();
                      await auth.logout();
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
                        color: Colors.red.withOpacity(0.8),
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
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 34),
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
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.weight != null ? '${user.weight!.toStringAsFixed(1)} kg' : '-'} • ${user.height != null ? '${user.height!.toStringAsFixed(0)} cm' : '-'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
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

  Widget _buildPersonalisasi(UserModel user) {
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
                  color: Colors.black.withOpacity(0.05),
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
                ),
                _divider(),
                _chevron(
                  Icons.cake_rounded,
                  'Umur',
                  user.age != null ? '${user.age} tahun' : '-',
                  const Color(0xFFFFF3E0),
                  const Color(0xFFFFA726),
                  user: user,
                ),
                _divider(),
                _chevron(
                  Icons.monitor_weight_rounded,
                  'Berat Badan',
                  user.weight != null
                      ? '${user.weight!.toStringAsFixed(1)} kg'
                      : '-',
                  const Color(0xFFFFEBEE),
                  const Color(0xFFEF5350),
                  user: user,
                ),
                _divider(),
                _chevron(
                  Icons.directions_run_rounded,
                  'Aktivitas',
                  actShort,
                  const Color(0xFFE8F5E9),
                  _green,
                  user: user,
                ),
                _divider(),
                _chevron(
                  Icons.track_changes_rounded,
                  'Target BB',
                  target,
                  const Color(0xFFF3E5F5),
                  const Color(0xFFAB47BC),
                  user: user,
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
    bool isFirst = false,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: () => _editProfil(user),
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 6),
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

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 18),
    child: Divider(height: 1, color: Color(0xFFE8F5E9)),
  );
}
