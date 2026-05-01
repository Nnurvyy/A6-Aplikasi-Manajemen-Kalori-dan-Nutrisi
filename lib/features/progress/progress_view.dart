import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../auth/auth_controller.dart';
import 'progress_controller.dart';

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});
  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> with TickerProviderStateMixin {
  late final ProgressController _ctrl;
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ProgressController();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _ctrl.setActiveNutrientTab(_tabCtrl.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        _ctrl.init(user);
        if (_ctrl.shouldShowWeightModal && _ctrl.pendingWeightMonth != null) {
          _showWeightModal(_ctrl.pendingWeightMonth!);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showWeightModal(DateTime month) {
    final fmt = DateFormat('MMMM yyyy', 'id');
    final ctrl = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF2E7D32), size: 32),
            ),
            const SizedBox(height: 12),
            Text('Update Berat Badan', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(fmt.format(month), style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Masukkan berat badan aktual kamu bulan ${fmt.format(month)} untuk melacak progress kamu.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Berat badan (kg)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.monitor_weight_outlined),
                filled: true,
                fillColor: const Color(0xFFF4F6F0),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _ctrl.skipWeightInput(month: month);
              if (mounted) { 
                Navigator.of(ctx).pop(); 
                setState(() {}); 
              }
            },
            child: const Text('Lewati'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final v = double.tryParse(ctrl.text.trim());
              if (v != null && v > 0) {
                await _ctrl.saveActualWeight(month: month, weight: v);
                if (mounted) { 
                  Navigator.of(ctx).pop(); 
                  setState(() {}); 
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan dialog pilih bulan & tahun menggunakan gaya Wheel (ListWheelScrollView)
  Future<DateTime?> _showMonthYearPicker({DateTime? initialDate, String title = 'Pilih Bulan'}) async {
    final now = DateTime.now();
    final init = initialDate ?? now;
    int selectedYear = init.year;
    int selectedMonth = init.month;

    final months = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    final years = List.generate(10, (i) => now.year - i);

    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFF4F6F0),
                  border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    // Bulan
                    Expanded(
                      flex: 2,
                      child: _wheelPicker(
                        items: months,
                        selected: selectedMonth - 1,
                        onChanged: (i) => setS(() => selectedMonth = i + 1),
                        label: 'Bulan',
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFF2E7D32).withOpacity(0.1)),
                    // Tahun
                    Expanded(
                      flex: 1,
                      child: _wheelPicker(
                        items: years.map((y) => y.toString()).toList(),
                        selected: years.indexOf(selectedYear),
                        onChanged: (i) => setS(() => selectedYear = years[i]),
                        label: 'Tahun',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${months[selectedMonth - 1]} $selectedYear',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                final result = DateTime(selectedYear, selectedMonth);
                if (result.isAfter(now)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tidak bisa memilih bulan di masa depan')),
                  );
                } else {
                  Navigator.pop(ctx, result);
                }
              },
              child: const Text('Pilih'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheelPicker({
    required List<String> items,
    required int selected,
    required void Function(int) onChanged,
    required String label,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32).withOpacity(0.6))),
        ),
        Expanded(
          child: ListWheelScrollView(
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: selected.clamp(0, items.length - 1)),
            onSelectedItemChanged: onChanged,
            children: items.asMap().entries.map((e) {
              final isSelected = e.key == selected;
              return Center(
                child: Text(
                  e.value,
                  style: GoogleFonts.poppins(
                    fontSize: isSelected ? 16 : 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _handleWeightInputClick() async {
    final now = DateTime.now();
    // Default ke bulan lalu jika hari ini masih awal bulan, atau bulan ini
    DateTime initial = DateTime(now.year, now.month);
    if (now.day < 5) {
      initial = DateTime(now.year, now.month - 1);
    }
    
    final selected = await _showMonthYearPicker(initialDate: initial, title: 'Pilih Bulan Input BB');
    if (selected != null) {
      _showWeightModal(selected);
    }
  }

  /// Tampilkan dialog pilih bulan & tahun untuk navigasi periode chart
  Future<void> _handlePeriodNavClick(ProgressController ctrl) async {
    if (ctrl.period == ChartPeriod.daily) {
      final selected = await _showMonthYearPicker(
        initialDate: DateTime(ctrl.viewYear, ctrl.viewMonth),
        title: 'Pilih Periode',
      );
      if (selected != null) {
        ctrl.setViewMonthYear(selected.year, selected.month);
      }
    } else {
      await _showPeriodYearPicker(ctrl);
    }
  }

  /// Tampilkan dialog pilih tahun untuk navigasi mode monthly
  Future<void> _showPeriodYearPicker(ProgressController ctrl) async {
    final now = DateTime.now();
    int selectedYear = ctrl.viewYearMonthly;

    final year = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Pilih Tahun', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
          content: SizedBox(
            width: 240,
            height: 200,
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (_, i) {
                final year = now.year - i;
                final isSelected = year == selectedYear;
                return GestureDetector(
                  onTap: () => setS(() => selectedYear = year),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFF4F6F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$year',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx, selectedYear),
              child: const Text('Pilih'),
            ),
          ],
        ),
      ),
    );
    
    if (year != null) {
      ctrl.setViewYearMonthly(year);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<ProgressController>(
        builder: (context, ctrl, _) => Scaffold(
          backgroundColor: const Color(0xFFF4F6F0),
          body: CustomScrollView(
            slivers: [
              _buildAppBar(ctrl),
              SliverToBoxAdapter(child: _buildStatsSection(ctrl)),
              SliverToBoxAdapter(child: _buildNutritionSection(ctrl)),
              SliverToBoxAdapter(child: _buildWeightSection(ctrl)),
              SliverToBoxAdapter(child: _buildActivityGrid(ctrl)),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ProgressController ctrl) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF2E7D32),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text('Progress', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF388E3C), Color(0xFF1B5E20)]),
          ),
        ),
      ),
      actions: const [],
    );
  }

  Widget _buildStatsSection(ProgressController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Ideal Weight Card
          Expanded(
            child: _statCard(
              title: 'Berat Ideal',
              value: ctrl.idealWeightStatusMessage,
              subtitle: 'Target: ${ctrl.idealWeight.toStringAsFixed(1)} kg',
              icon: Icons.star_rounded,
              onTap: () => _showIdealWeightDetail(ctrl),
            ),
          ),
          const SizedBox(width: 12),
          // BMI Card
          Expanded(
            child: _statCard(
              title: 'Status BMI',
              value: ctrl.bmiStatusMessage,
              subtitle: 'BMI: ${ctrl.currentBMI?.toStringAsFixed(1) ?? "-"}',
              icon: Icons.monitor_weight_rounded,
              onTap: () => _showBMIDetail(ctrl),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                subtitle,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityGrid(ProgressController ctrl) {
    final monthName = DateFormat('MMMM yyyy', 'id').format(DateTime(ctrl.viewYearActivity, ctrl.viewMonthActivity));
    final data = ctrl.activityData;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aktivitas Nutrisi', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                      Text(monthName, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                _navBadge(
                  label: DateFormat('MMM yy', 'id').format(DateTime(ctrl.viewYearActivity, ctrl.viewMonthActivity)),
                  onTap: () => _handleActivityNavClick(ctrl),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final dayData = data[index];
                final status = ctrl.getCalorieStatus(dayData);
                
                Color color;
                switch (status) {
                  case 1: color = const Color(0xFF4CAF50); break; // Green
                  case 2: color = const Color(0xFFFFC107); break; // Yellow
                  case 3: color = const Color(0xFFEF5350); break; // Red
                  default: color = Colors.grey.withOpacity(0.15); // Empty/Gray
                }
                
                return Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: status == 0 ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildGridLegendDetailed(),
            const SizedBox(height: 16),
            Text(
              'Tips: Jaga rantai kotak hijau agar tetap konsisten!',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLegendDetailed() {
    return Column(
      children: [
        _legendItemDetailed(const Color(0xFF4CAF50), 'Sesuai Target (90-110%)'),
        const SizedBox(height: 4),
        _legendItemDetailed(const Color(0xFFFFC107), 'Hampir Target (70-130%)'),
        const SizedBox(height: 4),
        _legendItemDetailed(const Color(0xFFEF5350), 'Jauh dari Target / Terlewat'),
      ],
    );
  }

  Widget _legendItemDetailed(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Future<void> _handleActivityNavClick(ProgressController ctrl) async {
    final selected = await _showMonthYearPicker(
      initialDate: DateTime(ctrl.viewYearActivity, ctrl.viewMonthActivity),
      title: 'Pilih Periode Aktivitas',
    );
    if (selected != null) {
      ctrl.setViewMonthYearActivity(selected.year, selected.month);
    }
  }

  Widget _buildGridLegend() {
    return Row(
      children: [
        _legendItem(const Color(0xFF4CAF50)),
        const SizedBox(width: 4),
        _legendItem(const Color(0xFFFFC107)),
        const SizedBox(width: 4),
        _legendItem(const Color(0xFFEF5350)),
      ],
    );
  }

  Widget _legendItem(Color color) {
    return Container(
      width: 10,
    height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }

  void _showIdealWeightDetail(ProgressController ctrl) {
    final weight = ctrl.user?.weight ?? 0.0;
    final ideal = ctrl.idealWeight;
    final diff = (weight - ideal).abs();
    final status = ctrl.idealWeightStatusMessage;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Text('Analisis Berat Ideal', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(status, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('BB Saat Ini', '${weight.toStringAsFixed(1)} kg'),
                    const SizedBox(height: 12),
                    _infoRow('BB Ideal', '${ideal.toStringAsFixed(1)} kg', isHighlighted: true),
                    const SizedBox(height: 12),
                    _infoRow('Selisih', '${diff.toStringAsFixed(1)} kg'),
                    const Divider(height: 32),
                    Text('Bagaimana Cara Menghitungnya?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rumus Berat Ideal:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(
                            ctrl.user?.gender == 'Laki-laki' 
                              ? 'Berat badan ideal (kg) = [tinggi badan (cm) - 100] - [(tinggi badan (cm) - 100) x 10%]'
                              : 'Berat badan ideal (kg) = [tinggi badan (cm) - 100] + [(tinggi badan (cm) - 100) x 15%]', 
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Keterangan: Rumus ini menggunakan indeks Broca yang disesuaikan dengan jenis kelamin. Untuk laki-laki dikurangi 10% dan untuk perempuan ditambah 15% dari selisih tinggi terhadap 100.',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBMIDetail(ProgressController ctrl) {
    final bmi = ctrl.currentBMI ?? 0.0;
    final weight = ctrl.user?.weight ?? 0.0;
    final height = ctrl.user?.height ?? 0.0;

    // Tentukan kategori dan range
    String category = ctrl.bmiCategory;
    Color catColor = ctrl.bmiColor;
    String advice = ctrl.bmiStatusMessage;

    final bmiRanges = [
      _BMIRange('Kurus', '< 18.5', const Color(0xFF1E88E5)),
      _BMIRange('Normal', '18.5 – 24.9', const Color(0xFF2E7D32)),
      _BMIRange('Overweight', '25.0 – 29.9', const Color(0xFFF59E0B)),
      _BMIRange('Obesitas', '≥ 30.0', const Color(0xFFE53935)),
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: catColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Text(category, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Skor BMI: ${bmi.toStringAsFixed(1)}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('BB Saat Ini', '${weight.toStringAsFixed(1)} kg'),
                    const SizedBox(height: 12),
                    _infoRow('Tinggi Badan', '${height.toStringAsFixed(0)} cm'),
                    const Divider(height: 32),
                    Text('Analisis', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(advice, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),
                    Text('Bagaimana Cara Menghitungnya?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rumus BMI:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                          Text('Berat (kg) / (Tinggi/100)²', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Klasifikasi BMI:', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 12),
                    ...bmiRanges.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(r.label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500))),
                          Text(r.range, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _infoRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
        Text(
          value, 
          style: GoogleFonts.poppins(
            fontSize: 15, 
            fontWeight: FontWeight.w700, 
            color: isHighlighted ? const Color(0xFF2E7D32) : Colors.black87
          )
        ),
      ],
    );
  }

  double _bmiRangeStart(String label) {
    switch (label) {
      case 'Kurus': return 0;
      case 'Normal': return 18.5;
      case 'Overweight': return 25.0;
      case 'Obesitas': return 30.0;
      default: return 0;
    }
  }

  double _bmiRangeEnd(String label) {
    switch (label) {
      case 'Kurus': return 18.5;
      case 'Normal': return 25.0;
      case 'Overweight': return 30.0;
      case 'Obesitas': return 999;
      default: return 999;
    }
  }

  Widget _buildBMIGauge(double? bmi) {
    final value = (bmi ?? 22.0).clamp(10.0, 40.0);
    final pct = (value - 10) / 30;
    return SizedBox(
      width: 80, height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: pct, strokeWidth: 8, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(bmi == null ? Colors.white38 : Colors.white)),
          Icon(Icons.person_outline_rounded, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(ProgressController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Konsumsi Nutrisi', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A2E1A))),
          const SizedBox(height: 12),
          // Toggle daily/monthly
          Row(
            children: [
              _periodBtn(ctrl, 'Per Hari', ChartPeriod.daily),
              const SizedBox(width: 8),
              _periodBtn(ctrl, 'Per Bulan', ChartPeriod.monthly),
              const Spacer(),
              _buildPeriodNav(ctrl),
            ],
          ),
          const SizedBox(height: 12),
          // Nutrient tabs
          Container(
            height: 40,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(color: ctrl.activeNutrientColor, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
              tabs: const [Tab(text: 'Kalori'), Tab(text: 'Protein'), Tab(text: 'Karbo'), Tab(text: 'Lemak')],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          _buildStatsRow(ctrl),
          const SizedBox(height: 16),
          // Bar chart
          _buildNutritionChart(ctrl),
        ],
      ),
    );
  }

  Widget _periodBtn(ProgressController ctrl, String label, ChartPeriod p) {
    final active = ctrl.period == p;
    return GestureDetector(
      onTap: () => ctrl.setPeriod(p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 8)] : [],
        ),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildPeriodNav(ProgressController ctrl) {
    final isDaily = ctrl.period == ChartPeriod.daily;
    final label = isDaily
        ? DateFormat('MMM yyyy', 'id').format(DateTime(ctrl.viewYear, ctrl.viewMonth))
        : '${ctrl.viewYearMonthly}';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handlePeriodNavClick(ctrl),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32))),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF2E7D32), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(ProgressController ctrl) {
    final stats = ctrl.nutritionStats;
    final unit = ctrl.activeNutrientUnit;
    return Row(
      children: [
        _statChip('Rata-rata', '${stats['avg']!.toStringAsFixed(1)} $unit', ctrl.activeNutrientColor),
        const SizedBox(width: 8),
        _statChip('Tertinggi', '${stats['max']!.toStringAsFixed(1)} $unit', ctrl.activeNutrientColor),
        const SizedBox(width: 8),
        _statChip('Total', '${stats['total']!.toStringAsFixed(0)} $unit', ctrl.activeNutrientColor),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionChart(ProgressController ctrl) {
    final data = ctrl.nutritionData;
    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('Belum ada data', style: GoogleFonts.poppins(color: Colors.grey)),
      );
    }
    final maxY = data.map(ctrl.nutrientValue).reduce((a, b) => a > b ? a : b);
    final interval = maxY == 0 ? 1.0 : (maxY / 4).ceilToDouble();

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 10 : maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: interval, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey)))),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  // Show every N-th label to avoid crowding
                  final step = ctrl.period == ChartPeriod.daily ? 5 : 1;
                  if (ctrl.period == ChartPeriod.daily && (i + 1) % step != 0 && i != 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(data[i].label, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(data.length, (i) {
            final val = ctrl.nutrientValue(data[i]);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: val,
                  width: ctrl.period == ChartPeriod.daily ? 6 : 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [ctrl.activeNutrientColorLight, ctrl.activeNutrientColor],
                  ),
                ),
              ],
            );
          }),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1A2E1A),
              getTooltipItem: (group, _, rod, __) {
                final p = data[group.x];
                return BarTooltipItem(
                  '${p.label}\n${rod.toY.toStringAsFixed(1)} ${ctrl.activeNutrientUnit}',
                  GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightSection(ProgressController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Grafik Berat Badan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A2E1A)))),
              _buildWeightYearSelector(ctrl),
            ],
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              _legendDot(const Color(0xFF2E7D32), 'BB Aktual'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF7C4DFF), 'Proyeksi Sistem'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 260,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: _buildWeightChart(ctrl),
          ),
          const SizedBox(height: 16),
          _buildWeightInputButton(ctrl),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWeightYearSelector(ProgressController ctrl) {
    return _navBadge(
      label: '${ctrl.viewYearWeight}',
      onTap: () async {
        final now = DateTime.now();
        int selectedYear = ctrl.viewYearWeight;

        final year = await showDialog<int>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setS) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Pilih Tahun BB', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
              content: SizedBox(
                width: 240,
                height: 200,
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (_, i) {
                    final year = now.year - i;
                    final isSelected = year == selectedYear;
                    return GestureDetector(
                      onTap: () => setS(() => selectedYear = year),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFF4F6F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$year',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(ctx, selectedYear),
                  child: const Text('Pilih'),
                ),
              ],
            ),
          ),
        );

        if (year != null) {
          ctrl.setViewYearWeight(year);
        }
      },
    );
  }

  Widget _navBadge({required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32))),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF2E7D32), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightChart(ProgressController ctrl) {
    final data = ctrl.weightData;
    if (data.isEmpty) {
      return Center(child: Text('Belum ada data', style: GoogleFonts.poppins(color: Colors.grey)));
    }
    final minY = ctrl.weightChartMin;
    final maxY = ctrl.weightChartMax;
    final interval = ((maxY - minY) / 4).ceilToDouble();

    // Build spots
    final systemSpots = <FlSpot>[];
    final actualSpots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      systemSpots.add(FlSpot(i.toDouble(), data[i].systemWeight));
      if (data[i].actualWeight != null) {
        actualSpots.add(FlSpot(i.toDouble(), data[i].actualWeight!));
      }
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval > 0 ? interval : 1,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: interval > 0 ? interval : 1, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= data.length) return const SizedBox();
            return Padding(padding: const EdgeInsets.only(top: 4), child: Text(data[i].label, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey)));
          })),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A2E1A),
            getTooltipItems: (spots) => spots.map((s) {
              final isActual = s.barIndex == 0;
              return LineTooltipItem(
                '${isActual ? "Aktual" : "Sistem"}: ${s.y.toStringAsFixed(1)} kg',
                GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Actual weight line
          if (actualSpots.isNotEmpty)
            LineChartBarData(
              spots: actualSpots,
              isCurved: true,
              color: const Color(0xFF2E7D32),
              barWidth: 3,
              dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: const Color(0xFF2E7D32), strokeWidth: 2, strokeColor: Colors.white)),
              belowBarData: BarAreaData(show: true, color: const Color(0xFF2E7D32).withOpacity(0.08)),
            ),
          // System projection line
          LineChartBarData(
            spots: systemSpots,
            isCurved: true,
            color: const Color(0xFF7C4DFF),
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInputButton(ProgressController ctrl) {
    return GestureDetector(
      onTap: _handleWeightInputClick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF388E3C)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.monitor_weight_outlined, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Input Berat Badan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('Pilih bulan untuk mencatat BB aktual', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _BMIRange {
  final String label;
  final String range;
  final Color color;
  const _BMIRange(this.label, this.range, this.color);
}
