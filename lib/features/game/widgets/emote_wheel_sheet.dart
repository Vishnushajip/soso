import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/emote.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_colors.dart';

class EmoteWheelSheet extends ConsumerWidget {
  const EmoteWheelSheet({
    super.key,
    required this.onEmoteSelected,
  });

  final void Function(Emote emote) onEmoteSelected;

  static void show(
    BuildContext context, {
    required void Function(Emote emote) onEmoteSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EmoteWheelSheet(onEmoteSelected: onEmoteSelected),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.arenaStone,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppColors.arenaGold.withValues(alpha: 0.45),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.arenaGold.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle pill
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.onArenaMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎭', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'EXPRESS & TAUNT',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 18,
                    color: AppColors.arenaGold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: Emote.all.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, i) {
                final emote = Emote.all[i];
                return GestureDetector(
                  onTap: () {
                    ref.read(hapticServiceProvider).fire(HapticEvent.selection);
                    Navigator.of(context).pop();
                    onEmoteSelected(emote);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.arenaBgBottom,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.arenaStoneEdge,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          emote.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            emote.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 9,
                              color: AppColors.onArenaMuted,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
