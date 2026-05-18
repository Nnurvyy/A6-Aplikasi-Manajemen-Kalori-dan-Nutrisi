import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'smartwatch_controller.dart';
import 'smartwatch_data_model.dart';

class SmartwatchSettingsView extends StatelessWidget {
  const SmartwatchSettingsView({super.key});

  static const _green = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF4FAF6);
  static const _dark = Color(0xFF1A2E22);
  static const _muted = Color(0xFF7A9485);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SmartwatchController>();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _dark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Smartwatch',
          style: TextStyle(
            color: _dark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (ctrl.isConnected)
            TextButton.icon(
              onPressed: () => _confirmDisconnect(context, ctrl),
              icon: const Icon(
                Icons.link_off_rounded,
                size: 16,
                color: Colors.red,
              ),
              label: const Text(
                'Putus',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
      // Stack: konten di bawah, blur overlay di atas
      body: Stack(
        children: [
          // ── Konten utama (selalu dirender, di-blur kalau coming soon) ──
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildStatusCard(context, ctrl),
              const SizedBox(height: 20),
              if (ctrl.isConnected) ...[
                _buildDataGrid(ctrl),
                const SizedBox(height: 20),
                _buildSyncButton(context, ctrl),
                const SizedBox(height: 20),
              ],
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildSupportedDevices(),
              const SizedBox(height: 80), // ruang ekstra bawah
            ],
          ),

          // ── Blur overlay "Coming Soon" ──────────────────────────────────
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ikon jam dengan efek glow
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _green.withValues(alpha: 0.4),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.watch_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Badge "Segera Hadir"
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SEGERA HADIR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Fitur Smartwatch',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Text(
                            'Fitur ini sedang dalam pengembangan.\n'
                            'Kami sedang mengurus izin Health Connect\nagar data smartwatch kamu bisa terbaca.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Chip fitur yang akan datang
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _comingSoonChip(
                              Icons.directions_walk_rounded,
                              'Langkah Kaki',
                            ),
                            _comingSoonChip(
                              Icons.favorite_rounded,
                              'Detak Jantung',
                            ),
                            _comingSoonChip(
                              Icons.local_fire_department_rounded,
                              'Kalori',
                            ),
                            _comingSoonChip(Icons.air_rounded, 'SpO2'),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // Tombol kembali
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Kembali',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comingSoonChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Card ──────────────────────────────────────────────────────────
  Widget _buildStatusCard(BuildContext context, SmartwatchController ctrl) {
    final isConnected = ctrl.isConnected;
    final isConnecting = ctrl.status == SmartwatchStatus.connecting;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isConnected
                  ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
                  : [const Color(0xFF455A64), const Color(0xFF546E7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isConnected ? _green : Colors.grey).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isConnected ? Icons.watch_rounded : Icons.watch_off_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected
                          ? 'Terhubung'
                          : isConnecting
                          ? 'Menghubungkan...'
                          : 'Belum Terhubung',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isConnected
                          ? 'Health Connect aktif'
                          : 'Hubungkan smartwatch kamu',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFF69F0AE) : Colors.white30,
                  shape: BoxShape.circle,
                  boxShadow:
                      isConnected
                          ? [
                            BoxShadow(
                              color: const Color(0xFF69F0AE).withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ]
                          : [],
                ),
              ),
            ],
          ),
          if (!isConnected) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null, // dinonaktifkan — coming soon
                icon: const Icon(
                  Icons.link_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
                label: const Text(
                  'Segera Hadir',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataGrid(SmartwatchController ctrl) {
    final data = ctrl.latestData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Hari Ini',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        const SizedBox(height: 12),
        _buildStepsCard(data),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFE53935),
                iconBg: const Color(0xFFFFEBEE),
                label: 'Detak Jantung',
                value:
                    data?.heartRate != null
                        ? '${data!.heartRate!.toInt()}'
                        : '-',
                unit: data?.heartRate != null ? 'bpm' : '',
                badge: data?.heartRateLabel,
                badgeColor: _heartRateColor(data?.heartRate),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFFF8C00),
                iconBg: const Color(0xFFFFF3E0),
                label: 'Kalori Terbakar',
                value:
                    data?.caloriesBurned != null
                        ? '${data!.caloriesBurned!.toInt()}'
                        : '-',
                unit: data?.caloriesBurned != null ? 'kkal' : '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          icon: Icons.air_rounded,
          iconColor: const Color(0xFF1E88E5),
          iconBg: const Color(0xFFE3F2FD),
          label: 'Saturasi Oksigen (SpO2)',
          value: data?.spO2 != null ? '${data!.spO2!.toStringAsFixed(1)}' : '-',
          unit: data?.spO2 != null ? '%' : '',
          badge: data?.spO2Label,
          badgeColor: _spO2Color(data?.spO2),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStepsCard(SmartwatchDataModel? data) {
    final steps = data?.steps ?? 0;
    final progress = data?.stepsProgress ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: _green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Langkah Kaki',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          data != null ? '$steps' : '-',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _dark,
                          ),
                        ),
                        if (data != null)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4, left: 4),
                            child: Text(
                              '/ 10.000 langkah',
                              style: TextStyle(fontSize: 11, color: _muted),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String unit,
    String? badge,
    Color? badgeColor,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child:
          isFullWidth
              ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(fontSize: 12, color: _muted),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _dark,
                              ),
                            ),
                            if (unit.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 3,
                                  left: 4,
                                ),
                                child: Text(
                                  unit,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? _green).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeColor ?? _green,
                        ),
                      ),
                    ),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: iconColor, size: 18),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? _green).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor ?? _green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _dark,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2, left: 3),
                          child: Text(
                            unit,
                            style: const TextStyle(fontSize: 10, color: _muted),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
    );
  }

  Widget _buildSyncButton(BuildContext context, SmartwatchController ctrl) {
    return GestureDetector(
      onTap: ctrl.isLoading ? null : () => ctrl.syncData(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              ctrl.isLoading ? Colors.grey.shade100 : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                ctrl.isLoading ? Colors.grey.shade300 : const Color(0xFFA5D6A7),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ctrl.isLoading
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _green,
                  ),
                )
                : const Icon(Icons.sync_rounded, color: _green, size: 20),
            const SizedBox(width: 8),
            Text(
              ctrl.isLoading ? 'Menyinkronkan...' : 'Sinkronkan Data Sekarang',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: ctrl.isLoading ? Colors.grey : _green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Cara Kerja',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Fitur ini menggunakan Health Connect (Android) untuk membaca data dari smartwatch kamu.\n\n'
            '• Pastikan app Health Connect terinstall di HP\n'
            '• Pastikan smartwatch sudah terhubung ke Health Connect\n'
            '• Data diambil secara lokal — tidak dikirim ke server lain\n'
            '• Kamu bisa cabut izin kapan saja melalui app Health Connect',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF5D4037),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedDevices() {
    final devices = [
      ('Samsung Galaxy Watch', Icons.watch_rounded, const Color(0xFF1E88E5)),
      ('Wear OS (Google)', Icons.watch_rounded, const Color(0xFF43A047)),
      (
        'Fitbit (via Health Connect)',
        Icons.monitor_heart_rounded,
        const Color(0xFF00ACC1),
      ),
      ('Xiaomi Mi Band', Icons.watch_rounded, const Color(0xFFE53935)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perangkat yang Didukung',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '(via Android Health Connect)',
          style: TextStyle(fontSize: 12, color: _muted),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
            ],
          ),
          child: Column(
            children: List.generate(devices.length, (i) {
              final d = devices[i];
              final isLast = i == devices.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: d.$3.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(d.$2, color: d.$3, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          d.$1,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _dark,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Didukung',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF0F0F0),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  void _confirmDisconnect(BuildContext context, SmartwatchController ctrl) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Putus Koneksi?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            content: const Text(
              'Data smartwatch tidak akan lagi ditampilkan di NutriTrack.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: _muted)),
              ),
              ElevatedButton(
                onPressed: () {
                  ctrl.disconnect();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Putus',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _heartRateColor(double? bpm) {
    if (bpm == null) return Colors.grey;
    if (bpm < 60) return Colors.blue;
    if (bpm <= 100) return _green;
    return Colors.red;
  }

  Color _spO2Color(double? spo2) {
    if (spo2 == null) return Colors.grey;
    if (spo2 >= 95) return _green;
    if (spo2 >= 90) return Colors.orange;
    return Colors.red;
  }
}
