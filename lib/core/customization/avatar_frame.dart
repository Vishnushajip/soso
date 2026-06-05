import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The geometric shape of a glowing avatar frame.
enum FrameShape { circle, rounded, hexagon, octagon, diamond }

/// A single purchasable ornate avatar frame.
///
/// SINGLE SOURCE OF TRUTH: the Shop renders cards from [kAvatarFrames] and
/// [UserAvatar] looks up the purchased [key] in [kAvatarFramesByKey] to paint
/// the correct frame everywhere (profile, friends, leaderboard, chat, …).
/// Keep [key] stable once shipped — it is what gets persisted in
/// `avatarFrameColor`.
///
/// [tier] controls how ornate the frame is:
///  * 0 — polished metallic band + glow
///  * 1 — adds a crown jewel at the top
///  * 2 — adds four corner jewels
///  * 3 — adds a large pendant jewel at the bottom (royal)
class AvatarFrame {
  const AvatarFrame({
    required this.key,
    required this.title,
    required this.desc,
    required this.icon,
    required this.cost,
    required this.color,
    this.shape = FrameShape.circle,
    this.gemColor = const Color(0xFF2EA8FF),
    this.tier = 0,
  });

  final String key;
  final String title;
  final String desc;
  final IconData icon;
  final int cost;

  /// Base metallic color of the band (a light→dark sheen is derived from it).
  final Color color;
  final FrameShape shape;

  /// Color of the decorative jewels (tier >= 1).
  final Color gemColor;
  final int tier;

  String get shapeLabel {
    switch (shape) {
      case FrameShape.circle:
        return 'Circle';
      case FrameShape.rounded:
        return 'Square';
      case FrameShape.hexagon:
        return 'Hexagon';
      case FrameShape.octagon:
        return 'Octagon';
      case FrameShape.diamond:
        return 'Diamond';
    }
  }
}

/// Returns a [ShapeBorder] for the given [shape], used to CLIP the avatar
/// content so it matches the frame opening.
ShapeBorder frameShapeBorder(FrameShape shape) {
  switch (shape) {
    case FrameShape.circle:
      return const CircleBorder();
    case FrameShape.rounded:
      return RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    case FrameShape.hexagon:
      return const _PolygonBorder(sides: 6, rotation: 0);
    case FrameShape.octagon:
      return const _PolygonBorder(sides: 8, rotation: math.pi / 8);
    case FrameShape.diamond:
      return const _PolygonBorder(sides: 4, rotation: 0);
  }
}

/// A regular-polygon outlined border (hexagon, octagon, diamond) used for
/// clipping avatar content to the frame opening.
class _PolygonBorder extends OutlinedBorder {
  const _PolygonBorder({
    required this.sides,
    required this.rotation,
    super.side,
  });

  final int sides;
  final double rotation;

  Path _polygon(Rect rect, double inset) {
    final center = rect.center;
    final radius = (math.min(rect.width, rect.height) / 2) - inset;
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = rotation - math.pi / 2 + (2 * math.pi * i / sides);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _polygon(rect, side.width);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _polygon(rect, 0);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_polygon(rect, side.width / 2), side.toPaint());
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  _PolygonBorder copyWith({BorderSide? side, int? sides, double? rotation}) =>
      _PolygonBorder(
        sides: sides ?? this.sides,
        rotation: rotation ?? this.rotation,
        side: side ?? this.side,
      );

  @override
  ShapeBorder scale(double t) =>
      _PolygonBorder(sides: sides, rotation: rotation, side: side.scale(t));
}

/// How much larger the framed widget is than the avatar opening it wraps.
const double kFrameScale = 1.42;

/// Paints an ornate metallic frame (band + sheen + glow + jewels) sized to fill
/// the canvas, with the avatar opening centered. Used by both [UserAvatar] and
/// the Shop preview so they always look identical.
class AvatarFramePainter extends CustomPainter {
  AvatarFramePainter(this.frame);

  final AvatarFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final bw = shortest * 0.13; // band thickness
    final shape = frameShapeBorder(frame.shape);
    final fullRect = Offset.zero & size;
    final bandRect = fullRect.deflate(bw / 2 + shortest * 0.03);
    final bandPath = shape.getOuterPath(bandRect);

    final base = frame.color;
    final light = Color.lerp(base, Colors.white, 0.65)!;
    final dark = Color.lerp(base, Colors.black, 0.42)!;

