import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soso/core/theme/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/sound_service.dart';
import '../view_models/flappy_view_model.dart';
import '../widgets/flappy_bird_section.dart';

class FlappyGameScreen extends ConsumerStatefulWidget {
  const FlappyGameScreen({super.key, required this.difficulty});

  final FlappyDifficulty difficulty;

  @override
  ConsumerState<FlappyGameScreen> createState() => _FlappyGameScreenState();
}

class _FlappyGameScreenState extends ConsumerState<FlappyGameScreen> {
  SoundService? _soundService;

  @override
  void initState() {
    super.initState();
    _soundService = ref.read(soundServiceProvider);
    _soundService?.onGameStarted();
  }

  @override
  void dispose() {
    _soundService?.onGameEnded();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flappyControllerProvider(widget.difficulty));
    final cfg = FlappyDifficultyConfig.of(widget.difficulty);

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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cfg.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: cfg.color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCORE: ${state.score}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cfg.color,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'BEST: ${state.best}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cfg.color,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: FlappyBirdSection(difficulty: widget.difficulty),
    );
  }
}
