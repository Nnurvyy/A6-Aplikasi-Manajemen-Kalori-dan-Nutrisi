import 'package:flutter/material.dart';

/// Toast kustom yang slide masuk dari kanan ke kiri, lalu slide keluar kembali ke kanan.
/// Dipanggil via [SubmissionToast.show] — tidak bergantung pada ScaffoldMessenger
/// sehingga tidak ada konflik dengan AppBar atau FAB.
class SubmissionToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle_rounded,
    Color iconColor = const Color(0xFF2ECC71),
    Color bgColor = const Color(0xFF1B5E20),
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder:
          (_) => _SubmissionToastWidget(
            message: message,
            icon: icon,
            iconColor: iconColor,
            bgColor: bgColor,
            duration: duration,
            onDone: () => entry.remove(),
          ),
    );

    overlay.insert(entry);
  }
}

class _SubmissionToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Duration duration;
  final VoidCallback onDone;

  const _SubmissionToastWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_SubmissionToastWidget> createState() => _SubmissionToastWidgetState();
}

class _SubmissionToastWidgetState extends State<_SubmissionToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 280),
    );

    // Slide dari kanan (1.5, 0) → tengah (0, 0)
    _slide = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)));

    // Masuk → tunggu → keluar
    _ctrl.forward().then((_) async {
      await Future.delayed(widget.duration);
      if (mounted) {
        await _ctrl.reverse();
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Muncul di bawah — di atas FAB area, tidak mengganggu AppBar
      bottom: 80,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
