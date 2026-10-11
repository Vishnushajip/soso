import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/emote.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/utils/bot_engine.dart';
import '../../../core/utils/sos_engine.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/user_avatar.dart';
import '../providers/ai_game_provider.dart';
import '../widgets/arena_widgets.dart';
import '../widgets/board_theme_selection_sheet.dart';
import '../widgets/confetti_shower.dart';
import '../widgets/emote_wheel_sheet.dart';
import '../widgets/floating_cartoon_emote.dart';
import '../widgets/game_board_widget.dart';

final aiLetterProvider = StateProvider.autoDispose<SosLetter>((ref) => SosLetter.s);
final aiEraserModeProvider = StateProvider.autoDispose<bool>((ref) => false);
final aiDidTriggerWinProvider = StateProvider.autoDispose<bool>((ref) => false);
final aiLastEmoteProvider = StateProvider.autoDispose<Emote?>((ref) => null);
final aiBotEmoteProvider = StateProvider.autoDispose<Emote?>((ref) => null);

class AIGameBoardScreen extends ConsumerStatefulWidget {
  const AIGameBoardScreen({
    super.key,
    required this.boardSize,
    required this.difficulty,
    this.magicEnabled = true,
  });

  final int boardSize;
  final BotDifficulty difficulty;
  final bool magicEnabled;

  @override
  ConsumerState<AIGameBoardScreen> createState() => _AIGameBoardScreenState();
}

