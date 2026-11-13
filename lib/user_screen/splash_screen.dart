import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:watch_hub/user_screen/home.dart';
import 'package:watch_hub/user_screen/user_login.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Continuous "breathing" pulse for the logo
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Rotating watch-bezel ring around the logo
  late AnimationController _rotateController;

  // Tagline fade/slide in (delayed)
  late AnimationController _taglineController;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  // Bottom loading dots
  late AnimationController _dotsController;

  static const Color kGold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _taglineFade = CurvedAnimation(parent: _taglineController, curve: Curves.easeIn);
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _taglineController, curve: Curves.easeOut));

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Logo pop-in ke baad tagline animate karo
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _taglineController.forward();
    });

    // 4 second ke baad Login page par le kar jayega
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                 const UserHomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _taglineController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF1C1C1E),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ---- Decorative faint golden glow blobs (depth) ----
            Positioned(
              top: -80,
              left: -60,
              child: _glowBlob(220),
            ),
            Positioned(
              bottom: -100,
              right: -80,
              child: _glowBlob(260),
            ),

            // ---- Faint rotating watch-dial tick marks in background ----
            AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: child,
                );
              },
              child: CustomPaint(
                size: const Size(340, 340),
                painter: _DialTicksPainter(color: kGold.withOpacity(0.08)),
              ),
            ),

            // ---- Main content ----
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- LOGO with rotating gold bezel ring + glow ---
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating dashed bezel ring
                          AnimatedBuilder(
                            animation: _rotateController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotateController.value * 2 * math.pi,
                                child: child,
                              );
                            },
                            child: CustomPaint(
                              size: const Size(260, 260),
                              painter: _BezelRingPainter(color: kGold),
                            ),
                          ),
                          // Glow + logo circle
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kGold.withOpacity(0.7),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kGold.withOpacity(0.35),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assesst/splash.gif',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF1A1A1A),
                                    child: Icon(
                                      Icons.watch_rounded,
                                      size: 110,
                                      color: kGold.withOpacity(0.9),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    // --- App Name with gold gradient shimmer ---
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFF5E6A3),
                          Color(0xFFD4AF37),
                          Color(0xFFB8960F),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'WatchHub',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Thin gold divider line
                    Container(
                      width: 60,
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kGold.withOpacity(0),
                            kGold,
                            kGold.withOpacity(0),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- Tagline (fades + slides in) ---
                    FadeTransition(
                      opacity: _taglineFade,
                      child: SlideTransition(
                        position: _taglineSlide,
                        child: Text(
                          'TIMELESS STYLE, DELIVERED',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.65),
                            letterSpacing: 3.0,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // --- Pulsing gold loading dots ---
                    AnimatedBuilder(
                      animation: _dotsController,
                      builder: (context, child) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            double t = (_dotsController.value - (i * 0.2)) % 1.0;
                            double scale = t < 0.5
                                ? 1.0 + (0.6 * (t / 0.5))
                                : 1.6 - (0.6 * ((t - 0.5) / 0.5));
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Transform.scale(
                                scale: scale.clamp(1.0, 1.6),
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kGold.withOpacity(0.85),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowBlob(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            kGold.withOpacity(0.10),
            kGold.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

// ---- Faint dial tick marks behind the logo (like a watch face) ----
class _DialTicksPainter extends CustomPainter {
  final Color color;
  _DialTicksPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (radius - 14) * math.cos(angle),
        center.dy + (radius - 14) * math.sin(angle),
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---- Rotating dashed bezel ring around the logo ----
class _BezelRingPainter extends CustomPainter {
  final Color color;
  _BezelRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashCount = 40;
    for (int i = 0; i < dashCount; i++) {
      final angle = (i * (360 / dashCount)) * math.pi / 180;
      if (i % 3 != 0) continue; // sparse dashes for elegance
      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (radius - 6) * math.cos(angle),
        center.dy + (radius - 6) * math.sin(angle),
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}