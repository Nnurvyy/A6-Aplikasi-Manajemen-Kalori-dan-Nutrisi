import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../helpers/app_colors.dart';
import 'auth_controller.dart';
import '../user_main_view.dart';
import '../shared/widgets/nt_button.dart';
import '../shared/widgets/nt_text_field.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _pageCtrl = PageController();
  int _currentStep = 0;

  // Step 1 – Akun
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _form1Key = GlobalKey<FormState>();

  // Step 2 – Profil
  String _gender = 'Laki-laki';
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String _activityLevel = 'Jarang olahraga';
  final _medHistory = TextEditingController();
  double _targetWeight = 0;
  final _form2Key = GlobalKey<FormState>();

  // Step 3 – Tanggal Lahir
  int _selectedYear = 2000;
  int _selectedMonth = 1;
  int _selectedDay = 1;

  final List<String> _activityLevels = [
    'Jarang olahraga',
    'Olahraga ringan (1-3 kali seminggu)',
    'Olahraga sedang (3-5 kali seminggu)',
    'Olahraga berat (6-7 hari seminggu / ngegym)',
    'Sangat berat (latihan fisik ekstra / atlet)',
  ];

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _medHistory.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep == 0 && !_form1Key.currentState!.validate()) return;
    if (_currentStep == 1 && !_form2Key.currentState!.validate()) return;
    if (_currentStep == 2) {
      _register();
      return;
    }
    setState(() => _currentStep++);
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _currentStep--);
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _register() async {
    final auth = context.read<AuthController>();
    final ok = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      weight: double.tryParse(_weightCtrl.text) ?? 60,
      height: double.tryParse(_heightCtrl.text) ?? 160,
      age: int.tryParse(_ageCtrl.text) ?? 20,
      gender: _gender,
      activityLevel: _activityLevel,
      medicalHistory: _medHistory.text.isEmpty ? 'Tidak ada' : _medHistory.text,
      birthDate: DateTime(_selectedYear, _selectedMonth, _selectedDay),
      targetWeightGainPerMonth: _targetWeight,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const UserMainView()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Registrasi gagal'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // ─── Header ───
          Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _back,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Step indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentStep == i ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentStep >= i
                                ? Colors.white
                                : Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Content ───
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(auth),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _form1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buat akun baru',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            Text('Masuk ke langkah 1 dari 3',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.lightTextSecondary)),
            const SizedBox(height: 24),
            NtTextField(
              label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap',
              controller: _nameCtrl,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            NtTextField(
              label: 'Email',
              hint: 'contoh@email.com',
              controller: _emailCtrl,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email wajib diisi';
                if (!v.contains('@')) return 'Email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 14),
            NtTextField(
              label: 'Password',
              hint: 'Minimal 6 karakter',
              controller: _passCtrl,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (v) =>
                  v != null && v.length < 6 ? 'Password minimal 6 karakter' : null,
            ),
            const SizedBox(height: 14),
            NtTextField(
              label: 'Konfirmasi Password',
              hint: 'Ulangi password',
              controller: _confirmCtrl,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (v) =>
                  v != _passCtrl.text ? 'Password tidak cocok' : null,
            ),
            const SizedBox(height: 28),
            NtButton(label: 'Lanjut', onPressed: _next),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _form2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Profil',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            Text('Langkah 2 dari 3',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.lightTextSecondary)),
            const SizedBox(height: 24),

            Text('Jenis Kelamin',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightTextPrimary)),
            const SizedBox(height: 8),
            Row(
              children: ['Laki-laki', 'Perempuan'].map((g) {
                final sel = _gender == g;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                          right: g == 'Laki-laki' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : AppColors.lightDivider,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            g == 'Laki-laki'
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            color: sel
                                ? Colors.white
                                : AppColors.lightTextSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(g,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: sel
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                              )),
                        ],
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
                  child: NtTextField(
                    label: 'Usia (tahun)',
                    hint: '20',
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.cake_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NtTextField(
                    label: 'BB (kg)',
                    hint: '60',
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.monitor_weight_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            NtTextField(
              label: 'TB (cm)',
              hint: '165',
              controller: _heightCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.height_rounded,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Tinggi badan wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            Text('Tambahan Aktivitas (Olahraga)',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightTextPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _activityLevel,
              items: _activityLevels
                  .map((p) =>
                      DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.poppins(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _activityLevel = v!),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.directions_run_rounded,
                    color: AppColors.primaryLight, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.lightBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.lightBorder)),
              ),
            ),
            const SizedBox(height: 14),
            NtTextField(
              label: 'Riwayat Penyakit',
              hint: 'Misal: diabetes, hipertensi (isi "Tidak ada" jika sehat)',
              controller: _medHistory,
              maxLines: 2,
              prefixIcon: Icons.medical_information_outlined,
            ),
            const SizedBox(height: 14),
            Text('Target Perubahan BB/bulan (kg)',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightTextPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _targetWeight,
                    min: -5,
                    max: 5,
                    divisions: 20,
                    label: _targetWeight > 0 
                        ? '+${_targetWeight.toStringAsFixed(1)} kg (Naik)' 
                        : _targetWeight < 0 
                            ? '${_targetWeight.toStringAsFixed(1)} kg (Turun)' 
                            : '0 kg (Tetap)',
                    activeColor: _targetWeight > 0 ? AppColors.primary : (_targetWeight < 0 ? Colors.orange : Colors.grey),
                    onChanged: (v) => setState(() => _targetWeight = v),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    _targetWeight > 0 
                        ? '+${_targetWeight.toStringAsFixed(1)}' 
                        : _targetWeight.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: _targetWeight > 0 ? AppColors.primary : (_targetWeight < 0 ? Colors.orange : AppColors.lightTextPrimary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _targetWeight > 0 
                  ? 'Surplus kalori untuk menaikkan berat badan.'
                  : _targetWeight < 0 
                      ? 'Defisit kalori untuk menurunkan berat badan.'
                      : 'Maintenance kalori untuk mempertahankan berat badan.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 28),
            NtButton(label: 'Lanjut', onPressed: _next),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3(AuthController auth) {
    final years = List.generate(80, (i) => DateTime.now().year - i);
    final days = List.generate(31, (i) => i + 1);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanggal Lahir',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          Text(
              'Data ini membantu kami menghitung rekomendasi\nasupan harian yang dipersonalisasi untuk Anda.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.lightTextSecondary,
                  height: 1.5)),
          const SizedBox(height: 32),

          // ─── Wheel Picker ───
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Row(
              children: [
                // Year
                Expanded(
                  child: _wheelPicker(
                    items: years.map((y) => y.toString()).toList(),
                    selected: _selectedYear,
                    onChanged: (v) =>
                        setState(() => _selectedYear = int.parse(v)),
                    label: 'Tahun',
                  ),
                ),
                Container(width: 1, color: AppColors.lightBorder),
                // Month
                Expanded(
                  child: _wheelPicker(
                    items: _months,
                    selected: _selectedMonth,
                    displayItems: _months,
                    onChanged: (v) =>
                        setState(() => _selectedMonth = _months.indexOf(v) + 1),
                    label: 'Bulan',
                    isMonth: true,
                  ),
                ),
                Container(width: 1, color: AppColors.lightBorder),
                // Day
                Expanded(
                  child: _wheelPicker(
                    items: days.map((d) => d.toString().padLeft(2, '0')).toList(),
                    selected: _selectedDay,
                    onChanged: (v) =>
                        setState(() => _selectedDay = int.parse(v)),
                    label: 'Tanggal',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${_selectedDay.toString().padLeft(2, '0')} ${_months[_selectedMonth - 1]} $_selectedYear',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const Spacer(),
          NtButton(
            label: 'Daftar Sekarang',
            isLoading: auth.isLoading,
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  Widget _wheelPicker({
    required List<String> items,
    required int selected,
    List<String>? displayItems,
    required void Function(String) onChanged,
    required String label,
    bool isMonth = false,
  }) {
    final display = displayItems ?? items;
    int initialIndex = 0;
    if (isMonth) {
      initialIndex = selected - 1;
    } else if (items.isNotEmpty) {
      final sv = selected.toString().padLeft(
          label == 'Tanggal' ? 2 : 0, label == 'Tanggal' ? '0' : '');
      initialIndex = items.indexOf(sv);
      if (initialIndex < 0) initialIndex = 0;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextSecondary)),
        ),
        Expanded(
          child: ListWheelScrollView(
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(
                initialItem: initialIndex.clamp(0, items.length - 1)),
            onSelectedItemChanged: (i) => onChanged(items[i]),
            children: display.asMap().entries.map((e) {
              final isSelected = e.key == initialIndex;
              return Center(
                child: Text(
                  e.value,
                  style: GoogleFonts.poppins(
                    fontSize: isSelected ? 16 : 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