class _AIGameBoardScreenState extends ConsumerState<AIGameBoardScreen>
    with SingleTickerProviderStateMixin {
  late final AIGameConfig _config = AIGameConfig(
    boardSize: widget.boardSize,
    difficulty: widget.difficulty,
    magicEnabled: widget.magicEnabled,
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
  Timer? _humanEmoteClearTimer;
  Timer? _botEmoteClearTimer;

  @override
  void initState() {
    super.initState();
    _soundService = ref.read(soundServiceProvider);
    _soundService?.onGameStarted();
  }

  @override
  void dispose() {
    _humanEmoteClearTimer?.cancel();
    _botEmoteClearTimer?.cancel();
    _soundService?.onGameEnded();
    _winCtrl.dispose();
    super.dispose();
  }

  void _triggerHumanEmote(Emote emote) {
    _humanEmoteClearTimer?.cancel();
    ref.read(aiLastEmoteProvider.notifier).state = emote;
    _soundService?.play(emote.sound);
    _humanEmoteClearTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        ref.read(aiLastEmoteProvider.notifier).state = null;
      }
    });
  }

  void _triggerBotEmote(Emote emote) {
    _botEmoteClearTimer?.cancel();
    ref.read(aiBotEmoteProvider.notifier).state = emote;
    // Visual speech bubble for bot so it doesn't interrupt or clash with game move audio
    _botEmoteClearTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        ref.read(aiBotEmoteProvider.notifier).state = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiGameProvider(_config));
    final notifier = ref.read(aiGameProvider(_config).notifier);
    final letter = ref.watch(aiLetterProvider);
    final eraserMode = ref.watch(aiEraserModeProvider);
    final playerEmote = ref.watch(aiLastEmoteProvider);
    final botEmote = ref.watch(aiBotEmoteProvider);

    final user = ref.watch(currentUserProvider).valueOrNull;
    final boardTheme = ref.watch(boardThemeProvider);

    // Reactive listeners for game events (emotes & game-over)
    ref.listen<AIGameState>(aiGameProvider(_config), (previous, next) {
      if (previous == null) return;

      if (next.botScore > previous.botScore) {
        final taunts = [
          Emote.all.firstWhere((e) => e.id == 'easy', orElse: () => Emote.all.first),
          Emote.all.firstWhere((e) => e.id == 'gg', orElse: () => Emote.all.first),
          Emote.all.firstWhere((e) => e.id == 'party', orElse: () => Emote.all.first),
        ];
        taunts.shuffle();
        _triggerBotEmote(taunts.first);
      }

      if (next.playerScore > previous.playerScore) {
        final shocks = [
          Emote.all.firstWhere((e) => e.id == 'omg', orElse: () => Emote.all.first),
          Emote.all.firstWhere((e) => e.id == 'cry', orElse: () => Emote.all.first),
          Emote.all.firstWhere((e) => e.id == 'fire', orElse: () => Emote.all.first),
        ];
        shocks.shuffle();
        _triggerBotEmote(shocks.first);
      }

      if (next.finished && !previous.finished) {
        ref.read(aiDidTriggerWinProvider.notifier).state = true;
        HapticFeedback.heavyImpact();
        _winCtrl.forward(from: 0);
      }
    });

    final lineColors = state.completedSosLines.map(
      (line, playerIdx) => MapEntry(
        line,
        AppColors.playerPalette[playerIdx % AppColors.playerPalette.length],
      ),
    );

    return PopScope(
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
            'VS AI Bot',
            style: GoogleFonts.luckiestGuy(
              fontSize: 20,
              color: AppColors.arenaGold,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.palette_outlined, color: AppColors.arenaGold),
              tooltip: 'Board Theme',
              onPressed: () {
                HapticFeedback.lightImpact();
                BoardThemeSelectionSheet.show(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.arenaGold),
              tooltip: 'Restart Match',
              onPressed: () => _showRestartConfirmDialog(context, notifier),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: ArenaBackground()),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  // Score & Player Cards Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Human Player Card
                        Expanded(
                          child: _PlayerCard(
                            name: user?.name ?? 'You',
                            score: state.playerScore,
                            isTurn: state.isPlayerTurn && !state.finished,
                            avatarUrl: user?.photoUrl,
                            frameColor: user?.avatarFrameColor,
                            color: AppColors.player1,
                            emote: playerEmote,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // VS Flame Indicator
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.arenaStone,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.arenaGold.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'VS',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 16,
                                  color: AppColors.arenaGold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _DifficultyBadge(difficulty: widget.difficulty),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Bot Player Card
                        Expanded(
                          child: _BotCard(
                            score: state.botScore,
                            isTurn: !state.isPlayerTurn && !state.finished,
                            isThinking: state.isBotThinking,
                            color: AppColors.player2,
                            emote: botEmote,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Turn Status pill
                  _StatusBanner(
                    isPlayerTurn: state.isPlayerTurn,
                    isBotThinking: state.isBotThinking,
                    finished: state.finished,
                    consecutiveTurns: state.consecutiveTurns,
                  ),

                  // Game Board
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GameBoardWidget(
                          size: widget.boardSize,
                          board: state.board,
                          sosLines: state.completedSosLines.keys.toList(),
                          lineColors: lineColors,
                          lastPlacedPosition: state.lastMovePosition,
                          theme: boardTheme,
                          disabled: !state.isPlayerTurn || state.finished || state.isBotThinking,
                          onTap: (index) {
                            if (eraserMode) {
                              if (state.board[index].isNotEmpty) {
                                notifier.useEraser(index);
                                ref.read(aiEraserModeProvider.notifier).state = false;
                              }
                            } else {
                              if (state.board[index].isEmpty) {
                                notifier.makePlayerMove(index, letter);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                  // Bottom Controls Bar (Letter Picker, Spells, Emotes)
                  if (!state.finished)
                    _AIBottomBar(
                      letter: letter,
                      eraserMode: eraserMode,
                      magicEnabled: widget.magicEnabled,
                      magicSpellsLeft: state.magicSpellsLeft,
                      erasersLeft: state.erasersLeft,
                      isPlayerTurn: state.isPlayerTurn && !state.isBotThinking,
                      onLetterChanged: (l) {
                        HapticFeedback.selectionClick();
                        ref.read(aiLetterProvider.notifier).state = l;
                        ref.read(aiEraserModeProvider.notifier).state = false;
                      },
                      onMagicSpell: () {
                        if (state.magicSpellsLeft > 0 && state.isPlayerTurn) {
                          notifier.useMagicSpell();
                        } else {
                          AppSnackBar.showWarning(context, 'No Magic Spells left!');
                        }
                      },
                      onEraserToggle: () {
                        if (state.erasersLeft > 0 && state.isPlayerTurn) {
                          final current = ref.read(aiEraserModeProvider);
                          ref.read(aiEraserModeProvider.notifier).state = !current;
                          if (!current) {
                            AppSnackBar.showInfo(context, 'Tap any filled letter to erase!');
                          }
                        } else {
                          AppSnackBar.showWarning(context, 'No Erasers left!');
                        }
                      },
                      onEmoteTap: () {
                        EmoteWheelSheet.show(
                          context,
                          onEmoteSelected: _triggerHumanEmote,
                        );
                      },
                    ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Confetti on Player Win
            if (state.finished && state.playerWon) const ConfettiShower(),

            // Win / Loss / Draw Result Card Overlay
            if (state.finished)
              _GameOverOverlay(
                scale: _winScale,
                playerWon: state.playerWon,
                botWon: state.botWon,
                playerScore: state.playerScore,
                botScore: state.botScore,
                onRematch: () {
                  ref.read(aiDidTriggerWinProvider.notifier).state = false;
                  _winCtrl.reset();
                  notifier.resetGame();
                },
                onExit: () => context.pop(),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.arenaStone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.arenaGold, width: 2),
        ),
        title: Text(
          'Leave Match?',
          style: GoogleFonts.luckiestGuy(
            color: AppColors.arenaGold,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Your offline match with the Bot will be abandoned.',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Stay',
              style: GoogleFonts.luckiestGuy(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Leave',
              style: GoogleFonts.luckiestGuy(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _showRestartConfirmDialog(BuildContext context, AIGameNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.arenaStone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.arenaGold, width: 2),
        ),
        title: Text(
          'Restart Match?',
          style: GoogleFonts.luckiestGuy(
            color: AppColors.arenaGold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Reset the current board and scores against the Bot?',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.luckiestGuy(
                color: Colors.white60,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.arenaGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(aiDidTriggerWinProvider.notifier).state = false;
              _winCtrl.reset();
              notifier.resetGame();
            },
            child: Text(
              'Restart',
              style: GoogleFonts.luckiestGuy(
                color: AppColors.arenaStone,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final BotDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (difficulty) {
      case BotDifficulty.easy:
        color = const Color(0xFF4CAF50);
        label = 'EASY';
        break;
      case BotDifficulty.medium:
        color = const Color(0xFFFF9800);
        label = 'MEDIUM';
        break;
      case BotDifficulty.hard:
        color = const Color(0xFFF44336);
        label = 'HARD';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.luckiestGuy(
          fontSize: 10,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.name,
    required this.score,
    required this.isTurn,
    required this.color,
    this.avatarUrl,
    this.frameColor,
    this.emote,
  });

  final String name;
  final int score;
  final bool isTurn;
  final Color color;
  final String? avatarUrl;
  final String? frameColor;
  final Emote? emote;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isTurn ? color.withValues(alpha: 0.22) : AppColors.arenaStone,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTurn ? color : AppColors.arenaStoneEdge,
              width: isTurn ? 2.5 : 1.5,
            ),
            boxShadow: isTurn
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              UserAvatar(
                photoUrl: avatarUrl,
                name: name,
                size: 38,
                frameColor: frameColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 13,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$score PTS',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (emote != null)
          Positioned(
            top: -55,
            left: 10,
            child: FloatingCartoonEmote(emote: emote!),
          ),
      ],
    );
  }
}

class _BotCard extends StatelessWidget {
  const _BotCard({
    required this.score,
    required this.isTurn,
    required this.isThinking,
    required this.color,
    this.emote,
  });

  final int score;
  final bool isTurn;
  final bool isThinking;
  final Color color;
  final Emote? emote;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isTurn ? color.withValues(alpha: 0.22) : AppColors.arenaStone,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTurn ? color : AppColors.arenaStoneEdge,
              width: isTurn ? 2.5 : 1.5,
            ),
            boxShadow: isTurn
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SOS BOT',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 13,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$score PTS',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Center(
                  child: Text(
                    isThinking ? '🧠' : '🤖',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (emote != null)
          Positioned(
            top: -55,
            right: 10,
            child: FloatingCartoonEmote(emote: emote!),
          ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.isPlayerTurn,
    required this.isBotThinking,
    required this.finished,
    required this.consecutiveTurns,
  });

  final bool isPlayerTurn;
  final bool isBotThinking;
  final bool finished;
  final int consecutiveTurns;

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return const SizedBox(height: 28);
    }

    String label;
    Color color;
    IconData icon;

    if (isBotThinking) {
      label = 'Bot is calculating move...';
      color = AppColors.player2;
      icon = Icons.psychology_rounded;
    } else if (isPlayerTurn) {
      if (consecutiveTurns > 0) {
        label = 'SOS Created! BONUS TURN!';
        color = AppColors.arenaGold;
        icon = Icons.bolt_rounded;
      } else {
        label = 'Your Turn! Pick a cell';
        color = AppColors.player1;
        icon = Icons.touch_app_rounded;
      }
    } else {
      label = 'Bot\'s Turn';
      color = AppColors.player2;
      icon = Icons.smart_toy_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.luckiestGuy(
              fontSize: 13,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIBottomBar extends StatelessWidget {
  const _AIBottomBar({
    required this.letter,
    required this.eraserMode,
    required this.magicEnabled,
    required this.magicSpellsLeft,
    required this.erasersLeft,
    required this.isPlayerTurn,
    required this.onLetterChanged,
    required this.onMagicSpell,
    required this.onEraserToggle,
    required this.onEmoteTap,
  });

  final SosLetter letter;
  final bool eraserMode;
  final bool magicEnabled;
  final int magicSpellsLeft;
  final int erasersLeft;
  final bool isPlayerTurn;
  final void Function(SosLetter) onLetterChanged;
  final VoidCallback onMagicSpell;
  final VoidCallback onEraserToggle;
  final VoidCallback onEmoteTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // S / O Picker
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.arenaStone,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.arenaGold.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LetterSelectBtn(
                  label: 'S',
                  selected: letter == SosLetter.s && !eraserMode,
                  onTap: () => onLetterChanged(SosLetter.s),
                ),
                const SizedBox(width: 6),
                _LetterSelectBtn(
                  label: 'O',
                  selected: letter == SosLetter.o && !eraserMode,
                  onTap: () => onLetterChanged(SosLetter.o),
                ),
              ],
            ),
          ),

          // Magic Spells & Eraser (if enabled)
          if (magicEnabled)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SpellBtn(
                  icon: Icons.auto_fix_high_rounded,
                  label: 'Spell',
                  count: magicSpellsLeft,
                  active: false,
                  color: const Color(0xFF9C27B0),
                  onTap: onMagicSpell,
                ),
                const SizedBox(width: 8),
                _SpellBtn(
                  icon: Icons.cleaning_services_rounded,
                  label: 'Eraser',
                  count: erasersLeft,
                  active: eraserMode,
                  color: const Color(0xFFFF5722),
                  onTap: onEraserToggle,
                ),
              ],
            ),

          // Emote Wheel Trigger
          GestureDetector(
            onTap: onEmoteTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.arenaGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.arenaGold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.arenaGold.withValues(alpha: 0.25),
                    blurRadius: 8,
                  )
                ],
              ),
              child: const Text('🎭', style: TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterSelectBtn extends StatelessWidget {
  const _LetterSelectBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.arenaGold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.arenaGold.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.luckiestGuy(
              fontSize: 22,
              color: selected ? AppColors.arenaStone : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpellBtn extends StatelessWidget {
  const _SpellBtn({
    required this.icon,
    required this.label,
    required this.count,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : AppColors.arenaStone,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? Colors.white : color.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: GoogleFonts.luckiestGuy(
                fontSize: 13,
                color: active ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.scale,
    required this.playerWon,
    required this.botWon,
    required this.playerScore,
    required this.botScore,
    required this.onRematch,
    required this.onExit,
  });

  final Animation<double> scale;
  final bool playerWon;
  final bool botWon;
  final int playerScore;
  final int botScore;
  final VoidCallback onRematch;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final String title = playerWon ? 'VICTORY!' : (botWon ? 'DEFEAT!' : 'DRAW MATCH!');
    final Color titleColor = playerWon
        ? AppColors.arenaGold
        : (botWon ? AppColors.danger : AppColors.arenaBlue);
    final String subtitle = playerWon
        ? 'You outsmarted the AI Bot!'
        : (botWon ? 'The AI Bot claimed the arena this time.' : 'Equal wits! Both scored same points.');

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        alignment: Alignment.center,
        child: ScaleTransition(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.arenaStone,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: titleColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: titleColor.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playerWon ? '🏆' : (botWon ? '💥' : '🤝'),
                  style: const TextStyle(fontSize: 54),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 32,
                    color: titleColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.arenaBgBottom,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'YOU',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 12,
                              color: AppColors.player1,
                            ),
                          ),
                          Text(
                            '$playerScore',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 26,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        ':',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 26,
                          color: Colors.white30,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            'AI BOT',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 12,
                              color: AppColors.player2,
                            ),
                          ),
                          Text(
                            '$botScore',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 26,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Exit',
                        variant: AppButtonVariant.secondary,
                        onPressed: onExit,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Rematch',
                        variant: AppButtonVariant.primary,
                        onPressed: onRematch,
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
  }
}
