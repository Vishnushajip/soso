import 'package:flutter/material.dart';
import '../view_models/flappy_view_model.dart';

class FlappyPainter extends CustomPainter {
  FlappyPainter(this.state);
  final FlappyState state;

  // Cached Paint objects to avoid instantiating them 60-120 times per second
  static final Paint _cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
  static final Paint _paintDistant = Paint()..color = const Color(0xFF90D0A0);
  static final Paint _paintClose = Paint()..color = const Color(0xFF75C080);
  static final Paint _darkOutline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const Color(0xFF543847);

  static const _mainColor = Color(0xFF75BE2F);
  static const _highlight = Color(0xFF9DE054);

  // Cached shaders that depend on screen size
  static Size? _lastSize;
  static late Paint _skyPaint;
  static late Paint _glowPaint;

  void _updateShadersIfNeeded(Size size) {
    if (_lastSize == size) return;
    _lastSize = size;
    final w = size.width;
    final h = size.height;

    _skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF70C5CE), Color(0xFFD4F3F8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    _glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, h * 0.85, w, h * 0.15));
  }

  @override
  void paint(Canvas canvas, Size size) {
    _updateShadersIfNeeded(size);
    
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _skyPaint);

    _drawClouds(canvas, w, h);
    _drawCityscape(canvas, w, h);

    for (final p in state.pipes) {
      final px = p.x * w;
      final pw = kPipeWidth * w;
      final gapTop = (p.gapCenter - p.gap / 2) * h;
      final gapBottom = (p.gapCenter + p.gap / 2) * h;
      _pipe(canvas, Rect.fromLTRB(px, 0, px + pw, gapTop), capAtBottom: true);
      _pipe(
        canvas,
        Rect.fromLTRB(px, gapBottom, px + pw, h),
        capAtBottom: false,
      );
    }

    canvas.drawRect(Rect.fromLTWH(0, h * 0.85, w, h * 0.15), _glowPaint);
  }

  void _drawClouds(Canvas canvas, double w, double h) {
    final double offset = (state.score * 10) % w;
    for (int i = 0; i < 3; i++) {
      double cx = (i * (w / 2)) - (offset * 0.2);
      if (cx < -100) cx += w + 200;
      final double cy = h * 0.2 + (i % 2 == 0 ? 0 : 50);

      canvas.drawCircle(Offset(cx, cy), 30, _cloudPaint);
      canvas.drawCircle(Offset(cx + 35, cy - 10), 40, _cloudPaint);
      canvas.drawCircle(Offset(cx + 70, cy + 5), 30, _cloudPaint);
      canvas.drawRRect(
        RRect.fromLTRBR(cx - 10, cy + 10, cx + 80, cy + 30, const Radius.circular(10)),
        _cloudPaint,
      );
    }
  }

  void _drawCityscape(Canvas canvas, double w, double h) {
    final double offset1 = (state.score * 5) % (w * 1.5);
    final double offset2 = (state.score * 8) % w;

    for (int i = -1; i < 5; i++) {
      final double bx = (i * w * 0.3) - offset1;
      canvas.drawRect(Rect.fromLTWH(bx, h * 0.6, w * 0.25, h * 0.4), _paintDistant);
      canvas.drawRect(Rect.fromLTWH(bx + 20, h * 0.55, w * 0.15, h * 0.45), _paintDistant);
    }

    for (int i = -1; i < 5; i++) {
      final double bx = (i * w * 0.4) - offset2;
      canvas.drawRect(Rect.fromLTWH(bx, h * 0.7, w * 0.1, h * 0.3), _paintClose);
      canvas.drawRect(Rect.fromLTWH(bx + 40, h * 0.65, w * 0.2, h * 0.35), _paintClose);
    }
  }

  void _pipe(Canvas canvas, Rect body, {required bool capAtBottom}) {
    if (body.height <= 0) return;

    // Linear gradient shader is relatively fast, but creating Paint on every frame is slow.
    // However, the gradient size depends on 'body' which varies per pipe.
    // Creating Paint object inside loop is the main bottleneck. We can reuse a Paint object.
    
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [_highlight, _mainColor, _mainColor],
        stops: [0.0, 0.4, 1.0],
      ).createShader(body);

    canvas.drawRect(body, fill);
    canvas.drawRect(body, _darkOutline);

    const capH = 24.0;
    final capRect = capAtBottom
        ? Rect.fromLTRB(body.left - 6, body.bottom - capH, body.right + 6, body.bottom)
        : Rect.fromLTRB(body.left - 6, body.top, body.right + 6, body.top + capH);

    final capFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [_highlight, _mainColor, _mainColor],
        stops: [0.0, 0.4, 1.0],
      ).createShader(capRect);

    canvas.drawRect(capRect, capFill);
    canvas.drawRect(capRect, _darkOutline);
  }

  @override
  bool shouldRepaint(covariant FlappyPainter old) => true;
}