    // 1. Outer glow.
    canvas.drawPath(
      bandPath,
      Paint()
        ..color = base.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bw * 1.1
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shortest * 0.06),
    );

    // 2. Main metallic band with a diagonal sheen.
    canvas.drawPath(
      bandPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bw
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, base, dark, base, light],
          stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
        ).createShader(bandRect),
    );

    // 3. Bright outer rim + dark inner rim → a beveled, 3D look.
    canvas.drawPath(
      shape.getOuterPath(fullRect.deflate(shortest * 0.03)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bw * 0.14
        ..color = light.withValues(alpha: 0.95),
    );
    canvas.drawPath(
      shape.getOuterPath(bandRect.deflate(bw * 0.42)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bw * 0.16
        ..color = dark.withValues(alpha: 0.85),
    );

    // 4. Jewels by tier.
    if (frame.tier >= 1) {
      _gem(canvas, Offset(size.width / 2, bandRect.top), bw * 0.78);
    }
    if (frame.tier >= 2) {
      final rx = bandRect.width / 2;
      final ry = bandRect.height / 2;
      const k = math.sqrt1_2; // sin/cos 45°
      for (final a in const [
        Offset(-k, -k),
        Offset(k, -k),
        Offset(-k, k),
        Offset(k, k),
      ]) {
        _gem(
          canvas,
          bandRect.center.translate(a.dx * rx, a.dy * ry),
          bw * 0.5,
        );
      }
    }
    if (frame.tier >= 3) {
      _gem(canvas, Offset(size.width / 2, bandRect.bottom), bw * 0.95);
    }
  }

  /// Draws a faceted diamond jewel with a metallic rim and highlight.
  void _gem(Canvas canvas, Offset center, double r) {
    final gem = frame.gemColor;
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.82, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.82, center.dy)
      ..close();

    // Soft shadow behind the jewel.
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    // Jewel body.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(gem, Colors.white, 0.7)!,
            gem,
            Color.lerp(gem, Colors.black, 0.35)!,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    // Gold rim around the jewel.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22
        ..strokeJoin = StrokeJoin.round
        ..color = Color.lerp(frame.color, Colors.white, 0.3)!,
    );
    // Sparkle highlight.
    canvas.drawCircle(
      center.translate(-r * 0.22, -r * 0.3),
      r * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(AvatarFramePainter oldDelegate) =>
      oldDelegate.frame.key != frame.key;
}

