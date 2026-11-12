import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/home/widgets/play_store_section.dart';
import '../../../core/providers/app_update_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/guest_google_prompt_dialog.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/sound_service.dart';
import '../../rewards/view/daily_reward_dialog.dart';
import '../widgets/ai_difficulty_sheet.dart';

class GameModeSelectScreen extends ConsumerWidget {
  const GameModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(soundServiceProvider).startBgm();
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StaggeredEntrance(delayMs: 0, offsetY: 0, child: _Header()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _DailyStreakBanner(),
                const SizedBox(height: 20),
                _StaggeredEntrance(
                  delayMs: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(
                        label: 'Same Device & AI',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.groups_outlined,
                              size: 14,
                              color: AppColors.onSurfaceMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'OFFLINE',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurfaceMuted,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _OfflineGrid(
                        onPassAndPlay: () {
                          ref
                              .read(soundServiceProvider)
                              .play(AppSound.buttonClick);
                          context.push(RouteNames.localSetup);
                        },
                        onAiBot: () {
                          ref
                              .read(soundServiceProvider)
                              .play(AppSound.buttonClick);
                          AIDifficultySheet.show(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _StaggeredEntrance(
                  delayMs: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionLabel(
                        label: 'Online',
                        trailing: _OnlineBadge(),
                      ),
                      const SizedBox(height: 14),
                      _OnlineGrid(
                        onRanked: () {
                          ref
                              .read(soundServiceProvider)
                              .play(AppSound.buttonClick);
                          context.push('${RouteNames.onlineLobby}?mode=ranked');
                        },
                        onFriendChallenge: () {
                          if (!GuestGooglePromptDialog.allowAction(
                            context,
                            ref,
                            feature: 'Friend Challenge',
                            description:
                                'Guest accounts cannot play friend matches. Sign in with Google to challenge and play with your friends!',
                          )) {
                            return;
                          }
                          ref
                              .read(soundServiceProvider)
                              .play(AppSound.buttonClick);
                          context.push('${RouteNames.onlineLobby}?mode=friend');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (kIsWeb) ...[const PlayStoreSection(source: 'home')],
                const SizedBox(height: 26),
                _StaggeredEntrance(
                  delayMs: 240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionLabel(
                        label: 'Solo & History',
                        trailing: _SoloBadge(),
                      ),
                      const SizedBox(height: 12),
                      _SoloPlayCard(
                        onTap: () => context.push(RouteNames.flappyGame),
                      ),
                      const SizedBox(height: 12),
                      _MatchHistoryCard(
                        onTap: () {
                          ref
                              .read(soundServiceProvider)
                              .play(AppSound.buttonClick);
                          context.push(RouteNames.matchHistory);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                const _StaggeredEntrance(delayMs: 320, child: _Footer()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({
    required this.delayMs,
    required this.child,
    this.offsetY = 18.0,
  });

  final int delayMs;
  final Widget child;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableMotion) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 450 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _AnimatedNeonBorderPainter extends CustomPainter {
  _AnimatedNeonBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.borderWidth,
  });

  final double progress;
  final double borderRadius;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= borderWidth || size.height <= borderWidth) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius),
    );

    final sweep = SweepGradient(
      center: Alignment.center,
      transform: GradientRotation(progress * 2 * math.pi),
      colors: const [
        AppColors.secondary,
        AppColors.arenaGold,
        AppColors.accent,
        AppColors.primaryContainer,
        AppColors.secondary,
      ],
      stops: const [0.0, 0.25, 0.55, 0.8, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = sweep.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedNeonBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CyberGridPainter extends CustomPainter {
  const _CyberGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    const spacing = 18.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroEmbersPainter extends CustomPainter {
  _HeroEmbersPainter({required this.progress});
  final double progress;

  static const _embers = [
    (0.08, 0.20, 2.8, 0, 1.1),
    (0.20, 0.75, 2.2, 1, 0.9),
    (0.35, 0.38, 3.2, 0, 1.3),
    (0.48, 0.82, 2.0, 2, 0.8),
    (0.62, 0.28, 2.6, 1, 1.0),
    (0.74, 0.68, 3.0, 0, 1.2),
    (0.86, 0.22, 2.2, 2, 0.7),
    (0.94, 0.78, 2.5, 0, 1.1),
    (0.16, 0.48, 1.8, 1, 1.4),
    (0.80, 0.12, 2.4, 0, 0.95),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [AppColors.arenaGold, AppColors.accent, Colors.white];

    final paint = Paint()..style = PaintingStyle.fill;

    for (final e in _embers) {
      final xFactor = e.$1;
      final yFactor = e.$2;
      final radius = e.$3;
      final color = colors[e.$4];
      final speed = e.$5;

      final t = (progress * speed + yFactor) % 1.0;
      final y = size.height * (1.0 - t);
      final x =
          size.width * xFactor +
          (math.sin((progress * 2 + xFactor) * 2 * math.pi) * 8.0);
      final alpha = (math.sin(t * math.pi) * 0.75).clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: alpha);

      final path = Path()
        ..moveTo(x, y - radius)
        ..lineTo(x + radius * 0.65, y)
        ..lineTo(x, y + radius)
        ..lineTo(x - radius * 0.65, y)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroEmbersPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FloatingBattleToken3D extends StatelessWidget {
  const _FloatingBattleToken3D({
    required this.letter,
    required this.baseColor,
    required this.secondaryColor,
    required this.floatProgress,
    required this.offsetPhase,
    this.size = 38.0,
  });

  final String letter;
  final Color baseColor;
  final Color secondaryColor;
  final double floatProgress;
  final double offsetPhase;
  final double size;

  @override
  Widget build(BuildContext context) {
    final phase = (floatProgress + offsetPhase) * 2 * math.pi;
    final yOffset = math.sin(phase) * 5.0;
    final rotZ = math.cos(phase) * 0.08;
    final scaleX = (math.cos(phase).abs() * 0.35 + 0.65);

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.rotate(
        angle: rotZ,
        child: Transform.scale(
          scaleX: scaleX,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.35),
                radius: 0.85,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  baseColor,
                  secondaryColor,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withValues(alpha: 0.55),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.luckiestGuy(
                  fontSize: size * 0.52,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarBeacon extends StatelessWidget {
  const _RadarBeacon({required this.pulseController});
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final scale = 1.0 + (pulseController.value * 0.7);
        final alpha = (1.0 - pulseController.value).clamp(0.0, 1.0) * 0.65;
        return SizedBox(
          width: 12,
          height: 12,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 9 * scale,
                  height: 9 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E676).withValues(alpha: alpha),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00E676),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF00E676),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroPlayCta extends StatefulWidget {
  const _HeroPlayCta({
    required this.pulseController,
    required this.disableMotion,
    required this.onTap,
  });

  final AnimationController pulseController;
  final bool disableMotion;
  final VoidCallback onTap;

  @override
  State<_HeroPlayCta> createState() => _HeroPlayCtaState();
}

class _HeroPlayCtaState extends State<_HeroPlayCta> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: widget.pulseController,
          builder: (context, child) {
            final pulseScale = widget.disableMotion
                ? 1.0
                : 1.0 +
                      (math.sin(widget.pulseController.value * 2 * math.pi) *
                          0.025);
            final userScale = _isPressed ? 0.93 : (_isHovered ? 1.05 : 1.0);
            return Transform.scale(scale: pulseScale * userScale, child: child);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFF6F00,
                  ).withValues(alpha: _isHovered ? 0.6 : 0.4),
                  blurRadius: _isHovered ? 14 : 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 3),
                Text(
                  'PLAY NOW',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 12,
                    color: Colors.white,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerStatefulWidget {
  const _Header();

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _floatController;
  late final AnimationController _shimmerController;
  late final AnimationController _pulseController;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        children: [
          Container(
            height: 195,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  blurRadius: 26,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Arena Cosmic Gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3F1973),
                          Color(0xFF1A0A36),
                          Color(0xFF280E54),
                        ],
                      ),
                    ),
                  ),

                  // Layer 2: Animated Breathing Neon Glow Orbs
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final val = disableMotion ? 0.5 : _pulseController.value;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            left: -35 + (val * 10),
                            top: -30 + (val * 8),
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary.withValues(
                                  alpha: 0.18 + (val * 0.08),
                                ),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 42,
                                  sigmaY: 42,
                                ),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -25 - (val * 8),
                            bottom: -25 + (val * 10),
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent.withValues(
                                  alpha: 0.20 + ((1.0 - val) * 0.08),
                                ),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 45,
                                  sigmaY: 45,
                                ),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Layer 3: Cyber Grid
                  const Opacity(
                    opacity: 0.12,
                    child: CustomPaint(painter: _CyberGridPainter()),
                  ),

                  // Layer 4: Floating Embers & Particle Stardust
                  if (!disableMotion)
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, _) => CustomPaint(
                          painter: _HeroEmbersPainter(
                            progress: _particleController.value,
                          ),
                        ),
                      ),
                    ),

                  // Layer 5: 3D Floating Battle Tokens & Badges
                  Positioned(
                    left: 8,
                    top: 10,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, _) => _FloatingBattleToken3D(
                        letter: 'S',
                        baseColor: AppColors.accent,
                        secondaryColor: const Color(0xFF1E40AF),
                        floatProgress: _floatController.value,
                        offsetPhase: 0.0,
                        size: 34,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 10,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, _) => _FloatingBattleToken3D(
                        letter: 'O',
                        baseColor: AppColors.secondary,
                        secondaryColor: const Color(0xFFC2410C),
                        floatProgress: _floatController.value,
                        offsetPhase: 0.5,
                        size: 34,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 12,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, _) {
                        final y =
                            math.sin(
                              (_floatController.value + 0.3) * 2 * math.pi,
                            ) *
                            3.5;
                        return Transform.translate(
                          offset: Offset(0, y),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.arenaGold.withValues(
                                alpha: 0.20,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.arenaGold.withValues(
                                  alpha: 0.45,
                                ),
                                width: 1.0,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.military_tech_rounded,
                                size: 14,
                                color: AppColors.arenaGold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Layer 6: Central COMPETE & WIN Content
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 3D Emblem with rotating halo
                          AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              final y = disableMotion
                                  ? 0.0
                                  : math.sin(
                                          _floatController.value * 2 * math.pi,
                                        ) *
                                        3.0;
                              return Transform.translate(
                                offset: Offset(0, y),
                                child: child,
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (!disableMotion)
                                  AnimatedBuilder(
                                    animation: _spinController,
                                    builder: (context, _) => SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: CustomPaint(
                                        painter: _RadiantHaloPainter(
                                          progress: _spinController.value,
                                          color: AppColors.arenaGold,
                                        ),
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 62,
                                  height: 62,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFF8B46FF),
                                        Color(0xFF38157A),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.arenaGold.withValues(
                                        alpha: 0.65,
                                      ),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryContainer
                                            .withValues(alpha: 0.5),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/app_icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Central Showcase Column
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Radar / Status Pill Row
                                Row(
                                  children: [
                                    _RadarBeacon(
                                      pulseController: _pulseController,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'LIVE MULTIPLAYER',
                                      style: GoogleFonts.luckiestGuy(
                                        fontSize: 10,
                                        color: AppColors.arenaGold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Consumer(
                                      builder: (context, ref, _) {
                                        final count =
                                            ref
                                                .watch(onlineCountProvider)
                                                .valueOrNull ??
                                            0;
                                        if (count <= 0)
                                          return const SizedBox.shrink();
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.20,
                                              ),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.bolt_rounded,
                                                size: 11,
                                                color: AppColors.arenaGold,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '$count LIVE',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                // COMPETE & WIN with text shimmer sweep
                                AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    if (disableMotion) return child!;
                                    final val = _shimmerController.value;
                                    return ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (bounds) {
                                        if (bounds.isEmpty) {
                                          return const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD54F),
                                              Color(0xFFFFB300),
                                            ],
                                          ).createShader(bounds);
                                        }
                                        return LinearGradient(
                                          begin: Alignment(
                                            -1.8 + (val * 3.6),
                                            -0.6,
                                          ),
                                          end: Alignment(
                                            -0.8 + (val * 3.6),
                                            0.6,
                                          ),
                                          colors: const [
                                            Color(0xFFFFD54F),
                                            Colors.white,
                                            Color(0xFFFFB300),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ).createShader(bounds);
                                      },
                                      child: child,
                                    );
                                  },
                                  child: Text(
                                    'COMPETE & WIN',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.luckiestGuy(
                                      fontSize: 21,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.7,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                        Shadow(
                                          color: AppColors.secondary.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Battle worldwide · Climb the ranks',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Interactive PLAY NOW CTA Button
                                _HeroPlayCta(
                                  pulseController: _pulseController,
                                  disableMotion: disableMotion,
                                  onTap: () {
                                    ref
                                        .read(soundServiceProvider)
                                        .play(AppSound.buttonClick);
                                    ref
                                        .read(hapticServiceProvider)
                                        .fire(HapticEvent.tap);
                                    context.push(
                                      '${RouteNames.onlineLobby}?mode=ranked',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Layer 7: Animated Rotating Neon Cyber-Border
                  if (!disableMotion)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _spinController,
                          builder: (context, _) => CustomPaint(
                            painter: _AnimatedNeonBorderPainter(
                              progress: _spinController.value,
                              borderRadius: 24,
                              borderWidth: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.luckiestGuy(
            fontSize: 13,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _OnlineBadge extends ConsumerStatefulWidget {
  const _OnlineBadge();

  @override
  ConsumerState<_OnlineBadge> createState() => _OnlineBadgeState();
}

class _OnlineBadgeState extends ConsumerState<_OnlineBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onlineCountAsync = ref.watch(onlineCountProvider);
    final count = onlineCountAsync.valueOrNull ?? 0;
    final countText = count > 0 ? '$count Online' : 'Online';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _anim,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            countText,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoloBadge extends StatelessWidget {
  const _SoloBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sports_esports_rounded,
            size: 13,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 5),
          Text(
            'NO WIFI NEEDED',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeSkyBackgroundPainter extends CustomPainter {
  _ArcadeSkyBackgroundPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.08)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const dashes = [
      (0.15, 0.22, 38.0, 1.0),
      (0.65, 0.38, 52.0, 0.8),
      (0.35, 0.65, 42.0, 1.2),
      (0.85, 0.78, 36.0, 0.9),
      (0.08, 0.88, 48.0, 1.1),
    ];

    for (final d in dashes) {
      final baseY = size.height * d.$2;
      final len = d.$3;
      final speed = d.$4;

      final t = (progress * speed + d.$1) % 1.0;
      final x = size.width * (1.0 - t);

      canvas.drawLine(Offset(x, baseY), Offset(x + len, baseY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcadeSkyBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SoloPlayCard extends StatefulWidget {
  const _SoloPlayCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SoloPlayCard> createState() => _SoloPlayCardState();
}

class _SoloPlayCardState extends State<_SoloPlayCard>
    with TickerProviderStateMixin {
  late final AnimationController _flightController;
  late final Animation<double> _bobAnimation;
  late final Animation<double> _tiltAnimation;

  late final AnimationController _skyController;
  late final AnimationController _playPulseController;
  late final Animation<double> _playPulseAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    // Flight bobbing & pitch
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: -4.5, end: 4.5).animate(
      CurvedAnimation(parent: _flightController, curve: Curves.easeInOut),
    );

    _tiltAnimation = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(parent: _flightController, curve: Curves.easeInOut),
    );

    // Drifting background dashes
    _skyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Inviting play button pulse
    _playPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _playPulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _playPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flightController.dispose();
    _skyController.dispose();
    _playPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondary.withValues(
                    alpha: _isHovered ? 0.18 : 0.14,
                  ),
                  AppColors.tertiary.withValues(
                    alpha: _isHovered ? 0.14 : 0.10,
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? AppColors.secondary.withValues(alpha: 0.65)
                    : AppColors.secondary.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(
                    alpha: _isHovered ? 0.18 : 0.10,
                  ),
                  blurRadius: _isHovered ? 18 : 14,
                  offset: Offset(0, _isHovered ? 8 : 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Arcade drifting cloud/speed dashes
                if (!disableMotion)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _skyController,
                        builder: (context, _) => CustomPaint(
                          painter: _ArcadeSkyBackgroundPainter(
                            progress: _skyController.value,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Card content
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _flightController,
                      builder: (context, child) {
                        final y = disableMotion ? 0.0 : _bobAnimation.value;
                        final angle = disableMotion
                            ? 0.0
                            : _tiltAnimation.value;
                        return Transform.translate(
                          offset: Offset(0, y),
                          child: Transform.rotate(angle: angle, child: child),
                        );
                      },
                      child: Container(
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/flappy-bird.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Flappy Dash',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 18,
                                  color: AppColors.onSurface,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.30,
                                    ),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  'SOLO',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.secondary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No one around to challenge right now? Take flight on '
                            'your own and beat your best score!',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceMuted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: _playPulseController,
                      builder: (context, child) {
                        final scale = disableMotion
                            ? (_isHovered ? 1.08 : 1.0)
                            : (_playPulseAnimation.value *
                                  (_isHovered ? 1.06 : 1.0));
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(
                                alpha: _isHovered ? 0.45 : 0.25,
                              ),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppColors.secondary,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineGrid extends StatelessWidget {
  const _OfflineGrid({required this.onPassAndPlay, required this.onAiBot});

  final VoidCallback onPassAndPlay;
  final VoidCallback onAiBot;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _AnimatedGridCard(
            imageUrl: 'https://cdn-icons-png.flaticon.com/512/808/808439.png',
            fallbackIcon: Icons.sports_esports_rounded,
            title: 'Pass & Play',
            sub: 'Up to 4 players on one screen',
            badgeLabel: 'LOCAL',
            bgColor: const Color(0xFFF5F3FF),
            borderColor: const Color(0xFFEDE9FE),
            accent: AppColors.player3,
            onTap: onPassAndPlay,
            floatDuration: const Duration(milliseconds: 2400),
            hasHalo: true,
            actionLabel: 'PLAY',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _AnimatedGridCard(
            imageUrl: 'https://cdn-icons-png.flaticon.com/512/4712/4712035.png',
            fallbackIcon: Icons.smart_toy_rounded,
            title: 'VS AI Bot',
            sub: 'Easy • Medium • Hard AI',
            badgeLabel: 'OFFLINE',
            bgColor: const Color(0xFFF0FDFA),
            borderColor: const Color(0xFFCCFBF1),
            accent: AppColors.tertiary,
            onTap: onAiBot,
            floatDuration: const Duration(milliseconds: 2700),
            hasHalo: true,
            actionLabel: 'PRACTICE',
          ),
        ),
      ],
    );
  }
}

class _OnlineGrid extends StatelessWidget {
  const _OnlineGrid({required this.onRanked, required this.onFriendChallenge});
  final VoidCallback onRanked;
  final VoidCallback onFriendChallenge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _AnimatedGridCard(
            imagePath: 'assets/icons/ranked_match.png',
            fallbackIcon: Icons.emoji_events_rounded,
            title: 'Ranked Match',
            sub: 'Climb the global leaderboard',
            badgeLabel: 'RANKED',
            bgColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFFE5D0),
            accent: AppColors.secondary,
            onTap: onRanked,
            floatDuration: const Duration(milliseconds: 2500),
            hasHalo: true,
            actionLabel: 'PLAY',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _AnimatedGridCard(
            imagePath: 'assets/icons/friend_challenge.png',
            fallbackIcon: Icons.people_alt_rounded,
            title: 'Friend Challenge',
            sub: 'Invite your online friends',
            badgeLabel: 'ONLINE',
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFDCF7E9),
            accent: AppColors.tertiary,
            onTap: onFriendChallenge,
            floatDuration: const Duration(milliseconds: 2600),
            hasHalo: false,
            actionLabel: 'PLAY',
          ),
        ),
      ],
    );
  }
}

class _RadiantHaloPainter extends CustomPainter {
  _RadiantHaloPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.12);

    const rayCount = 8;
    const angleStep = (2 * math.pi) / rayCount;

    for (int i = 0; i < rayCount; i++) {
      final baseAngle = i * angleStep + (progress * 2 * math.pi);
      final p1 = Offset(
        center.dx + math.cos(baseAngle - 0.14) * radius * 0.95,
        center.dy + math.sin(baseAngle - 0.14) * radius * 0.95,
      );
      final p2 = Offset(
        center.dx + math.cos(baseAngle + 0.14) * radius * 0.95,
        center.dy + math.sin(baseAngle + 0.14) * radius * 0.95,
      );

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadiantHaloPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AnimatedGridCard extends ConsumerStatefulWidget {
  const _AnimatedGridCard({
    this.imagePath,
    this.imageUrl,
    this.fallbackIcon,
    this.hasHalo = false,
    this.badgeLabel,
    this.actionLabel = 'PLAY',
    required this.title,
    required this.sub,
    required this.bgColor,
    required this.borderColor,
    required this.accent,
    required this.onTap,
    required this.floatDuration,
  });

  final String? imagePath;
  final String? imageUrl;
  final IconData? fallbackIcon;
  final bool hasHalo;
  final String? badgeLabel;
  final String actionLabel;
  final String title;
  final String sub;
  final Color bgColor;
  final Color borderColor;
  final Color accent;
  final VoidCallback onTap;
  final Duration floatDuration;

  @override
  ConsumerState<_AnimatedGridCard> createState() => _AnimatedGridCardState();
}

class _AnimatedGridCardState extends ConsumerState<_AnimatedGridCard>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _swayAnimation;

  late final AnimationController _haloController;
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  late final AnimationController _hoverController;
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();

    // Float animation
    _floatController = AnimationController(
      vsync: this,
      duration: widget.floatDuration,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _swayAnimation = Tween<double>(begin: -0.045, end: 0.045).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Radiant halo
    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();

    // Entrance animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
        );

    _entryController.forward();

    // Hover & Press interaction controllers (Zero setState!)
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _haloController.dispose();
    _entryController.dispose();
    _hoverController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _hoverController.forward(),
          onExit: (_) => _hoverController.reverse(),
          child: GestureDetector(
            onTapDown: (_) => _pressController.forward(),
            onTapUp: (_) => _pressController.reverse(),
            onTapCancel: () => _pressController.reverse(),
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: Listenable.merge([_hoverController, _pressController]),
              builder: (context, _) {
                final hoverVal = _hoverController.value;
                final pressVal = _pressController.value;
                final scale = (1.0 + (hoverVal * 0.02) - (pressVal * 0.04))
                    .clamp(0.92, 1.03);

                return Transform.scale(
                  scale: scale,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // Card container
                      Container(
                        margin: const EdgeInsets.only(top: 38),
                        width: double.infinity,
                        height: 172,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, widget.bgColor],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Color.lerp(
                              widget.borderColor,
                              widget.accent.withValues(alpha: 0.6),
                              hoverVal,
                            )!,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withValues(
                                alpha: 0.14 + (hoverVal * 0.14),
                              ),
                              blurRadius: 16 + (hoverVal * 8),
                              offset: Offset(0, 8 + (hoverVal * 4)),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Optional top badge
                            if (widget.badgeLabel != null)
                              Positioned(
                                top: 10,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.accent.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: widget.accent.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    widget.badgeLabel!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: widget.accent,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                10,
                                52,
                                10,
                                12,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: GoogleFonts.luckiestGuy(
                                      fontSize: 15,
                                      color: AppColors.onSurface,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  // Accent divider pill
                                  Container(
                                    width: 26,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: widget.accent,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        widget.sub,
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurfaceMuted,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Responsive interactive action affordance chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.accent.withValues(
                                        alpha: 0.12 + (hoverVal * 0.10),
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: widget.accent.withValues(
                                          alpha: 0.20 + (hoverVal * 0.25),
                                        ),
                                        width: 1.2,
                                      ),
                                      boxShadow: hoverVal > 0.05
                                          ? [
                                              BoxShadow(
                                                color: widget.accent.withValues(
                                                  alpha: hoverVal * 0.22,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.actionLabel,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: widget.accent,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Transform.translate(
                                          offset: Offset(hoverVal * 3.0, 0),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 12,
                                            color: widget.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dynamic contact shadow beneath floating illustration
                      Positioned(
                        top: 68,
                        child: AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, _) {
                            final val = disableMotion
                                ? 0.0
                                : _floatAnimation.value;
                            final shadowWidth = (48.0 - (val * 1.5)).clamp(
                              36.0,
                              56.0,
                            );
                            final shadowOpacity = (0.09 - (val * 0.007)).clamp(
                              0.04,
                              0.14,
                            );
                            return Container(
                              width: shadowWidth,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(
                                  alpha: shadowOpacity,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Overflowing 3D floating illustration with radiant aura/sway
                      Positioned(
                        top: 0,
                        child: AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) {
                            final y = disableMotion
                                ? -14.0
                                : (_floatAnimation.value - 14.0);
                            final sway = (!disableMotion)
                                ? _swayAnimation.value
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(0, y),
                              child: Transform.rotate(
                                angle: sway,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  widget.accent.withValues(alpha: 0.25),
                                  widget.accent.withValues(alpha: 0.0),
                                ],
                                stops: const [0.55, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              alignment: Alignment.center,
                              children: [
                                // Radiant halo
                                if (widget.hasHalo && !disableMotion)
                                  AnimatedBuilder(
                                    animation: _haloController,
                                    builder: (context, _) => CustomPaint(
                                      painter: _RadiantHaloPainter(
                                        progress: _haloController.value,
                                        color: widget.accent,
                                      ),
                                    ),
                                  ),

                                // Main Artwork / Fallback
                                Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: _buildArtwork(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(BuildContext context) {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackArtwork(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildFallbackArtwork(isLoading: true);
        },
      );
    }
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return Image.asset(
        widget.imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackArtwork(),
      );
    }
    return _buildFallbackArtwork();
  }

  Widget _buildFallbackArtwork({bool isLoading = false}) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accent.withValues(alpha: 0.28),
            widget.accent.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: widget.accent.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          widget.fallbackIcon ?? Icons.sports_esports_rounded,
          size: 38,
          color: widget.accent,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 1.5,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 10),
            Text(
              '★ UNLEASH THE GAMER WITHIN ★',
              style: GoogleFonts.luckiestGuy(
                fontSize: 10,
                color: AppColors.primary.withValues(alpha: 0.4),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 24,
              height: 1.5,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Crafted with ❤️ by The SOSO',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Consumer(
          builder: (context, ref, _) {
            final version = ref.watch(appVersionProvider);
            final v = version.isEmpty ? '' : 'v$version · ';
            return Text(
              'SOS ARENA · $v© 2026 soso',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceMuted.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DailyStreakBanner extends ConsumerWidget {
  const _DailyStreakBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final streak = user?.dailyStreak ?? 0;
    final canClaim = user?.canClaimDailyReward ?? false;

    return InkWell(
      onTap: () {
        ref.read(hapticServiceProvider).fire(HapticEvent.selection);
        DailyRewardDialog.show(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.arenaStone,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canClaim
                ? AppColors.arenaGold.withValues(alpha: 0.7)
                : AppColors.arenaStoneEdge,
            width: canClaim ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: canClaim
                  ? AppColors.arenaGold.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: canClaim ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: canClaim
                    ? AppColors.secondary.withValues(alpha: 0.22)
                    : AppColors.arenaCell,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canClaim
                      ? AppColors.arenaGold.withValues(alpha: 0.5)
                      : AppColors.arenaStoneEdge,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                canClaim ? '🎁' : '🔥',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          canClaim
                              ? 'DAILY REWARD READY!'
                              : 'DAY $streak STREAK',
                          maxLines: 2,
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 14,
                            color: canClaim
                                ? AppColors.arenaGold
                                : AppColors.onArena,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (canClaim) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.arenaPink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    canClaim
                        ? 'Tap to collect free coins & gifts!'
                        : 'Keep your streak alive • Longest: ${user?.longestStreak ?? 0}d',
                    maxLines: 2,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onArenaMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: canClaim
                    ? const LinearGradient(
                        colors: [AppColors.secondary, AppColors.arenaGold],
                      )
                    : null,
                color: canClaim ? null : AppColors.arenaCell,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canClaim
                      ? AppColors.arenaGold
                      : AppColors.arenaStoneEdge,
                  width: 1.2,
                ),
              ),
              child: Text(
                canClaim ? 'CLAIM' : 'STREAK',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 12,
                  color: canClaim
                      ? AppColors.arenaBgBottom
                      : AppColors.onArenaMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchHistoryCard extends StatelessWidget {
  const _MatchHistoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.arenaStone,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: const Text('📜', style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'MATCH HISTORY',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 16,
                            color: AppColors.onArena,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'RECORDS',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inversePrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View past matches, scores, outcomes, and head-to-head records',
                    maxLines: 3,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onArenaMuted,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '🏆 Outcomes • 👥 Opponents • 📊 Scores',
                    maxLines: 2,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.arenaGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.inversePrimary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
