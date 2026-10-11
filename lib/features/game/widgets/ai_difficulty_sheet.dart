import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bot_engine.dart';
import '../../../core/widgets/app_button.dart';

final _selectedDifficultyProvider = StateProvider.autoDispose<BotDifficulty>((ref) => BotDifficulty.medium);
final _selectedBoardSizeProvider = StateProvider.autoDispose<int>((ref) => 8);
final _aiMagicEnabledProvider = StateProvider.autoDispose<bool>((ref) => true);

class AIDifficultySheet extends ConsumerWidget {
  const AIDifficultySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AIDifficultySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diff = ref.watch(_selectedDifficultyProvider);
    final size = ref.watch(_selectedBoardSizeProvider);
    final magic = ref.watch(_aiMagicEnabledProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.arenaStone,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.arenaGold, width: 2.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🤖', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text(
                'BATTLE AI BOT',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 22,
                  color: AppColors.arenaGold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Test your skills against our smart offline AI',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Difficulty Selector
          Text(
            'SELECT DIFFICULTY',
            style: GoogleFonts.luckiestGuy(
              fontSize: 13,
              color: AppColors.arenaGold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DiffOptionCard(
                  label: 'EASY',
                  emoji: '🟢',
                  subtitle: 'Casual fun',
                  selected: diff == BotDifficulty.easy,
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(_selectedDifficultyProvider.notifier).state = BotDifficulty.easy;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DiffOptionCard(
                  label: 'MEDIUM',
                  emoji: '🟡',
                  subtitle: 'Balanced play',
                  selected: diff == BotDifficulty.medium,
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(_selectedDifficultyProvider.notifier).state = BotDifficulty.medium;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DiffOptionCard(
                  label: 'HARD',
                  emoji: '🔴',
                  subtitle: 'Mastermind AI',
                  selected: diff == BotDifficulty.hard,
                  color: const Color(0xFFF44336),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(_selectedDifficultyProvider.notifier).state = BotDifficulty.hard;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Board Size Selector
          Text(
            'GRID SIZE',
            style: GoogleFonts.luckiestGuy(
              fontSize: 13,
              color: AppColors.arenaGold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [6, 7, 8].map((s) {
              final isSel = size == s;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(_selectedBoardSizeProvider.notifier).state = s;
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.arenaGold : AppColors.arenaBgBottom,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? AppColors.arenaGold : Colors.white12,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${s}x$s',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 16,
                        color: isSel ? AppColors.arenaStone : Colors.white70,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Magic Spells Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.arenaBgBottom,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Magic Spells & Eraser',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 14,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Allows auto-spells and cell erasers',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: magic,
                  activeThumbColor: AppColors.arenaGold,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    ref.read(_aiMagicEnabledProvider.notifier).state = val;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Launch Game Button
          AppButton(
            label: 'START MATCH ⚔️',
            onPressed: () {
              Navigator.of(context).pop();
              context.push(
                '${RouteNames.aiBoard}?size=$size&difficulty=${diff.name}&magic=$magic',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DiffOptionCard extends StatelessWidget {
  const _DiffOptionCard({
    required this.label,
    required this.emoji,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.22) : AppColors.arenaBgBottom,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.white12,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.luckiestGuy(
                fontSize: 14,
                color: selected ? color : Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
