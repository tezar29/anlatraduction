import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';

/// Ecran de demarrage de l'application Anla.
///
/// Fond sombre avec des cercles concentriques animes aux couleurs de la
/// marque (bleu marine / or), logo centre dans une carte blanche arrondie,
/// et une petite barre de chargement animee sous le logo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const navy = Color(0xFF1D3480);
  static const navyDark = Color(0xFF0B1638);
  static const navyMid = Color(0xFF2E4CA0);
  static const gold = Color(0xFFF6C028);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spiralController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  @override
  void initState() {
    super.initState();
    // Initialisation async pendant le splash — ne bloque pas le thread UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadHistory();
      state.loadThemePreference();
    });
    Timer(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      final state = context.read<AppState>();
      final destination = state.isAuthenticated
          ? const RootNav()
          : const LoginScreen();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    });
  }

  @override
  void dispose() {
    _spiralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated background spiral
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _spiralController,
              builder: (context, _) => CustomPaint(
                painter: _SpiralPainter(_spiralController.value),
              ),
            ),
          ),
          // Centered logo
          Center(
            child: Image.asset(
              'assets/anla_logo.png',
              width: 280,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

/// Petite barre de chargement indeterminee, aux couleurs de la marque.
class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const width = 96.0;
    const barWidth = 44.0;

    return SizedBox(
      width: width,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
          child: Container(
          color: SplashScreen.gold.withValues(alpha: 0.2),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final start = (width + barWidth) * t - barWidth;
              return Stack(
                children: [
                  Positioned(
                    left: start,
                    child: Container(
                      width: barWidth,
                      height: 4,
                      decoration: BoxDecoration(
                        color: SplashScreen.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dessine des cercles concentriques et deux arcs decoratifs, en rotation
/// lente, dans les couleurs de la marque Anla.
class _SpiralPainter extends CustomPainter {
  _SpiralPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 0.62;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);

    final radii = [0.18, 0.32, 0.46, 0.6, 0.78];
    for (var i = 0; i < radii.length; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = (i.isEven ? SplashScreen.gold : SplashScreen.navyMid)
            .withValues(alpha: i.isEven ? 0.32 : 0.45);
      canvas.drawCircle(center, maxRadius * radii[i], paint);
    }

    final arcPaint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = SplashScreen.navyMid.withValues(alpha: 0.5);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius * 0.9),
      -math.pi / 3,
      math.pi * 0.9,
      false,
      arcPaint1,
    );

    final arcPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = SplashScreen.gold.withValues(alpha: 0.35);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius * 0.7),
      math.pi * 0.75,
      math.pi * 0.7,
      false,
      arcPaint2,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpiralPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