/// The full catalog of ornate frames, ordered cheap → legendary.
const List<AvatarFrame> kAvatarFrames = [
  // ── Classic Rings (circle, tier 0) ──────────────────────────────────────
  AvatarFrame(
    key: 'sky_blue',
    title: 'Sky Drift',
    desc: 'Polished sky-blue ring',
    icon: Icons.cloud_rounded,
    cost: 5000,
    color: Color(0xFF38BDF8),
    shape: FrameShape.circle,
  ),
  AvatarFrame(
    key: 'neon_blue',
    title: 'Neon Steel',
    desc: 'Electric-blue metallic ring',
    icon: Icons.blur_circular_rounded,
    cost: 6000,
    color: Color(0xFF3B82F6),
    shape: FrameShape.circle,
  ),
  AvatarFrame(
    key: 'vibrant_green',
    title: 'Emerald Ring',
    desc: 'Forest-green metallic ring',
    icon: Icons.stars_rounded,
    cost: 6000,
    color: Color(0xFF10B981),
    shape: FrameShape.circle,
  ),
  AvatarFrame(
    key: 'crimson_red',
    title: 'Crimson Steel',
    desc: 'Fierce crimson metallic ring',
    icon: Icons.local_fire_department_rounded,
    cost: 8000,
    color: Color(0xFFEF4444),
    shape: FrameShape.circle,
  ),
  AvatarFrame(
    key: 'sunset_orange',
    title: 'Sunset Bronze',
    desc: 'Warm sunset-bronze ring',
    icon: Icons.wb_sunny_rounded,
    cost: 9000,
    color: Color(0xFFFF6A00),
    shape: FrameShape.circle,
  ),

  // ── Gemmed Frames (square, tier 1 — crown jewel) ────────────────────────
  AvatarFrame(
    key: 'cyan_teal',
    title: 'Cyber Teal',
    desc: 'Teal frame with a crown jewel',
    icon: Icons.bolt_rounded,
    cost: 13000,
    color: Color(0xFF06B6D4),
    shape: FrameShape.rounded,
    gemColor: Color(0xFFE0F7FF),
    tier: 1,
  ),
  AvatarFrame(
    key: 'lime_punch',
    title: 'Lime Crown',
    desc: 'Lime frame with a crown jewel',
    icon: Icons.flash_on_rounded,
    cost: 14000,
    color: Color(0xFFA3E635),
    shape: FrameShape.rounded,
    gemColor: Color(0xFFEFFFC2),
    tier: 1,
  ),
  AvatarFrame(
    key: 'tangerine',
    title: 'Tangerine Crown',
    desc: 'Tangerine frame with a crown jewel',
    icon: Icons.emoji_food_beverage_rounded,
    cost: 16000,
    color: Color(0xFFFB923C),
    shape: FrameShape.rounded,
    gemColor: Color(0xFFFFE3B0),
    tier: 1,
  ),
  AvatarFrame(
    key: 'royal_purple',
    title: 'Royal Amethyst',
    desc: 'Purple frame with a crown jewel',
    icon: Icons.auto_awesome_rounded,
    cost: 18000,
    color: Color(0xFF8B5CF6),
    shape: FrameShape.rounded,
    gemColor: Color(0xFFE9D5FF),
    tier: 1,
  ),

  // ── Jeweled Frames (square, tier 2 — corner jewels) ─────────────────────
  AvatarFrame(
    key: 'bubblegum',
    title: 'Bubblegum Jewels',
    desc: 'Pink frame studded with jewels',
    icon: Icons.cake_rounded,
    cost: 20000,
    color: Color(0xFFF472B6),
    shape: FrameShape.rounded,
    gemColor: Color(0xFFFFFFFF),
    tier: 2,
  ),
  AvatarFrame(
    key: 'rose_quartz',
    title: 'Rose Quartz',
    desc: 'Rose frame studded with jewels',
    icon: Icons.spa_rounded,
    cost: 24000,
    color: Color(0xFFFB7185),
    shape: FrameShape.rounded,
    gemColor: Color(0xFFFFE4E6),
    tier: 2,
  ),
  AvatarFrame(
    key: 'midnight_blue',
    title: 'Midnight Sapphire',
    desc: 'Deep-blue frame with sapphires',
    icon: Icons.dark_mode_rounded,
    cost: 28000,
    color: Color(0xFF1E3A8A),
    shape: FrameShape.rounded,
    gemColor: Color(0xFF7DD3FC),
    tier: 2,
  ),

  // ── Royal Frames (square, tier 3 — full ornamentation) ──────────────────
  AvatarFrame(
    key: 'emerald_flame',
    title: 'Emerald Royal',
    desc: 'Royal emerald frame with pendant',
    icon: Icons.eco_rounded,
    cost: 30000,
    color: Color(0xFF34D399),
    shape: FrameShape.rounded,
    gemColor: Color(0xFFFFFFFF),
    tier: 3,
  ),
  AvatarFrame(
    key: 'toxic_green',
    title: 'Venom Royal',
    desc: 'Radioactive royal frame with pendant',
    icon: Icons.science_rounded,
    cost: 35000,
    color: Color(0xFF84CC16),
    shape: FrameShape.rounded,
    gemColor: Color(0xFFD9F99D),
    tier: 3,
  ),
  AvatarFrame(
    key: 'galaxy_indigo',
    title: 'Galaxy Royal',
    desc: 'Cosmic royal frame with pendant',
    icon: Icons.nights_stay_rounded,
    cost: 40000,
    color: Color(0xFF6366F1),
    shape: FrameShape.rounded,
    gemColor: Color(0xFFC7D2FE),
    tier: 3,
  ),

  // ── Legendary Gold (square, gilded with sapphires — like the reference) ──
  AvatarFrame(
    key: 'gold',
    title: 'Champion Gold',
    desc: 'Gilded frame crowned with sapphires',
    icon: Icons.workspace_premium_rounded,
    cost: 42000,
    color: Color(0xFFFFB300),
    shape: FrameShape.rounded,
    gemColor: Color(0xFF2EA8FF),
    tier: 2,
  ),
  AvatarFrame(
    key: 'molten_lava',
    title: 'Inferno Crown',
    desc: 'Gilded royal frame forged in lava',
    icon: Icons.whatshot_rounded,
    cost: 46000,
    color: Color(0xFFFFA000),
    shape: FrameShape.rounded,
    gemColor: Color(0xFFFF3D00),
    tier: 3,
  ),
  AvatarFrame(
    key: 'celestial_prism',
    title: 'Celestial Crown',
    desc: 'The ultimate gilded royal frame',
    icon: Icons.auto_awesome_motion_rounded,
    cost: 50000,
    color: Color(0xFFFFC857),
    shape: FrameShape.rounded,
    gemColor: Color(0xFF2EA8FF),
    tier: 3,
  ),
];

/// Fast lookup by persisted key (the value stored in `avatarFrameColor`).
final Map<String, AvatarFrame> kAvatarFramesByKey = {
  for (final f in kAvatarFrames) f.key: f,
};
