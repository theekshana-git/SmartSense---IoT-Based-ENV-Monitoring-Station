// ============================================================
//  lib/screens/splash_screen.dart
//  SmartSense animated splash screen.
//
//  Sequence:
//   0ms  → logo icon scales up + fades in  (800ms)
//   500ms → app name + tagline slides up   (600ms)
//   1100ms → pulsing loading dots start
//   2400ms → fade-transition to HomeScreen
// ============================================================

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Logo animation
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Text animation
  late final AnimationController _textCtrl;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // ── Logo ──────────────────────────────────────────────
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    // ── Text + dots ────────────────────────────────────────
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _runSplash();
  }

  Future<void> _runSplash() async {
    // Init notifications while splash plays
    NotificationService.initialize();

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1750));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2340),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Animated logo icon ───────────────────────
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: _LogoIcon(),
              ),
            ),

            const SizedBox(height: 36),

            // ── App name, tagline, loading dots ───────────
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    // App name
                    const Text(
                      'SmartSense',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    Text(
                      'Environmental Intelligence',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 14,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 52),
                    // Pulsing dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) =>
                        _PulsingDot(delay: Duration(milliseconds: i * 200))),
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
}

// ── Hexagonal-style logo container ───────────────────────────
class _LogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF378ADD).withOpacity(0.13),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFF378ADD).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF378ADD).withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          // Icon
          const Icon(
            Icons.sensors,
            size: 54,
            color: Color(0xFF378ADD),
          ),
        ],
      ),
    );
  }
}

// ── Single pulsing loading dot ────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Duration delay;
  const _PulsingDot({required this.delay});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _opacity = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF378ADD),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
