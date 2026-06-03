import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  final bool isCircle;
  double opacity;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
    this.opacity = 1.0,
  });
}

class ConfettiShower extends StatefulWidget {
  const ConfettiShower({super.key});

  @override
  State<ConfettiShower> createState() => _ConfettiShowerState();
}

class _ConfettiShowerState extends State<ConfettiShower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Quick tick timer via AnimationController
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _ctrl.addListener(_updateParticles);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_updateParticles);
    _ctrl.dispose();
    super.dispose();
  }

  void _updateParticles() {
    if (!mounted) return;
    
    // Periodically generate new particles at the top of screen
    if (_particles.length < 150 && _random.nextDouble() < 0.4) {
      _particles.add(ConfettiParticle(
        x: _random.nextDouble() * 400, // Normalized width space
        y: -20,
        vx: _random.nextDouble() * 3.5 - 1.75, // Horizontal drift
        vy: _random.nextDouble() * 4.5 + 2.5,  // Vertical gravity fall speed
        size: _random.nextDouble() * 8 + 6,
        color: [
          const Color(0xFFFF2E93), // Vivid Pink
          const Color(0xFFFF8A00), // Energetic Orange
          const Color(0xFFFFD600), // Radiant Yellow
          const Color(0xFF00E575), // Electric Green
          const Color(0xFF00B2FE), // Cyan Accent
          const Color(0xFF9B51E0), // Purple Accent
          Colors.white,
        ][_random.nextInt(7)],
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: _random.nextDouble() * 0.16 - 0.08,
        isCircle: _random.nextBool(),
      ));
    }

    setState(() {
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.rotation += p.rotationSpeed;
        
        // Decay opacity slowly as they fall lower
        if (p.y > 450) {
          p.opacity = (p.opacity - 0.015).clamp(0.0, 1.0);
        }
      }
      
      // Remove off-screen/dead particles
      _particles.removeWhere((p) => p.y > 900 || p.opacity <= 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return IgnorePointer(
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _ConfettiPainter(
              particles: _particles,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double width;
  final double height;

  _ConfettiPainter({
    required this.particles,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Map normalized X [0..400] to actual screen width
      final actualX = (p.x / 400.0) * width;
      if (p.y > height) continue;

      canvas.save();
      canvas.translate(actualX, p.y);
      canvas.rotate(p.rotation);

      paint.color = p.color.withOpacity(p.opacity);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
