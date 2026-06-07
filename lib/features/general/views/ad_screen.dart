import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutritrack_app/helpers/app_colors.dart';
import 'package:nutritrack_app/features/user/scan/views/widgets/kawaii_apple_painter.dart';

class AdScreen extends StatefulWidget {
  final int durationSeconds;

  const AdScreen({super.key, this.durationSeconds = 15});

  @override
  State<AdScreen> createState() => _AdScreenState();
}

class _AdScreenState extends State<AdScreen> with SingleTickerProviderStateMixin {
  late int _timeLeft;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.durationSeconds;

    // Bouncing animation for the cute apple
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -15.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_timeLeft / widget.durationSeconds);
    final isTimerFinished = _timeLeft == 0;

    return WillPopScope(
      onWillPop: () async => isTimerFinished, // Prevent back button during ad
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F0),
        body: SafeArea(
          child: Stack(
            children: [
              // ─── Header & Locked/Unlocked Close Button ───
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: isTimerFinished
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Iklan: $_timeLeft detik lagi',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5A7A5A),
                        ),
                      ),
                    ),
                    secondChild: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Center Promotion Content ───
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cute Bouncing Apple
                      AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: child,
                          );
                        },
                        child: Container(
                          width: 130,
                          height: 130,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: CustomPaint(
                            painter: KawaiiApplePainter(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Premium Branding
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.shade400, width: 1),
                        ),
                        child: Text(
                          '🌟 NUTRITRACK PREMIUM 🌟',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Bebaskan Batasan AI Anda!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Upgrade ke Premium hanya Rp 20.000 / bulan untuk menikmati:\n\n'
                        '🚀 Scan Foto Makanan Gemini Tanpa Batas\n'
                        '🔍 Cari Gizi Makanan Groq Tanpa Batas\n'
                        '✨ Bebas Iklan 100% Selamanya',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Ad Completion Progress Bar
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: 1.0 - progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isTimerFinished ? 'Kamu bisa menutup iklan sekarang!' : 'Menunggu iklan selesai...',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
