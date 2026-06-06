import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutritrack_app/helpers/app_colors.dart';

class CuteLoadingWidget extends StatefulWidget {
  const CuteLoadingWidget({super.key});

  @override
  State<CuteLoadingWidget> createState() => _CuteLoadingWidgetState();
}

class _CuteLoadingWidgetState extends State<CuteLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FoodParticle> _particles;
  late Timer _messageTimer;
  int _messageIndex = 0;

  final List<String> _loadingMessages = [
    'Mengintip resep rahasia Krabby Patty...',
    'Menghitung dosa kuliner hari ini...',
    'Bertanya pada chef AI terbaik...',
    'Mendeteksi kadar kebahagiaan makanan ini...',
    'Memisahkan cinta dan kalori...',
    'Mencocokkan protein dengan cita-cita kamu...',
    'Menganalisis karbohidrat... Jangan panik ya!',
    'Membaca masa depan lingkar pinggangmu...',
    'Menerjemahkan bahasa kalori...',
    'Menyiapkan laporan gizi terbaik untukmu...',
    'Menimbang kalori makanan ini...',
  ];

  final List<String> _emojis = ['🍎', '🍌', '🥦', '🍕', '🥑', '🥕', '🍳', '🍉', '🍍', '🍩', '🍔', '🍓'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Generate random particle settings
    final rand = Random();
    _particles = List.generate(12, (index) {
      return _FoodParticle(
        emoji: _emojis[index % _emojis.length],
        startX: (rand.nextDouble() * 2.0) - 1.0, // -1.0 to 1.0
        speed: 1.0 + rand.nextDouble() * 0.8,    // speed scaling
        scale: 0.8 + rand.nextDouble() * 0.6,    // emoji scale
        delay: rand.nextDouble(),                 // time delay offset
      );
    });

    // Rotate messages every 2.2 seconds
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ─── Animation Area ───
          SizedBox(
            height: 300,
            width: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Pulsing Scan Waves
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(260, 260),
                      painter: ScanWavePainter(_controller.value),
                    );
                  },
                ),

                // 2. Floating Food Particles
                ..._particles.map((particle) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      // Normalize the timing progress based on delay
                      double progress = (_controller.value - particle.delay) % 1.0;
                      
                      // Calculate positions
                      double yOffset = -progress * 160 - 35; // Floats upward
                      double xOffset = (particle.startX * 70) + sin(progress * 4 * pi) * 15; // Sways side to side
                      
                      // Opacity fade in at start, fade out at end
                      double opacity = 0.0;
                      if (progress < 0.2) {
                        opacity = progress / 0.2;
                      } else if (progress > 0.7) {
                        opacity = (1.0 - progress) / 0.3;
                      } else {
                        opacity = 1.0;
                      }
                      opacity = opacity.clamp(0.0, 1.0);

                      return Transform.translate(
                        offset: Offset(xOffset, yOffset),
                        child: Transform.scale(
                          scale: particle.scale,
                          child: Opacity(
                            opacity: opacity,
                            child: Text(
                              particle.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

                // 3. Central Kawaii Salad Bowl (Bounces and wiggles!)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Sine waves for smooth bouncy bobbing and wiggling
                    double bounce = sin(_controller.value * 2 * pi) * 12;
                    double wiggle = sin(_controller.value * 4 * pi) * 0.06;
                    double scale = 1.0 + sin(_controller.value * 2 * pi) * 0.03;

                    return Transform.translate(
                      offset: Offset(0, bounce),
                      child: Transform.rotate(
                        angle: wiggle,
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.12),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: KawaiiBowlPainter(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // ─── Loading Text ───
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.4),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  )),
                  child: child,
                ),
              );
            },
            child: Text(
              _loadingMessages[_messageIndex],
              key: ValueKey<int>(_messageIndex),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 12),
          
          // Sub-message for extra premium style
          Text(
            'Tunggu Sebentar Ya...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodParticle {
  final String emoji;
  final double startX;
  final double speed;
  final double scale;
  final double delay;

  _FoodParticle({
    required this.emoji,
    required this.startX,
    required this.speed,
    required this.scale,
    required this.delay,
  });
}

class ScanWavePainter extends CustomPainter {
  final double progress;
  ScanWavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // Wave 1
    final wave1Radius = maxRadius * progress;
    final wave1Opacity = (1.0 - progress).clamp(0.0, 1.0);
    final wave1Paint = Paint()
      ..color = AppColors.primaryLight.withOpacity(wave1Opacity * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, wave1Radius, wave1Paint);

    // Wave 2 (offset progress by 0.5)
    final progress2 = (progress + 0.5) % 1.0;
    final wave2Radius = maxRadius * progress2;
    final wave2Opacity = (1.0 - progress2).clamp(0.0, 1.0);
    final wave2Paint = Paint()
      ..color = AppColors.primary.withOpacity(wave2Opacity * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, wave2Radius, wave2Paint);
  }

  @override
  bool shouldRepaint(covariant ScanWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class KawaiiBowlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF2E7D32) // primary brand color
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Draw the food / salad inside the bowl (some green mounds on top)
    paint.color = const Color(0xFF81C784); // light green salad
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.22, size.width * 0.7, size.height * 0.3),
      paint,
    );
    
    // Add tomato slices/bits
    paint.color = const Color(0xFFEF5350); // vibrant tomato red
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.32), 7, paint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.35), 6, paint);
    
    // Add corn bits
    paint.color = const Color(0xFFFFD54F); // yellow corn
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.28), 5, paint);
    canvas.drawCircle(Offset(size.width * 0.48, size.height * 0.36), 4, paint);

    // Draw the main bowl body
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.78, size.width * 0.3, size.height * 0.83)
      ..lineTo(size.width * 0.7, size.height * 0.83)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.78, size.width * 0.9, size.height * 0.42)
      ..close();

    // Fill bowl
    paint.color = const Color(0xFFE8F5E9); // super soft green/white bowl fill
    canvas.drawPath(path, paint);

    // Outline bowl
    canvas.drawPath(path, outlinePaint);

    // Draw bowl rim line
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.42),
      Offset(size.width * 0.92, size.height * 0.42),
      outlinePaint,
    );

    // Draw Kawaii Eyes (Happy curved arcs)
    final eyePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = const Color(0xFF1B5E20)
      ..strokeCap = StrokeCap.round;

    // Left eye (arc ^ shape)
    final leftEyePath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.52, size.width * 0.4, size.height * 0.58);
    canvas.drawPath(leftEyePath, eyePaint);

    // Right eye (arc ^ shape)
    final rightEyePath = Path()
      ..moveTo(size.width * 0.6, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.52, size.width * 0.7, size.height * 0.58);
    canvas.drawPath(rightEyePath, eyePaint);

    // Rosy Cheeks
    paint.color = const Color(0xFFFFCDD2).withOpacity(0.8); // cute pink blushing cheeks
    canvas.drawCircle(Offset(Offset(size.width * 0.24, size.height * 0.64).dx, Offset(size.width * 0.24, size.height * 0.64).dy), 8, paint);
    canvas.drawCircle(Offset(Offset(size.width * 0.76, size.height * 0.64).dx, Offset(size.width * 0.76, size.height * 0.64).dy), 8, paint);

    // Happy smiling mouth (cute curve)
    final mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF1B5E20)
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(size.width * 0.46, size.height * 0.63)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.70, size.width * 0.54, size.height * 0.63);
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
