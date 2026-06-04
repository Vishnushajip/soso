import 'dart:math' as math;
import 'package:flutter/material.dart';

class FirecrackerParticle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  Color color;

  FirecrackerParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
  });
}

class FirecrackersEffect extends StatefulWidget {
  const FirecrackersEffect({super.key});

  @override
  State<FirecrackersEffect> createState() => _FirecrackersEffectState();
}

class _FirecrackersEffectState extends State<FirecrackersEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<FirecrackerParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _ctrl.addListener(_updateParticles);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_updateParticles);
    _ctrl.dispose();
    super.dispose();
  }

  void _explode(double cx, double cy) {
    const colors = [
      Color(0xFFFF2E93),
      Color(0xFFFF8A00),
      Color(0xFFFFD600),
      Color(0xFF00E575),
      Color(0xFF00B2FE),
      Color(0xFF9B51E0),
      Colors.white,
    ];
    final color = colors[_random.nextInt(colors.length)];
    final count = _random.nextInt(30) + 40;
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = _random.nextDouble() * 6 + 2;
      _particles.add(
        FirecrackerParticle(
          x: cx,
          y: cy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          life: 1.0,
          color: color,
        ),
      );
    }
  }

  void _updateParticles() {
    if (!mounted) return;

    if (_random.nextDouble() < 0.08) {
      _explode(
        _random.nextDouble() * 300 + 50, // width range approx
        _random.nextDouble() * 400 + 100, // height range approx
      );
    }

    setState(() {
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.15; // gravity
        p.life -= 0.015;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return IgnorePointer(
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _FirecrackersPainter(
              particles: _particles,
            ),
          ),
        );
      },
    );
  }
}

class _FirecrackersPainter extends CustomPainter {
  final List<FirecrackerParticle> particles;

  _FirecrackersPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      if (p.life <= 0) continue;
      paint.color = p.color.withOpacity(p.life.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), 3.0 * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FirecrackersPainter oldDelegate) => true;
}
