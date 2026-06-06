import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nutritrack_app/helpers/app_colors.dart';
import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'package:nutritrack_app/features/user/views/user_main_view.dart';
import './login_view.dart';
import 'package:nutritrack_app/features/admin/views/admin_main_view.dart';
import 'package:nutritrack_app/features/nutritionist/views/nutri_main_view.dart';
import 'package:nutritrack_app/features/general/submission/controllers/submission_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  // ── Logo entrance animation ──────────────────────────────────
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // ── Loading bar animation (looping) ──────────────────────────
  late AnimationController _barCtrl;
  late Animation<double> _barProgress;

  // ── Pulse glow on logo ───────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    // 1. Logo pop-in
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5)),
    );

    // 2. Loading progress bar fills over 2.5 s then navigates
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _barProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut),
    );

    // 3. Subtle pulse on the logo circle
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Kick off
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _barCtrl.forward();
    });
    _barCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _navigate();
    });
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
      return;
    }

    await context.read<SubmissionController>().init(
      role: user.role,
      userId: user.id,
    );

    if (!mounted) return;

    Widget target;
    if (user.role == 'admin') {
      target = const AdminMainView();
    } else if (user.role == 'nutritionist') {
      target = const NutriMainView();
    } else {
      target = const UserMainView();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _barCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E5C1E), // hijau tua — sisi kiri logo
              Color(0xFF3A8A2A), // transisi tengah
              Color(0xFF6DB33F), // hijau muda — sisi kanan logo
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_logoCtrl, _barCtrl, _pulseCtrl]),
            builder: (_, __) {
              return Column(
                children: [
                  const Spacer(flex: 3),

                  // ── App icon + name ──────────────────────────
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Lingkaran putih + pulse glow di belakang logo
                          Transform.scale(
                            scale: _pulseScale.value,
                            child: Container(
                              width: 148,
                              height: 148,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    blurRadius: 32,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Image.asset(
                                  'assets/icon/app_icon_no_bg.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.eco_rounded,
                                    size: 64,
                                    color: Color(0xFF2D6A2D),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          Text(
                            'NutriTrack',
                            style: GoogleFonts.poppins(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.4,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Track your Nutrition, Stay Healthy',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Loading progress bar ─────────────────────
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _barProgress.value,
                              minHeight: 5,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Memuat…',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}