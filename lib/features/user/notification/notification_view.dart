import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './notification_controller.dart';
import './models/notification_setting_model.dart';
import '../../../services/notification_service.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  static const _green = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF4FAF4);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctrl = context.read<NotificationController>();

      if (ctrl.settings.isEmpty) {
        await ctrl.loadSettings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(
            color: Color(0xFF1A2E1A),
            fontWeight: FontWeight.w700,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Color(0xFF1A2E1A),
        ),

        actions: [
          IconButton(
            onPressed: () async {
              await NotificationService.instantTest();
            },
            icon: const Icon(Icons.bug_report_rounded),
          ),

          Consumer<NotificationController>(
            builder: (_, ctrl, __) {
              return IconButton(
                onPressed: () async {
                  await ctrl.resetToDefault();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reset berhasil'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.restart_alt_rounded),
              );
            },
          ),
        ],
      ),

      body: Consumer<NotificationController>(
        builder: (_, controller, __) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.settings.isEmpty) {
            return const Center(
              child: Text('Tidak ada data notifikasi'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.settings.length,
            itemBuilder: (_, index) {
              final setting = controller.settings[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _NotificationCard(
                  setting: setting,
                  controller: controller,
                  index: index,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationSettingModel setting;
  final NotificationController controller;
  final int index;

  const _NotificationCard({
    required this.setting,
    required this.controller,
    required this.index,
  });

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,

                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: _green,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setting.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2E1A),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      controller.formatTime(setting),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              Transform.scale(
                scale: 0.95,
                child: Switch(
                  value: setting.isEnabled,
                  activeColor: _green,

                  onChanged: (value) {
                    controller.toggleEnabled(index);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _InputField(
            label: 'Judul Notifikasi',
            initialValue: setting.title,
            onSave: (v) async {
              await controller.updateTitle(index, v);
            },
          ),

          const SizedBox(height: 14),

          _InputField(
            label: 'Isi Notifikasi',
            initialValue: setting.body,
            maxLines: 3,
            onSave: (v) async {
              await controller.updateBody(index, v);
            },
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: controller.toTimeOfDay(setting),
                );

                if (picked != null) {
                  await controller.updateTime(index, picked);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${setting.label} diubah ke '
                          '${picked.hour.toString().padLeft(2, '0')}:'
                          '${picked.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    );
                  }
                }
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,

                padding: const EdgeInsets.symmetric(vertical: 14),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              icon: const Icon(Icons.schedule_rounded),

              label: const Text(
                'Atur Waktu',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatefulWidget {
  final String label;
  final String initialValue;
  final int maxLines;
  final Future<void> Function(String value) onSave;

  const _InputField({
    required this.label,
    required this.initialValue,
    required this.onSave,
    this.maxLines = 1,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();

    _ctrl = TextEditingController(
      text: widget.initialValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5A7A5A),
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: _ctrl,
          maxLines: widget.maxLines,

          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF4FAF4),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),

          onSubmitted: (v) async {
            await widget.onSave(v);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Berhasil disimpan'),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}