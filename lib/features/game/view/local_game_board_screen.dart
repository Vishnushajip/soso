import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/sos_engine.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/providers/game_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/models/emote.dart';
import '../widgets/arena_widgets.dart';
import '../widgets/board_theme_selection_sheet.dart';
import '../widgets/confetti_shower.dart';
import '../widgets/emote_wheel_sheet.dart';
import '../widgets/floating_cartoon_emote.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/vs_animation_overlay.dart';

final localLetterProvider = StateProvider.autoDispose<SosLetter>(
  (ref) => SosLetter.s,
);
final localEraserModeProvider = StateProvider.autoDispose<bool>((ref) => false);
final localShowVsAnimationProvider = StateProvider.autoDispose<bool>(
  (ref) => true,
);
final localDidTriggerWinProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final localEmoteProvider = StateProvider.autoDispose<Emote?>((ref) => null);

class LocalGameBoardScreen extends ConsumerStatefulWidget {
  const LocalGameBoardScreen({
    super.key,
    required this.boardSize,
    required this.playerNames,
    required this.magicEnabled,
  });

  final int boardSize;
  final List<String> playerNames;
  final bool magicEnabled;

  @override
  ConsumerState<LocalGameBoardScreen> createState() =>
      _LocalGameBoardScreenState();
}

