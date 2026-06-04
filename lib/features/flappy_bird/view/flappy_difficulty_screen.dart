import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soso/core/theme/app_colors.dart';
import '../view_models/flappy_view_model.dart';
import 'flappy_game_screen.dart';

class FlappyDifficultyScreen extends StatelessWidget {
  const FlappyDifficultyScreen({super.key});

  void _start(BuildContext context, FlappyDifficulty difficulty) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlappyGameScreen(difficulty: difficulty),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          'Flappy Dash',
          style: GoogleFonts.luckiestGuy(
            fontSize: 20,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _HeroBanner(),
            const SizedBox(height: 22),
            Text(
              'CHOOSE DIFFICULTY',
              style: GoogleFonts.luckiestGuy(
                fontSize: 14,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pillars start farther apart on easier modes and close in as your '
              'score climbs.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 16),
            for (final cfg in FlappyDifficultyConfig.all) ...[
              _DifficultyCard(
                config: cfg,
                onTap: () => _start(context, cfg.difficulty),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.arenaBgTop, AppColors.arenaBgBottom],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.arenaGlow.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.flutter_dash,
              color: AppColors.secondary,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take Flight',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to flap, dodge the pillars, and chase a new best score.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatefulWidget {
  const _DifficultyCard({required this.config, required this.onTap});
  final FlappyDifficultyConfig config;
  final VoidCallback onTap;

  @override
  State<_DifficultyCard> createState() => _DifficultyCardState();
}

class _DifficultyCardState extends State<_DifficultyCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cfg.color.withValues(alpha: 0.16),
                cfg.color.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cfg.color.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: cfg.color.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cfg.color,
                      Color.lerp(cfg.color, Colors.white, 0.3)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: cfg.color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(cfg.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cfg.label,
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 19,
                        color: AppColors.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cfg.tagline,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LevelMeter(level: cfg.level, color: cfg.color),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_fill_rounded,
                color: cfg.color,
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level, required this.color});
  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            width: 22,
            height: 6,
            decoration: BoxDecoration(
              color: i < level
                  ? color
                  : AppColors.onSurfaceMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ],
    );
  }
}
