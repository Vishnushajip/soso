import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';

class PlayerScoreCard extends StatelessWidget {
  const PlayerScoreCard({
    super.key,
    required this.name,
    required this.score,
    required this.color,
    required this.isCurrentTurn,
    this.photoUrl,
  });

  final String name;
  final int score;
  final Color color;
  final bool isCurrentTurn;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentTurn ? color.withValues(alpha: 0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentTurn ? color : AppColors.divider,
          width: isCurrentTurn ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(name: name, photoUrl: photoUrl, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  '$score pts',
                  key: ValueKey(score),
                  style: const TextStyle(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
