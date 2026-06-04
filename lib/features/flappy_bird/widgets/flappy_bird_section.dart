import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soso/core/theme/app_colors.dart';

import '../view_models/flappy_view_model.dart';
import 'center_card.dart';
import 'flappy_painter.dart';

class FlappyBirdSection extends ConsumerWidget {
  const FlappyBirdSection({super.key, required this.difficulty});

  final FlappyDifficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flappyControllerProvider(difficulty));
    final controller = ref.read(flappyControllerProvider(difficulty).notifier);
    final cfg = FlappyDifficultyConfig.of(difficulty);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final r = kBirdRadius * h;
        final birdSize =
            r * 2.2; // Slightly larger to accommodate the image's bounding box
        final bx = kBirdX * w;
        final by = state.birdY * h;
        final tilt = (state.birdVel * 14).clamp(-0.6, 1.2).toDouble();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.flap,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: FlappyPainter(state)),
              ),
              Positioned(
                left: bx - birdSize / 2,
                top: by - birdSize / 2,
                width: birdSize,
                height: birdSize,
                child: Transform.rotate(
                  angle: tilt,
                  child: Image.asset(
                    'assets/images/flappy-bird.pngg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              if (state.status == FlappyStatus.playing)
                Align(
                  alignment: const Alignment(0, -0.8),
                  child: Text(
                    '${state.score}',
                    style: GoogleFonts.luckiestGuy(
                      color: Colors.white,
                      fontSize: 60,
                      shadows: const [
                        Shadow(color: AppColors.overlay, blurRadius: 16),
                      ],
                    ),
                  ),
                ),
              if (state.status == FlappyStatus.idle)
                CenterCard(
                  title: 'Tap to Fly',
                  subtitle: 'Tap anywhere to flap. How far can you go?',
                  buttonLabel: 'Start',
                  color: cfg.color,
                  onTap: controller.start,
                ),
              if (state.status == FlappyStatus.gameOver)
                CenterCard(
                  title: 'Game Over',
                  subtitle: 'Score ${state.score}   •   Best ${state.best}',
                  buttonLabel: 'Play Again',
                  color: cfg.color,
                  onTap: controller.start,
                ),
            ],
          ),
        );
      },
    );
  }
}