class _LocalGameBoardScreenState extends ConsumerState<LocalGameBoardScreen>
    with SingleTickerProviderStateMixin {
  late final LocalGameConfig _config = LocalGameConfig(
    boardSize: widget.boardSize,
    playerNames: widget.playerNames,
  );

  late final AnimationController _winCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _winScale = CurvedAnimation(
    parent: _winCtrl,
    curve: Curves.elasticOut,
  );

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
    _winCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localGameProvider(_config));
    final notifier = ref.read(localGameProvider(_config).notifier);
    final letter = ref.watch(localLetterProvider);
    final eraserMode = ref.watch(localEraserModeProvider);
    final showVsAnimation = ref.watch(localShowVsAnimationProvider);
    final didTriggerWin = ref.watch(localDidTriggerWinProvider);
    final activeEmote = ref.watch(localEmoteProvider);

    final currentColor = AppColors
        .playerPalette[state.currentTurn % AppColors.playerPalette.length];
    final user = ref.watch(currentUserProvider).valueOrNull;

    final lineColors = state.completedSosLines.map(
      (line, playerIdx) => MapEntry(
        line,
        AppColors.playerPalette[playerIdx % AppColors.playerPalette.length],
      ),
    );
    final boardTheme = ref.watch(boardThemeProvider);

    if (state.finished && !didTriggerWin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(localDidTriggerWinProvider.notifier).state = true;
        HapticFeedback.heavyImpact();
        _winCtrl.forward(from: 0);
      });
    }

    final Widget mainContent = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmationDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.arenaBgBottom,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final shouldPop = await _showExitConfirmationDialog(context);
              if (shouldPop && context.mounted) {
                context.pop();
              }
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.arenaStone,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.arenaGold.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.arenaGold,
              ),
            ),
          ),
          title: Text(
            'Local Match',
            style: GoogleFonts.luckiestGuy(
              fontSize: 20,
              color: AppColors.arenaGold,
              letterSpacing: 1.5,
            ),
          ),
          centerTitle: true,
          actions: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                BoardThemeSelectionSheet.show(context);
              },
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.arenaStone,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.arenaGold.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  size: 18,
                  color: AppColors.arenaGold,
                ),
              ),
            ),
            Tooltip(
              message: 'Restart Match',
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  // If game is in progress (moves made, not yet finished), confirm first.
                  final boardHasMoves = state.board.any(
                    (cell) => cell.isNotEmpty,
                  );
                  if (boardHasMoves && !state.finished) {
                    final confirmed = await _showRestartConfirmationDialog(
                      context,
                    );
                    if (!confirmed) return;
                  }
                  ref.read(localEraserModeProvider.notifier).state = false;
                  ref.read(localDidTriggerWinProvider.notifier).state = false;
                  _winCtrl.reset();
                  notifier.reset();
                },
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.arenaStone,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.arenaGold.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColors.arenaGold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: ArenaBackground()),
            if (activeEmote != null)
              Positioned(
                top: 70,
                left: 30,
                child: FloatingCartoonEmote(emote: activeEmote),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(
                  children: [
                    _ScoreRow(state: state),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: GameBoardWidget(
                          theme: boardTheme,
                          size: state.boardSize,
                          board: state.board,
                          highlightCells: state.customHighlights.toSet(),
                          disabled: state.finished,
                          sosLines: state.completedSosLines.keys.toList(),
                          lineColors: lineColors,
                          onTap: (i) async {
                            if (eraserMode) {
                              if (state.board[i].isEmpty) return;
                              if (user != null) {
                                try {
                                  HapticFeedback.mediumImpact();
                                  await ref
                                      .read(userRepositoryProvider)
                                      .consumeTool(
                                        uid: user.uid,
                                        itemId: 'erase_cell',
                                      );
                                  notifier.eraseLocal(position: i);
                                  ref
                                          .read(
                                            localEraserModeProvider.notifier,
                                          )
                                          .state =
                                      false;
                                } catch (e) {
                                  HapticFeedback.vibrate();
                                  AppSnackBar.showError(context, e.toString());
                                }
                              }
                            } else {
                              if (state.board[i].isNotEmpty) return;
                              HapticFeedback.selectionClick();
                              notifier.place(position: i, letter: letter);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!state.finished &&
                        user != null &&
                        widget.magicEnabled) ...[
                      _SpellBar(
                        eraserMode: eraserMode,
                        undoCount: user.inventory['undo_move'] ?? 0,
                        eraseCount: user.inventory['erase_cell'] ?? 0,
                        hintCount: user.inventory['hint_vision'] ?? 0,
                        totalPoints: user.totalPoints,
                        onEraserToggle: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(localEraserModeProvider.notifier)
                              .update((v) => !v);
                        },
                        onUndo: () async {
                          try {
                            HapticFeedback.mediumImpact();
                            await ref
                                .read(userRepositoryProvider)
                                .consumeTool(
                                  uid: user.uid,
                                  itemId: 'undo_move',
                                );
                            notifier.undoLocal();
                          } catch (e) {
                            HapticFeedback.vibrate();
                            AppSnackBar.showError(context, e.toString());
                          }
                        },
                        onHint: () async {
                          try {
                            HapticFeedback.mediumImpact();
                            await ref
                                .read(userRepositoryProvider)
                                .consumeTool(
                                  uid: user.uid,
                                  itemId: 'hint_vision',
                                );
                            notifier.showHintsLocal();
                          } catch (e) {
                            HapticFeedback.vibrate();
                            AppSnackBar.showError(context, e.toString());
                          }
                        },
                        onBuyUndo: () async {
                          try {
                            await ref
                                .read(userRepositoryProvider)
                                .purchaseTool(
                                  uid: user.uid,
                                  itemId: 'undo_move',
                                  cost: 50,
                                );
                          } catch (e) {
                            HapticFeedback.vibrate();
                            AppSnackBar.showError(context, e.toString());
                          }
                        },
                        onBuyErase: () async {
                          try {
                            await ref
                                .read(userRepositoryProvider)
                                .purchaseTool(
                                  uid: user.uid,
                                  itemId: 'erase_cell',
                                  cost: 100,
                                );
                          } catch (e) {
                            HapticFeedback.vibrate();
                            AppSnackBar.showError(context, e.toString());
                          }
                        },
                        onBuyHint: () async {
                          try {
                            await ref
                                .read(userRepositoryProvider)
                                .purchaseTool(
                                  uid: user.uid,
                                  itemId: 'hint_vision',
                                  cost: 30,
                                );
                          } catch (e) {
                            HapticFeedback.vibrate();
                            AppSnackBar.showError(context, e.toString());
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (state.finished)
                      _WinnerPanel(
                        state: state,
                        winScale: _winScale,
                        onExit: () {
                          HapticFeedback.lightImpact();
                          ref.read(adServiceProvider).showInterstitialIfAllowed(
                            onDismissed: () {
                              if (context.mounted) {
                                context.pop();
                              }
                            },
                          );
                        },
                        onRestart: () {
                          HapticFeedback.heavyImpact();
                          ref.read(localEraserModeProvider.notifier).state =
                              false;
                          ref.read(localDidTriggerWinProvider.notifier).state =
                              false;
                          _winCtrl.reset();
                          notifier.reset();
                        },
                      )
                    else
                      _LetterPicker(
                        letter: letter,
                        playerName: state.players[state.currentTurn].name,
                        currentColor: currentColor,
                        onChanged: (l) {
                          HapticFeedback.selectionClick();
                          ref.read(localLetterProvider.notifier).state = l;
                        },
                        onEmoteTap: () {
                          HapticFeedback.lightImpact();
                          EmoteWheelSheet.show(
                            context,
                            onEmoteSelected: (emote) {
                              ref.read(localEmoteProvider.notifier).state =
                                  emote;
                              _soundService?.play(emote.sound);
                              Future.delayed(
                                const Duration(milliseconds: 2600),
                                () {
                                  if (mounted) {
                                    ref
                                            .read(localEmoteProvider.notifier)
                                            .state =
                                        null;
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget screen = mainContent;

    if (state.finished) {
      screen = Stack(
        children: [
          mainContent,
          const Positioned.fill(child: ConfettiShower()),
        ],
      );
    }

    if (showVsAnimation && widget.playerNames.length >= 2) {
      return Stack(
        children: [
          screen,
          Positioned.fill(
            child: VsAnimationOverlay(
              p1Name: '',
              p2Name: '',
              playerNames: widget.playerNames,
              playerColors: List.generate(
                widget.playerNames.length,
                (i) =>
                    AppColors.playerPalette[i % AppColors.playerPalette.length],
              ),
              title: 'LOCAL MATCH STARTING',
              onComplete: () {
                ref.read(localShowVsAnimationProvider.notifier).state = false;
              },
            ),
          ),
        ],
      );
    }

    return screen;
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.danger.withOpacity(0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withOpacity(0.08),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'LEAVE MATCH?',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: AppColors.danger,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you leave now, the match will be forfeited and your progress will be lost.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Continue Playing',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Exit Match',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<bool> _showRestartConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.arenaStone,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.arenaGold.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.arenaGold.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.arenaGold,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'RESTART MATCH?',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 18,
                  color: AppColors.arenaGold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All current scores and moves will be reset.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onArenaMuted,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppColors.onArenaMuted.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: AppColors.onArena,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.arenaGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Restart',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: AppColors.arenaStone,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.state});
  final dynamic state;

  @override
  Widget build(BuildContext context) {
    return BattleHeader(
      players: [
        for (var i = 0; i < state.players.length; i++)
          BattlePlayer(
            name: state.players[i].name,
            score: state.players[i].score,
          ),
      ],
      activeIndex: state.finished ? -1 : state.currentTurn,
    );
  }
}

class _LetterPicker extends StatelessWidget {
  const _LetterPicker({
    required this.letter,
    required this.playerName,
    required this.currentColor,
    required this.onChanged,
    this.onEmoteTap,
  });

  final SosLetter letter;
  final String playerName;
  final Color currentColor;
  final void Function(SosLetter) onChanged;
  final VoidCallback? onEmoteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.arenaStone,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: currentColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: currentColor.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LetterBtn(
            letter: 'S',
            selected: letter == SosLetter.s,
            color: AppColors.sColor,
            onTap: () => onChanged(SosLetter.s),
          ),
          const SizedBox(width: 10),
          _LetterBtn(
            letter: 'O',
            selected: letter == SosLetter.o,
            color: AppColors.oColor,
            onTap: () => onChanged(SosLetter.o),
          ),
          if (onEmoteTap != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEmoteTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.arenaStone,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.arenaGold.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('🎭', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
          const SizedBox(width: 14),
          Container(
            width: 1.5,
            height: 32,
            color: AppColors.onArenaMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$playerName\'s turn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 13,
                      color: currentColor,
                      letterSpacing: 0.5,
                    ),
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

class _LetterBtn extends StatelessWidget {
  const _LetterBtn({
    required this.letter,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String letter;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 48,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.35),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? color.withValues(alpha: 0.45)
                  : Colors.transparent,
              blurRadius: selected ? 12.0 : 0.0,
              offset: selected ? const Offset(0, 3) : Offset.zero,
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: GoogleFonts.luckiestGuy(
              fontSize: 20,
              color: selected ? Colors.white : color,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpellBar extends StatelessWidget {
  const _SpellBar({
    required this.eraserMode,
    required this.undoCount,
    required this.eraseCount,
    required this.hintCount,
    required this.totalPoints,
    required this.onEraserToggle,
    required this.onUndo,
    required this.onHint,
    required this.onBuyUndo,
    required this.onBuyErase,
    required this.onBuyHint,
  });

  final bool eraserMode;
  final int undoCount;
  final int eraseCount;
  final int hintCount;
  final int totalPoints;
  final VoidCallback onEraserToggle;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onBuyUndo;
  final VoidCallback onBuyErase;
  final VoidCallback onBuyHint;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.arenaStone,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: eraserMode
              ? AppColors.danger.withValues(alpha: 0.6)
              : AppColors.arenaGold.withValues(alpha: 0.35),
          width: eraserMode ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: eraserMode
                ? AppColors.danger.withValues(alpha: 0.2)
                : AppColors.arenaGold.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (eraserMode)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              if (eraserMode) const SizedBox(width: 6),
              Text(
                eraserMode ? 'Tap occupied cell to erase' : '🔮 Magic Spells',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 12,
                  color: eraserMode ? AppColors.danger : AppColors.arenaGold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SpellChip(
                emoji: '⏪',
                label: 'Rewind',
                count: undoCount,
                cost: 50,
                color: AppColors.primary,
                active: !eraserMode,
                isSelected: false,
                totalPoints: totalPoints,
                onCast: onUndo,
                onBuy: onBuyUndo,
              ),
              _SpellChip(
                emoji: '🧹',
                label: 'Erase',
                count: eraseCount,
                cost: 100,
                color: AppColors.danger,
                active: true,
                isSelected: eraserMode,
                totalPoints: totalPoints,
                onCast: onEraserToggle,
                onBuy: onBuyErase,
              ),
              _SpellChip(
                emoji: '💡',
                label: 'Hint',
                count: hintCount,
                cost: 30,
                color: AppColors.highlight,
                active: !eraserMode,
                isSelected: false,
                totalPoints: totalPoints,
                onCast: onHint,
                onBuy: onBuyHint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpellChip extends StatelessWidget {
  const _SpellChip({
    required this.emoji,
    required this.label,
    required this.count,
    required this.cost,
    required this.color,
    required this.active,
    required this.isSelected,
    required this.totalPoints,
    required this.onCast,
    required this.onBuy,
  });

  final String emoji;
  final String label;
  final int count;
  final int cost;
  final Color color;
  final bool active;
  final bool isSelected;
  final int totalPoints;
  final VoidCallback onCast;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final hasSpell = count > 0;
    final canBuy = totalPoints >= cost;
    final effectiveColor = isSelected ? AppColors.danger : color;

    return GestureDetector(
      onTap: !active
          ? null
          : hasSpell
          ? onCast
          : canBuy
          ? onBuy
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: (hasSpell || isSelected) && active
                  ? LinearGradient(
                      colors: [
                        effectiveColor,
                        effectiveColor.withOpacity(0.75),
                      ],
                    )
                  : null,
              color: (hasSpell || isSelected) && active
                  ? null
                  : effectiveColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? effectiveColor.withOpacity(
                        isSelected || hasSpell ? 0.4 : 0.3,
                      )
                    : AppColors.onArenaMuted.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: (hasSpell || isSelected) && active
                  ? [
                      BoxShadow(
                        color: effectiveColor.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 14,
                    color: active ? null : AppColors.onArenaMuted,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  hasSpell
                      ? '×$count'
                      : canBuy && active
                      ? '${cost}pt'
                      : '—',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 12,
                    color: (hasSpell || isSelected) && active
                        ? Colors.white
                        : active
                        ? effectiveColor
                        : AppColors.onArenaMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: active
                  ? AppColors.onArenaMuted
                  : AppColors.onArenaMuted.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _WinnerPanel extends StatelessWidget {
  const _WinnerPanel({
    required this.state,
    required this.winScale,
    required this.onExit,
    required this.onRestart,
  });

  final dynamic state;
  final Animation<double> winScale;
  final VoidCallback onExit;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final isTie = state.winnerIndex == null;
    final winnerName = isTie ? null : state.players[state.winnerIndex!].name;
    final winnerColor = isTie
        ? AppColors.highlight
        : AppColors.playerPalette[state.winnerIndex! %
              AppColors.playerPalette.length];

    return ScaleTransition(
      scale: winScale,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.arenaStone,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: winnerColor.withOpacity(0.40), width: 2),
          boxShadow: [
            BoxShadow(
              color: winnerColor.withOpacity(0.20),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(isTie ? '🤝' : '🏆', style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              isTie ? "It's a Tie!" : '$winnerName Wins!',
              style: GoogleFonts.luckiestGuy(
                fontSize: 22,
                color: winnerColor,
                letterSpacing: 1,
              ),
            ),
            if (state.awardedProfilePoints != null &&
                state.awardedProfilePoints! > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.highlight],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '+${state.awardedProfilePoints} profile points',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 13,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onExit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.onArenaMuted.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.onArenaMuted.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.onArena,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Exit',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 15,
                                color: AppColors.onArena,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onRestart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.sColor],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.replay_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Restart Match',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 15,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
