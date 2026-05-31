import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/sos_engine.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/game_providers.dart';
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
  late final LocalGameConfig _config = LocalGameConfig(
    boardSize: widget.boardSize,
    playerNames: widget.playerNames,
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localGameProvider(_config));
    final notifier = ref.read(localGameProvider(_config).notifier);
    final currentColor = AppColors.playerPalette[state.currentTurn % AppColors.playerPalette.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Match'),
        actions: [
          IconButton(
            tooltip: 'Restart',
            onPressed: notifier.reset,
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
                    highlightCells: sosLineCells(state.lastSosLines),
                    disabled: state.finished,
                    onTap: (i) => notifier.place(position: i, letter: _letter),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (state.finished)
                Column(
                  children: [
                    Text(
                      state.winnerIndex == null
                          ? 'It\'s a tie!'
                          : '${state.players[state.winnerIndex!].name} wins!',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
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
                            onPressed: notifier.reset,
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
