import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/sos_engine.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/game_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_providers.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/player_score_card.dart';

class LocalGameBoardScreen extends ConsumerStatefulWidget {
  const LocalGameBoardScreen({super.key, required this.boardSize, required this.playerNames});
  final int boardSize;
  final List<String> playerNames;

  @override
  ConsumerState<LocalGameBoardScreen> createState() => _LocalGameBoardScreenState();
}

class _LocalGameBoardScreenState extends ConsumerState<LocalGameBoardScreen> {
  SosLetter _letter = SosLetter.s;
  bool _eraserMode = false;
  late final LocalGameConfig _config = LocalGameConfig(
    boardSize: widget.boardSize,
    playerNames: widget.playerNames,
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localGameProvider(_config));
    final notifier = ref.read(localGameProvider(_config).notifier);
    final currentColor = AppColors.playerPalette[state.currentTurn % AppColors.playerPalette.length];
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Match'),
        actions: [
          IconButton(
            tooltip: 'Restart',
            onPressed: () {
              setState(() => _eraserMode = false);
              notifier.reset();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < state.players.length; i++) ...[
                      PlayerScoreCard(
                        name: state.players[i].name,
                        score: state.players[i].score,
                        color: AppColors.playerPalette[i % AppColors.playerPalette.length],
                        isCurrentTurn: i == state.currentTurn && !state.finished,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: GameBoardWidget(
                    size: state.boardSize,
                    board: state.board,
                    highlightCells: {
                      ...sosLineCells(state.lastSosLines),
                      ...state.customHighlights,
                    },
                    disabled: state.finished,
                    onTap: (i) async {
                      if (_eraserMode) {
                        if (state.board[i].isNotEmpty && user != null) {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref.read(userRepositoryProvider).consumeTool(
                                  uid: user.uid,
                                  itemId: 'erase_cell',
                                );
                            notifier.eraseLocal(position: i);
                            setState(() => _eraserMode = false);
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      } else {
                        notifier.place(position: i, letter: _letter);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Dynamic Spells Toolbelt Row
              if (!state.finished && user != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _eraserMode ? 'SELECT OCCUPIED CELL TO ERASE' : 'CAST MAGIC SPELLS',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: _eraserMode ? AppColors.danger : AppColors.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _SpellButton(
                            label: 'Rewind',
                            icon: Icons.undo,
                            cost: 50,
                            itemId: 'undo_move',
                            count: user.inventory['undo_move'] ?? 0,
                            active: !_eraserMode,
                            onCast: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref.read(userRepositoryProvider).consumeTool(
                                      uid: user.uid,
                                      itemId: 'undo_move',
                                    );
                                notifier.undoLocal();
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
                                );
                              }
                            },
                            onBuy: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref.read(userRepositoryProvider).purchaseTool(
                                      uid: user.uid,
                                      itemId: 'undo_move',
                                      cost: 50,
                                    );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
                                );
                              }
                            },
                            currentPoints: user.totalPoints,
                          ),
                          _SpellButton(
                            label: 'Erase',
                            icon: Icons.delete_sweep,
                            cost: 100,
                            itemId: 'erase_cell',
                            count: user.inventory['erase_cell'] ?? 0,
                            active: true,
                            isSelected: _eraserMode,
                            onCast: () {
                              setState(() => _eraserMode = !_eraserMode);
                            },
                            onBuy: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref.read(userRepositoryProvider).purchaseTool(
                                      uid: user.uid,
                                      itemId: 'erase_cell',
                                      cost: 100,
                                    );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
                                );
                              }
                            },
                            currentPoints: user.totalPoints,
                          ),
                          _SpellButton(
                            label: 'Hint Vision',
                            icon: Icons.lightbulb,
                            cost: 30,
                            itemId: 'hint_vision',
                            count: user.inventory['hint_vision'] ?? 0,
                            active: !_eraserMode,
                            onCast: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref.read(userRepositoryProvider).consumeTool(
                                      uid: user.uid,
                                      itemId: 'hint_vision',
                                    );
                                notifier.showHintsLocal();
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
                                );
                              }
                            },
                            onBuy: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref.read(userRepositoryProvider).purchaseTool(
                                      uid: user.uid,
                                      itemId: 'hint_vision',
                                      cost: 30,
                                    );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
                                );
                              }
                            },
                            currentPoints: user.totalPoints,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (state.finished)
                Column(
                  children: [
                    Text(
                      state.winnerIndex == null
                          ? 'It\'s a tie!'
                          : '${state.players[state.winnerIndex!].name} wins!',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    if (state.awardedProfilePoints != null && state.awardedProfilePoints! > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+${state.awardedProfilePoints} profile points',
                          style: const TextStyle(
                            color: AppColors.onSecondaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            variant: AppButtonVariant.secondary,
                            label: 'Exit',
                            onPressed: () => context.pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Play again',
                            onPressed: () {
                              setState(() => _eraserMode = false);
                              notifier.reset();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('S', style: TextStyle(fontWeight: FontWeight.w800)),
                      selected: _letter == SosLetter.s,
                      selectedColor: AppColors.sColor.withValues(alpha: 0.3),
                      onSelected: (_) => setState(() => _letter = SosLetter.s),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('O', style: TextStyle(fontWeight: FontWeight.w800)),
                      selected: _letter == SosLetter.o,
                      selectedColor: AppColors.oColor.withValues(alpha: 0.3),
                      onSelected: (_) => setState(() => _letter = SosLetter.o),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${state.players[state.currentTurn].name}\'s turn',
                      style: TextStyle(color: currentColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpellButton extends StatelessWidget {
  const _SpellButton({
    required this.label,
    required this.icon,
    required this.cost,
    required this.itemId,
    required this.count,
    required this.active,
    this.isSelected = false,
    required this.onCast,
    required this.onBuy,
    required this.currentPoints,
  });

  final String label;
  final IconData icon;
  final int cost;
  final String itemId;
  final int count;
  final bool active;
  final bool isSelected;
  final VoidCallback onCast;
  final VoidCallback onBuy;
  final int currentPoints;

  @override
  Widget build(BuildContext context) {
    final hasSpell = count > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: !active
              ? null
              : (hasSpell
                  ? onCast
                  : (currentPoints >= cost ? onBuy : null)),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.danger.withValues(alpha: 0.15)
                  : (hasSpell
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.danger
                    : (hasSpell
                        ? AppColors.primary
                        : AppColors.onSurfaceMuted.withValues(alpha: 0.3)),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? AppColors.danger
                      : (hasSpell ? AppColors.primary : AppColors.onSurfaceMuted),
                ),
                const SizedBox(width: 4),
                Text(
                  hasSpell ? '$count' : 'Buy ($cost)',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? AppColors.danger
                        : (hasSpell ? AppColors.primary : AppColors.onSurfaceMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}
