import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../notification/notification_controller.dart';
import '../notification/models/notification_setting_model.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  static const _green = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF4FAF4);

  static const _mealColors = [
    Color(0xFFFF9800), // Sarapan  — oranye pagi
    Color(0xFF42A5F5), // Siang    — biru langit
    Color(0xFF7E57C2), // Malam    — ungu malam
  ];
  static const _mealBgColors = [
    Color(0xFFFFF3E0),
    Color(0xFFE3F2FD),
    Color(0xFFEDE7F6),
  ];
  static const _mealIcons = [
    Icons.wb_sunny_rounded,
    Icons.wb_cloudy_rounded,
    Icons.nightlight_round,
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationController()..loadSettings(),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Pengingat Makan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<NotificationController>(
          builder: (context, ctrl, _) {
            if (ctrl.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: _green));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _buildInfoBanner(),
                const SizedBox(height: 20),
                ...ctrl.settings.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MealCard(
                      index: e.key,
                      setting: e.value,
                      ctrl: ctrl,
                      color: _mealColors[e.key],
                      bgColor: _mealBgColors[e.key],
                      icon: _mealIcons[e.key],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<NotificationController>(
                  builder: (context, ctrl, _) => TextButton.icon(
                    onPressed: () => _confirmReset(context, ctrl),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset ke Pengaturan Awal'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: _green, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notifikasi akan muncul setiap hari sesuai jadwal.',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF2E7D32), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, NotificationController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Pengaturan?'),
        content: const Text(
            'Semua jam dan teks notifikasi akan dikembalikan ke pengaturan default.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ctrl.resetToDefault();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Pengaturan berhasil direset'),
                backgroundColor: _green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reset',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEAL CARD  →  diubah ke StatefulWidget agar ScrollController bisa hidup
// ─────────────────────────────────────────────────────────────────────────────

class _MealCard extends StatefulWidget {
  final int index;
  final NotificationSettingModel setting;
  final NotificationController ctrl;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _MealCard({
    required this.index,
    required this.setting,
    required this.ctrl,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard> {
  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          _buildHeader(context),
          if (widget.setting.isEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Divider(height: 1, color: Colors.grey.shade100),
            ),
            _buildTimeRow(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Divider(height: 1, color: Colors.grey.shade100),
            ),
            _buildTextRow(context,
                label: 'Judul', value: widget.setting.title, isTitle: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Divider(height: 1, color: Colors.grey.shade100),
            ),
            _buildTextRow(context,
                label: 'Pesan', value: widget.setting.body, isTitle: false),
            const SizedBox(height: 4),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Header (ikon + label + switch) ────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.icon, color: widget.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.setting.label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2E1A))),
                Text(
                  widget.setting.isEnabled
                      ? 'Aktif · ${widget.ctrl.formatTime(widget.setting)}'
                      : 'Nonaktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.setting.isEnabled
                        ? widget.color
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.setting.isEnabled,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              widget.ctrl.toggleEnabled(widget.index);
            },
            activeColor: widget.color,
          ),
        ],
      ),
    );
  }

  // ── Time row (tap → buka wheel picker) ────────────────────────────────────

  Widget _buildTimeRow(BuildContext context) {
    return InkWell(
      onTap: () => _showWheelTimePicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.access_time_rounded,
                  color: widget.color, size: 18),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Jam Notifikasi',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A2E1A))),
            ),
            Text(widget.ctrl.formatTime(widget.setting),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: widget.color)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Text row (edit judul / pesan) ─────────────────────────────────────────

  Widget _buildTextRow(BuildContext context,
      {required String label,
      required String value,
      required bool isTitle}) {
    return InkWell(
      onTap: () => _editText(context, isTitle: isTitle),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(
                isTitle ? Icons.title_rounded : Icons.message_rounded,
                color: widget.color,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A2E1A))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Wheel Time Picker (bottom sheet) ──────────────────────────────────────

  Future<void> _showWheelTimePicker(BuildContext context) async {
    // Nilai sementara selama user scroll — baru disimpan saat tekan Simpan
    int tempHour = widget.setting.hour;
    int tempMinute = widget.setting.minute;

    final hourCtrl =
        FixedExtentScrollController(initialItem: tempHour);
    final minCtrl =
        FixedExtentScrollController(initialItem: tempMinute);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: 340,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle bar ──
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ── Judul sheet ──
              Text(
                'Atur Jam · ${widget.setting.label}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2E1A),
                ),
              ),
              const SizedBox(height: 16),

              // ── Wheel picker jam & menit ──
              Expanded(
                child: Row(
                  children: [
                    // Jam (00–23)
                    Expanded(
                      child: _buildWheelColumn(
                        label: 'Jam',
                        controller: hourCtrl,
                        itemCount: 24,
                        itemLabel: (i) => i.toString().padLeft(2, '0'),
                        onChanged: (i) => tempHour = i,
                      ),
                    ),

                    // Pemisah titik dua
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                    ),

                    // Menit (00–59)
                    Expanded(
                      child: _buildWheelColumn(
                        label: 'Menit',
                        controller: minCtrl,
                        itemCount: 60,
                        itemLabel: (i) => i.toString().padLeft(2, '0'),
                        onChanged: (i) => tempMinute = i,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Tombol Simpan ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await widget.ctrl.updateTime(
                      widget.index,
                      TimeOfDay(hour: tempHour, minute: tempMinute),
                    );
                    HapticFeedback.lightImpact();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
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
        );
      },
    );

    // Dispose controller setelah sheet ditutup
    hourCtrl.dispose();
    minCtrl.dispose();
  }

  /// Satu kolom scroll wheel (jam ATAU menit).
  Widget _buildWheelColumn({
    required String label,
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) itemLabel,
    required void Function(int) onChanged,
  }) {
    return Column(
      children: [
        // Label kolom
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),

        // Highlight item terpilih
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Garis highlight atas & bawah item terpilih
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Divider(
                      height: 1,
                      color: widget.color.withOpacity(0.4)),
                  const SizedBox(height: 42),
                  Divider(
                      height: 1,
                      color: widget.color.withOpacity(0.4)),
                ],
              ),

              // Wheel
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 44,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) {
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    // Gunakan ValueListenableBuilder agar item aktif
                    // di-highlight secara real-time saat scroll
                    return AnimatedBuilder(
                      animation: controller,
                      builder: (_, __) {
                        final isSelected =
                            controller.hasClients &&
                                controller.selectedItem == index;
                        return Center(
                          child: Text(
                            itemLabel(index),
                            style: TextStyle(
                              fontSize: isSelected ? 22 : 15,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? widget.color
                                  : Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: itemCount,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Edit teks notifikasi (judul / pesan) ──────────────────────────────────

  void _editText(BuildContext context, {required bool isTitle}) {
    final ctrl = context.read<NotificationController>();
    final textCtrl = TextEditingController(
        text: isTitle ? widget.setting.title : widget.setting.body);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit ${isTitle ? 'Judul' : 'Pesan'} · ${widget.setting.label}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2E1A)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textCtrl,
                autofocus: true,
                maxLines: isTitle ? 1 : 3,
                maxLength: isTitle ? 60 : 120,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF1A2E1A)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF4FAF4),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: widget.color, width: 2),
                  ),
                  hintText: isTitle
                      ? 'Contoh: 🌅 Waktunya Sarapan!'
                      : 'Contoh: Jangan lupa catat makanmu hari ini!',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = textCtrl.text.trim();
                    if (text.isEmpty) return;
                    if (isTitle) {
                      await ctrl.updateTitle(widget.index, text);
                    } else {
                      await ctrl.updateBody(widget.index, text);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    HapticFeedback.lightImpact();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Simpan',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}