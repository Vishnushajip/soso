import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soso/core/theme/app_colors.dart';

class CenterCard extends StatelessWidget {
  const CenterCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
        margin: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: AppColors.arenaStone.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlay.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.luckiestGuy(
                color: AppColors.arenaGold,
                fontSize: 28,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.onArenaMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, Color.lerp(color, Colors.white, 0.25)!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      buttonLabel,
                      style: GoogleFonts.luckiestGuy(
                        color: Colors.white,
                        fontSize: 17,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
