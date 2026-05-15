import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './notification_controller.dart';
import './models/notification_setting_model.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  static const _green = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF4FAF4);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationController()..loadSettings(),
      child: Scaffold(
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
          iconTheme: const IconThemeData(color: Color(0xFF1A2E1A)),
          actions: [
            Consumer<NotificationController>(
              builder: (_, controller, __) {
                return IconButton(
                  onPressed: () async {
                    await controller.resetToDefault();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Berhasil reset ke default'),
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
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: controller.settings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, index) {
                final setting = controller.settings[index];

                return _NotificationCard(
                  setting: setting,
                  controller: controller,
                  index: index,
                );
              },
            );
          },
        ),
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
                width: 46,
                height: 46,
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
                        fontSize: 15,
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
              Switch(
                value: setting.isEnabled,
                activeColor: _green,
                onChanged: (_) async {
                  await controller.toggleEnabled(index);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          _TextEditor(
            label: 'Judul Notifikasi',
            initialValue: setting.title,
            onSave: (v) async {
              await controller.updateTitle(index, v);
            },
          ),

          const SizedBox(height: 14),

          _TextEditor(
            label: 'Isi Notifikasi',
            initialValue: setting.body,
            maxLines: 3,
            onSave: (v) async {
              await controller.updateBody(index, v);
            },
          ),

          const SizedBox(height: 16),

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

class _TextEditor extends StatefulWidget {
  final String label;
  final String initialValue;
  final int maxLines;
  final Future<void> Function(String value) onSave;

  const _TextEditor({
    required this.label,
    required this.initialValue,
    required this.onSave,
    this.maxLines = 1,
  });

  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
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
          controller: _controller,
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