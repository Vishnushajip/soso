import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/emote.dart';

class FloatingCartoonEmote extends StatefulWidget {
  const FloatingCartoonEmote({
    super.key,
    this.emote,
    this.emoji,
    this.label,
    this.senderName,
    this.onFinished,
  });

  final Emote? emote;
  final String? emoji;
  final String? label;
  final String? senderName;
  final VoidCallback? onFinished;

  @override
  State<FloatingCartoonEmote> createState() => _FloatingCartoonEmoteState();
}

class _FloatingCartoonEmoteState extends State<FloatingCartoonEmote>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..forward().then((_) {
        if (mounted && widget.onFinished != null) widget.onFinished!();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final val = _ctrl.value;
        final dy = -val * 40.0;
        final dx = math.sin(val * math.pi * 3.0) * 8.0;
        final scale = val < 0.2
            ? (val / 0.2) * 1.15
            : (1.15 - (val - 0.2) * 0.25).clamp(0.8, 1.2);
        final opacity = (1.0 - (val * 1.2)).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.arenaStone, AppColors.arenaStoneEdge],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.arenaGold,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.arenaGold.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.emote?.emoji ?? widget.emoji ?? '🎉',
                      style: const TextStyle(fontSize: 34),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.senderName != null)
                          Text(
                            widget.senderName!.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onArenaMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        Text(
                          widget.emote?.label ?? widget.label ?? '',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 14,
                            color: AppColors.arenaGold,
                            letterSpacing: 0.8,
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
      },
    );
  }
}
