import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bot_engine.dart';
import '../../../core/utils/sos_engine.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/game_room.dart';
import '../../../models/chat_room.dart';
import '../../../models/message.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/chat_providers.dart';
import '../../../providers/game_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../routes/route_names.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/vs_animation_overlay.dart';
import '../widgets/confetti_shower.dart';
import '../widgets/circular_turn_timer.dart';

class GameBoardScreen extends ConsumerStatefulWidget {
  const GameBoardScreen({super.key, required this.roomId});
  final String roomId;

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> {
  SosLetter _letter = SosLetter.s;
  bool _summaryShown = false;
  bool _eraserMode = false;
  Set<int> _customHighlights = const {};
  bool _showVsAnimation = false;
  bool _vsAnimationDone = false;
  final Map<SosLine, Color> _completedSosColors = {};

  bool _matchRoomEnsured = false;
  ChatRoom? _matchChatRoom;
  String? _lastProcessedMsgId;
  bool _chatSheetOpen = false;
  bool _showChatToast = false;
  Message? _lastIncomingMessage;
  final List<String> _activeFloatingReactions = [];

  final List<String> _eventLogs = [];
  bool _showLogs = false;
  GameRoom? _prevRoom;

  // Fill-in AI opponent: timer that adds a bot if no human shows up, and a
  // guard so we only schedule one automatic bot move per turn.
  Timer? _botJoinTimer;
  bool _botMoveScheduled = false;

  // Cached so dispose() can clear it without touching the disposed `ref`.
  StateController<String?>? _activeChatRoomNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeChatRoomIdProvider.notifier).state =
          'match_${widget.roomId}';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _activeChatRoomNotifier = ref.read(activeChatRoomIdProvider.notifier);
  }

  @override
  void dispose() {
    _botJoinTimer?.cancel();
    // Clear the active chat room id via the cached notifier (reading `ref`
    // after disposal throws), and defer it with Future() so we don't modify a
    // provider synchronously during widget-tree teardown.
    final notifier = _activeChatRoomNotifier;
    Future(() {
      try {
        notifier?.state = null;
      } catch (_) {
        // Provider scope already gone (e.g. app shutting down) — safe to ignore.
      }
    });
    super.dispose();
  }

  /// Drives the fill-in AI: schedules a bot to join an unmatched ranked/quick
  /// room, and plays the bot's turns automatically. Only the host runs this.
  void _maybeDriveBot(GameRoom room, String? me) {
    if (me == null || room.hostId != me) return;

    if (room.status != GameRoomStatus.waiting) {
      _botJoinTimer?.cancel();
      _botJoinTimer = null;
    }

    // No human opponent yet → after a short wait, fill the room with a bot.
    final isMatchmade =
        room.type == GameRoomType.ranked || room.type == GameRoomType.quick;
    if (isMatchmade &&
        room.status == GameRoomStatus.waiting &&
        room.players.length < room.maxPlayers) {
      _botJoinTimer ??= Timer(const Duration(seconds: 8), () {
        _botJoinTimer = null;
        if (!mounted) return;
        ref.read(gameRepositoryProvider).addBotAndStart(widget.roomId);
      });
    }

    // It's a bot's turn → play it after a lifelike pause.
    if (room.status == GameRoomStatus.active &&
        room.players.isNotEmpty &&
        room.players[room.currentTurn].isBot &&
        !_botMoveScheduled) {
      _botMoveScheduled = true;
      final delay = Duration(milliseconds: 850 + math.Random().nextInt(900));
      Future.delayed(delay, () async {
        _botMoveScheduled = false;
        if (!mounted) return;
        final latest = ref.read(gameRoomProvider(widget.roomId)).valueOrNull;
        if (latest == null ||
            latest.status != GameRoomStatus.active ||
            latest.players.isEmpty ||
            !latest.players[latest.currentTurn].isBot) {
          return;
        }
        await _driveBotMove(latest);
      });
    }
  }

  Future<void> _driveBotMove(GameRoom room) async {
    final bot = room.players[room.currentTurn];
    final move = BotEngine(room.boardSize).chooseMove(room.board);
    if (move == null) return;
    try {
      final sos = await ref
          .read(gameRepositoryProvider)
          .placeLetter(
            roomId: room.id,
            playerId: bot.uid,
            position: move.position,
            letter: move.letterStr,
          );
      if (mounted) {
        ref
            .read(soundServiceProvider)
            .play(sos > 0 ? AppSound.sos : AppSound.point);
      }
    } catch (_) {
      // Turn already advanced or room changed — safe to ignore.
    }
  }

  Future<void> _ensureChatRoom(String roomId, List<String> playerIds) async {
    if (_matchRoomEnsured) return;
    try {
      final room = await ref
          .read(chatRepositoryProvider)
          .ensureMatchRoom(roomId: roomId, participants: playerIds);
      if (mounted) {
        setState(() {
          _matchChatRoom = room;
          _matchRoomEnsured = true;
        });
      }
    } catch (e) {
      debugPrint('Error ensuring match chat room: $e');
    }
  }

  void _triggerFloatingReaction(String emoji) {
    if (!mounted) return;
    setState(() {
      _activeFloatingReactions.add(emoji);
    });
  }

  void _checkRoomEvents(GameRoom current) {
    if (_prevRoom == null) {
      _eventLogs.add(
        '[Lobby] Match started! Grid: ${current.boardSize}x${current.boardSize}',
      );
      for (final p in current.players) {
        _eventLogs.add('[Lobby] ${p.name} joined the arena');
      }
      return;
    }

    if (current.players.length > _prevRoom!.players.length) {
      final joined = current.players.where(
        (p) => !_prevRoom!.players.any((old) => old.uid == p.uid),
      );
      for (final p in joined) {
        _eventLogs.add('[Lobby] ${p.name} joined');
      }
    }

    if (current.lastPlacedPosition != _prevRoom!.lastPlacedPosition &&
        current.lastPlacedPosition != null) {
      final placerId = current.lastPlacedPlayerId;
      final player = current.players.firstWhere(
        (p) => p.uid == placerId,
        orElse: () => current.players[0],
      );
      final cell = current.lastPlacedPosition!;
      final letter = current.lastPlacedLetter ?? '';
      _eventLogs.add('[Turn] ${player.name} placed \'$letter\' at cell $cell');
    }

    for (var i = 0; i < current.players.length; i++) {
      final oldPlayer = _prevRoom!.players.firstWhere(
        (p) => p.uid == current.players[i].uid,
        orElse: () => current.players[i],
      );
      if (current.players[i].score > oldPlayer.score) {
        final diff = current.players[i].score - oldPlayer.score;
        final sosCount = diff ~/ 10;
        _eventLogs.add(
          '🔥 [SOS] ${current.players[i].name} created $sosCount SOS! (+$diff pts)',
        );
      }
    }

    if (current.status != _prevRoom!.status) {
      if (current.status == GameRoomStatus.abandoned) {
        _eventLogs.add('🚨 [Exit] Match abandoned by opponent');
      } else if (current.status == GameRoomStatus.finished) {
        _eventLogs.add('🏆 [End] Match finished!');
      }
    }
  }

  Future<void> _place(GameRoom room, int pos) async {
    final me = ref.read(currentUidProvider);
    if (me == null || room.players[room.currentTurn].uid != me) return;
    final letterStr = _letter == SosLetter.s ? 'S' : 'O';
    try {
      final sos = await ref
          .read(gameRepositoryProvider)
          .placeLetter(
            roomId: room.id,
            playerId: me,
            position: pos,
            letter: letterStr,
          );
      final sound = ref.read(soundServiceProvider);
      sound.play(sos > 0 ? AppSound.sos : AppSound.point);
      HapticFeedback.mediumImpact();
    } catch (e) {
      AppSnackBar.showError(context, e.toString());
    }
  }

  void _placeRandomMove(GameRoom room) {
    final emptyIndices = <int>[];
    for (var i = 0; i < room.board.length; i++) {
      if (room.board[i].isEmpty) {
        emptyIndices.add(i);
      }
    }
    if (emptyIndices.isNotEmpty) {
      final randPos = emptyIndices[math.Random().nextInt(emptyIndices.length)];
      _place(room, randPos);
    }
  }

  void _showOnlineHints(GameRoom room) {
    final engine = SosEngine(room.boardSize);
    final hints = <int>{};
    for (var i = 0; i < room.board.length; i++) {
      if (room.board[i].isEmpty) {
        final sLines = engine.findSosCreated(
          board: room.board,
          pos: i,
          letter: SosLetter.s,
        );
        final oLines = engine.findSosCreated(
          board: room.board,
          pos: i,
          letter: SosLetter.o,
        );
        if (sLines.isNotEmpty || oLines.isNotEmpty) {
          hints.add(i);
        }
      }
    }
    setState(() => _customHighlights = hints);
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
                'If you leave now, the match will be forfeited and your opponent will be notified.',
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

  void _showPlayerSurrenderedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  Icons.door_back_door_outlined,
                  color: AppColors.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'OPPONENT EXITED',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 18,
                  color: AppColors.danger,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your opponent has exited/abandoned the match. The game is ended.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.go(RouteNames.home);
                  },
                  child: Text(
                    'Return to Home',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChatSheet(BuildContext context, GameRoom room) {
    if (_matchChatRoom == null) return;
    setState(() => _chatSheetOpen = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InGameChatWidget(
        room: _matchChatRoom!,
        onClose: () => setState(() => _chatSheetOpen = false),
      ),
    ).then((_) {
      if (mounted) setState(() => _chatSheetOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncRoom = ref.watch(gameRoomProvider(widget.roomId));
    final me = ref.watch(currentUidProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    ref.listen<AsyncValue<List<Message>>>(
      roomMessagesProvider('match_${widget.roomId}'),
      (prev, next) {
        final messages = next.valueOrNull;
        if (messages != null && messages.isNotEmpty) {
          final lastMsg = messages.last;
          if (_lastProcessedMsgId != lastMsg.id) {
            _lastProcessedMsgId = lastMsg.id;

            final meUid = ref.read(currentUidProvider);
            final text = lastMsg.text;
            if (['👍', '😂', '🔥', '😮', '❤️'].contains(text)) {
              _triggerFloatingReaction(text);
            }
            if (lastMsg.senderId != meUid) {
              if (!_chatSheetOpen && mounted) {
                setState(() {
                  _lastIncomingMessage = lastMsg;
                  _showChatToast = true;
                });
                Future.delayed(const Duration(seconds: 4), () {
                  if (mounted && _lastIncomingMessage?.id == lastMsg.id) {
                    setState(() => _showChatToast = false);
                  }
                });
              }
            }
          }
        }
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmationDialog(context);
        if (shouldPop && context.mounted) {
          await ref.read(gameRepositoryProvider).abandon(widget.roomId);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
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
                await ref.read(gameRepositoryProvider).abandon(widget.roomId);
                if (context.mounted) {
                  context.pop();
                }
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
            'SOS Arena Match',
            style: GoogleFonts.luckiestGuy(
              fontSize: 18,
              color: AppColors.arenaGold,
              letterSpacing: 1.5,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_matchChatRoom != null)
              _ChatActionButton(
                roomId: 'match_${widget.roomId}',
                onTap: () => asyncRoom.whenData((room) {
                  if (room != null) _openChatSheet(context, room);
                }),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: _ArenaBackground()),
            asyncRoom.when(
              loading: () => const AppLoader(label: 'Loading room…'),
              error: (e, _) => ErrorView(message: '$e'),
              data: (room) {
                if (room == null)
                  return const ErrorView(message: 'Room not found');
                _checkRoomEvents(room);
                _prevRoom = room;
                _maybeDriveBot(room, me);
                if (!_matchRoomEnsured && room.playerIds.isNotEmpty) {
                  _ensureChatRoom(room.id, room.playerIds);
                }

                final allSosLines = SosEngine(
                  room.boardSize,
                ).findAllSos(room.board);
                _completedSosColors.removeWhere(
                  (line, _) => !allSosLines.contains(line),
                );
                final newLines = allSosLines
                    .where((line) => !_completedSosColors.containsKey(line))
                    .toList();
                if (newLines.isNotEmpty) {
                  final lastPlayerId = room.lastPlacedPlayerId;
                  int playerIndex = room.currentTurn;
                  if (lastPlayerId != null) {
                    final idx = room.players.indexWhere(
                      (p) => p.uid == lastPlayerId,
                    );
                    if (idx != -1) {
                      playerIndex = idx;
                    }
                  }
                  final playerColor =
                      AppColors.playerPalette[playerIndex %
                          AppColors.playerPalette.length];
                  for (final line in newLines) {
                    _completedSosColors[line] = playerColor;
                  }
                }

                if (room.status == GameRoomStatus.finished && !_summaryShown) {
                  _summaryShown = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context.pushReplacement(
                        '${RouteNames.matchSummary}?roomId=${room.id}',
                      );
                    }
                  });
                }

                if (room.status == GameRoomStatus.abandoned && !_summaryShown) {
                  _summaryShown = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showPlayerSurrenderedDialog(context);
                    }
                  });
                }

                if (room.status == GameRoomStatus.waiting) {
                  return _Waiting(room: room);
                }

                if (room.status == GameRoomStatus.active &&
                    room.type == GameRoomType.friend &&
                    room.players.length == 2 &&
                    !_vsAnimationDone &&
                    !_showVsAnimation) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _showVsAnimation = true;
                      });
                    }
                  });
                }

                final myTurn =
                    me != null && room.players[room.currentTurn].uid == me;
                final currentColor =
                    AppColors.playerPalette[room.currentTurn %
                        AppColors.playerPalette.length];

                final Widget content = SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    child: Column(
                      children: [
                        _BattleHeader(room: room),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.arenaStone,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: currentColor.withValues(alpha: 0.5),
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: currentColor.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: myTurn
                                          ? AppColors.success
                                          : AppColors.onArenaMuted,
                                      shape: BoxShape.circle,
                                      boxShadow: myTurn
                                          ? [
                                              BoxShadow(
                                                color: AppColors.success
                                                    .withOpacity(0.5),
                                                blurRadius: 6,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    myTurn ? 'YOUR TURN' : 'OPPONENT\'S TURN',
                                    style: GoogleFonts.luckiestGuy(
                                      fontSize: 13,
                                      color: myTurn
                                          ? AppColors.success
                                          : AppColors.onArenaMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              CircularTurnTimer(
                                duration: 30,
                                currentTurn: room.currentTurn,
                                isActive: room.status == GameRoomStatus.active,
                                onTimeout: () {
                                  if (myTurn) {
                                    _placeRandomMove(room);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: GameBoardWidget(
                              arena: true,
                              size: room.boardSize,
                              board: room.board,
                              highlightCells: _customHighlights,
                              disabled: !myTurn,
                              lastPlacedPosition: room.lastPlacedPosition,
                              sosLines: allSosLines,
                              lineColors: _completedSosColors,
                              onTap: (i) async {
                                if (_eraserMode) {
                                  if (room.board[i].isEmpty) return;
                                  if (me != null) {
                                    try {
                                      await ref
                                          .read(userRepositoryProvider)
                                          .consumeTool(
                                            uid: me,
                                            itemId: 'erase_cell',
                                          );
                                      await ref
                                          .read(gameRepositoryProvider)
                                          .eraseCellOnline(
                                            roomId: room.id,
                                            position: i,
                                          );
                                      setState(() {
                                        _eraserMode = false;
                                        _customHighlights = const {};
                                      });
                                    } catch (e) {
                                      AppSnackBar.showError(
                                        context,
                                        e.toString(),
                                      );
                                    }
                                  }
                                } else {
                                  if (room.board[i].isNotEmpty) return;
                                  _place(room, i);
                                  setState(() => _customHighlights = const {});
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (user != null && room.magicEnabled) ...[
                          IgnorePointer(
                            ignoring: !myTurn,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 220),
                              opacity: myTurn ? 1.0 : 0.55,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.arenaStone,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _eraserMode
                                        ? AppColors.danger
                                        : AppColors.arenaGold.withValues(
                                            alpha: 0.35,
                                          ),
                                    width: _eraserMode ? 1.8 : 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_eraserMode
                                                  ? AppColors.danger
                                                  : AppColors.arenaGold)
                                              .withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 12,
                                          color: !myTurn
                                              ? AppColors.onArenaMuted
                                              : (_eraserMode
                                                    ? AppColors.danger
                                                    : AppColors.arenaGold),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          !myTurn
                                              ? "WAITING FOR OPPONENT'S TURN"
                                              : (_eraserMode
                                                    ? 'SELECT OCCUPIED CELL TO ERASE'
                                                    : 'MAGIC SPELLS'),
                                          style: GoogleFonts.luckiestGuy(
                                            fontSize: 11,
                                            color: !myTurn
                                                ? AppColors.onArenaMuted
                                                : (_eraserMode
                                                      ? AppColors.danger
                                                      : AppColors.arenaGold),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _SpellButton(
                                          label: 'Erase Cell',
                                          icon: Icons.delete_sweep,
                                          cost: 100,
                                          itemId: 'erase_cell',
                                          count:
                                              user.inventory['erase_cell'] ?? 0,
                                          active: myTurn,
                                          isSelected: _eraserMode,
                                          onCast: () {
                                            setState(
                                              () => _eraserMode = !_eraserMode,
                                            );
                                          },
                                          onBuy: () async {
                                            try {
                                              await ref
                                                  .read(userRepositoryProvider)
                                                  .purchaseTool(
                                                    uid: user.uid,
                                                    itemId: 'erase_cell',
                                                    cost: 100,
                                                  );
                                            } catch (e) {
                                              AppSnackBar.showError(
                                                context,
                                                e.toString(),
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
                                          count:
                                              user.inventory['hint_vision'] ??
                                              0,
                                          active: myTurn && !_eraserMode,
                                          onCast: () async {
                                            try {
                                              await ref
                                                  .read(userRepositoryProvider)
                                                  .consumeTool(
                                                    uid: user.uid,
                                                    itemId: 'hint_vision',
                                                  );
                                              _showOnlineHints(room);
                                            } catch (e) {
                                              AppSnackBar.showError(
                                                context,
                                                e.toString(),
                                              );
                                            }
                                          },
                                          onBuy: () async {
                                            try {
                                              await ref
                                                  .read(userRepositoryProvider)
                                                  .purchaseTool(
                                                    uid: user.uid,
                                                    itemId: 'hint_vision',
                                                    cost: 30,
                                                  );
                                            } catch (e) {
                                              AppSnackBar.showError(
                                                context,
                                                e.toString(),
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
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _LetterBtn(
                                  letter: 'S',
                                  selected: _letter == SosLetter.s,
                                  color: AppColors.sColor,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _letter = SosLetter.s);
                                  },
                                ),
                                const SizedBox(width: 12),
                                _LetterBtn(
                                  letter: 'O',
                                  selected: _letter == SosLetter.o,
                                  color: AppColors.oColor,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _letter = SosLetter.o);
                                  },
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showLogs = !_showLogs),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.arenaStone,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.arenaGold.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 14,
                                      color: AppColors.arenaGold,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Logs',
                                      style: GoogleFonts.luckiestGuy(
                                        fontSize: 10,
                                        color: AppColors.arenaGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_showLogs) _buildEventLogWidget(),
                      ],
                    ),
                  ),
                );

                Widget screen = content;
                if (room.status == GameRoomStatus.finished) {
                  screen = Stack(
                    children: [
                      content,
                      const Positioned.fill(child: ConfettiShower()),
                    ],
                  );
                }

                if (_activeFloatingReactions.isNotEmpty) {
                  screen = Stack(
                    children: [
                      screen,
                      for (final emoji in _activeFloatingReactions)
                        _FloatingEmoji(
                          emoji: emoji,
                          onFinished: () {
                            setState(() {
                              _activeFloatingReactions.remove(emoji);
                            });
                          },
                        ),
                    ],
                  );
                }
                if (_showChatToast && _lastIncomingMessage != null) {
                  screen = Stack(
                    children: [
                      screen,
                      Positioned(
                        top: 10,
                        left: 20,
                        right: 20,
                        child: _IncomingMessageTicker(
                          message: _lastIncomingMessage!,
                          onTap: () {
                            setState(() => _showChatToast = false);
                            _openChatSheet(context, room);
                          },
                        ),
                      ),
                    ],
                  );
                }

                if (_showVsAnimation && room.players.length >= 2) {
                  return Stack(
                    children: [
                      screen,
                      Positioned.fill(
                        child: VsAnimationOverlay(
                          p1Name: room.players[0].name,
                          p1Photo: room.players[0].photoUrl,
                          p2Name: room.players[1].name,
                          p2Photo: room.players[1].photoUrl,
                          title: 'MATCH STARTING',
                          onComplete: () {
                            if (mounted) {
                              setState(() {
                                _showVsAnimation = false;
                                _vsAnimationDone = true;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }

                return screen;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLogWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.arenaStone,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.arenaGold.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: ListView.builder(
        reverse: true,
        itemCount: _eventLogs.length,
        itemBuilder: (context, i) {
          final log = _eventLogs[_eventLogs.length - 1 - i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              log,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.onArenaMuted,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatActionButton extends ConsumerWidget {
  const _ChatActionButton({required this.roomId, required this.onTap});
  final String roomId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMessages = ref.watch(roomMessagesProvider(roomId));
    final me = ref.watch(currentUidProvider);

    int unreadCount = 0;
    if (me != null && asyncMessages.hasValue) {
      unreadCount = asyncMessages.value!
          .where((m) => m.senderId != me && m.status != 'read')
          .length;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
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
              Icons.chat_bubble_rounded,
              size: 18,
              color: AppColors.arenaGold,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: 4,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$unreadCount',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingEmoji extends StatefulWidget {
  const _FloatingEmoji({required this.emoji, required this.onFinished});
  final String emoji;
  final VoidCallback onFinished;

  @override
  State<_FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<_FloatingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final double _startX;

  @override
  void initState() {
    super.initState();
    _startX = 60.0 + math.Random().nextDouble() * 220.0;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward().then((_) => widget.onFinished());
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
        final y = 480.0 - (val * 350.0);
        final x = _startX + math.sin(val * math.pi * 3.5) * 22.0;
        final scale = 0.8 + (val * 0.9);
        final opacity = (1.0 - (val * 1.15)).clamp(0.0, 1.0);

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Text(widget.emoji, style: const TextStyle(fontSize: 44)),
            ),
          ),
        );
      },
    );
  }
}

class _IncomingMessageTicker extends StatelessWidget {
  const _IncomingMessageTicker({required this.message, required this.onTap});
  final Message message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.primary.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              UserAvatar(
                photoUrl: message.senderPhoto,
                name: message.senderName,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.senderName,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      message.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InGameChatWidget extends ConsumerStatefulWidget {
  const _InGameChatWidget({required this.room, required this.onClose});
  final ChatRoom room;
  final VoidCallback onClose;

  @override
  ConsumerState<_InGameChatWidget> createState() => _InGameChatWidgetState();
}

class _InGameChatWidgetState extends ConsumerState<_InGameChatWidget> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  void _markRead() {
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me != null) {
      ref
          .read(chatRepositoryProvider)
          .markRead(roomId: widget.room.id, uid: me.uid);
      ref
          .read(chatRepositoryProvider)
          .markMessagesAsRead(roomId: widget.room.id, myUid: me.uid);
    }
  }

  void _onTyping() {
    if (_isTyping) return;
    _isTyping = true;
    _updateFirestoreTyping(true);

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      _updateFirestoreTyping(false);
    });
  }

  void _updateFirestoreTyping(bool typing) {
    final me = ref.read(currentUidProvider);
    if (me == null) return;
    FirebaseFirestore.instance
        .collection(AppConstants.chatRoomsCollection)
        .doc(widget.room.id)
        .set({
          'typingState': {me: typing},
        }, SetOptions(merge: true));
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    _ctrl.clear();
    _isTyping = false;
    _updateFirestoreTyping(false);

    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            room: widget.room,
            senderId: me.uid,
            senderName: me.name,
            senderPhoto: me.photoUrl,
            text: text.trim(),
          );
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    _updateFirestoreTyping(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncMessages = ref.watch(roomMessagesProvider(widget.room.id));
    final me = ref.watch(currentUserProvider).valueOrNull;
    final otherUid = me != null ? widget.room.otherUid(me.uid) : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.18),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MATCH CHAT',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 16,
                            color: AppColors.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        widget.onClose();
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  color: AppColors.surfaceContainerLow,
                  child: asyncMessages.when(
                    loading: () => const AppLoader(),
                    error: (e, _) => ErrorView(message: '$e'),
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'Say hello to your opponent! 👋',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[messages.length - 1 - i];
                          final isMine = m.senderId == me?.uid;
                          return _InGameMessageBubble(
                            message: m,
                            isMine: isMine,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.chatRoomsCollection)
                    .doc(widget.room.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final typingMap = data?['typingState'] as Map?;
                  final otherTyping = typingMap?[otherUid] as bool? ?? false;

                  if (!otherTyping) return const SizedBox(height: 0);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Opponent is typing...',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 14,
                ),
                color: AppColors.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['👍', '😂', '🔥', '😮', '❤️'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _send(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh.withValues(
                            alpha: 0.3,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.18),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: _ctrl,
                          textInputAction: TextInputAction.send,
                          onChanged: (_) => _onTyping(),
                          onSubmitted: (val) {
                            HapticFeedback.mediumImpact();
                            _send(val);
                          },
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Send message...',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceMuted.withOpacity(0.4),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _send(_ctrl.text);
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.sColor],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InGameMessageBubble extends StatelessWidget {
  const _InGameMessageBubble({required this.message, required this.isMine});
  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final hasSpell = ['👍', '😂', '🔥', '😮', '❤️'].contains(message.text);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            UserAvatar(
              photoUrl: message.senderPhoto,
              name: message.senderName,
              size: 24,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: hasSpell ? 10 : 12,
                vertical: hasSpell ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: hasSpell
                    ? Colors.transparent
                    : (isMine
                          ? AppColors.primary
                          : AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMine ? 14 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 14),
                ),
                border: hasSpell
                    ? null
                    : Border.all(
                        color: isMine
                            ? Colors.transparent
                            : AppColors.primary.withOpacity(0.1),
                        width: 1,
                      ),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.outfit(
                  fontSize: hasSpell ? 26 : 13,
                  fontWeight: FontWeight.w700,
                  color: isMine ? Colors.white : AppColors.onSurface,
                ),
              ),
            ),
          ),
        ],
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
              : (hasSpell ? onCast : (currentPoints >= cost ? onBuy : null)),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.danger.withValues(alpha: 0.18)
                  : (hasSpell
                        ? AppColors.arenaGold.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.danger
                    : (hasSpell
                          ? AppColors.arenaGold
                          : AppColors.onArenaMuted.withValues(alpha: 0.4)),
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
                      : (hasSpell
                            ? AppColors.arenaGold
                            : AppColors.onArenaMuted),
                ),
                const SizedBox(width: 4),
                Text(
                  hasSpell ? '$count' : 'Buy ($cost)',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? AppColors.danger
                        : (hasSpell
                              ? AppColors.arenaGold
                              : AppColors.onArenaMuted),
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
            color: AppColors.onArenaMuted,
          ),
        ),
      ],
    );
  }
}

class _Waiting extends ConsumerWidget {
  const _Waiting({required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUidProvider);
    final isHost = me != null && room.hostId == me;
    final joined = room.players.length;
    final canStartEarly = isHost && joined >= 2 && joined < room.maxPlayers;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hourglass_top,
                color: AppColors.sColor,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                room.maxPlayers > 2
                    ? 'Waiting for players…'
                    : 'Waiting for opponent…',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$joined / ${room.maxPlayers} joined',
                style: const TextStyle(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (room.code != null) ...[
                const Text(
                  'Share this room code:',
                  style: TextStyle(color: AppColors.onSurfaceMuted),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  room.code!,
                  style: const TextStyle(
                    fontSize: 32,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w800,
                    color: AppColors.highlight,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (canStartEarly) ...[
                AppButton(
                  label: 'Start Now ($joined Players)',
                  onPressed: () async {
                    await ref.read(gameRepositoryProvider).startNow(room.id);
                  },
                ),
                const SizedBox(height: 10),
              ],
              AppButton(
                variant: AppButtonVariant.secondary,
                label: 'Cancel',
                onPressed: () async {
                  await ref.read(gameRepositoryProvider).abandon(room.id);
                  if (context.mounted) context.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchEvent {
  final String text;
  final DateTime timestamp;
  MatchEvent(this.text) : timestamp = DateTime.now();
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

class _ArenaBackground extends StatelessWidget {
  const _ArenaBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.arenaBgTop, AppColors.arenaBgBottom],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.3),
            radius: 1.1,
            colors: [Color(0x33FF6A00), Color(0x00FF6A00)],
            stops: [0.0, 0.72],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _BattleHeader extends StatelessWidget {
  const _BattleHeader({required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    final players = room.players;
    int maxScore = 1;
    for (final p in players) {
      if (p.score > maxScore) maxScore = p.score;
    }

    Color colorFor(int i) =>
        AppColors.playerPalette[i % AppColors.playerPalette.length];

    if (players.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _PlayerBattleCard(
              name: players[0].name,
              photoUrl: players[0].photoUrl,
              score: players[0].score,
              color: colorFor(0),
              isCurrentTurn: room.currentTurn == 0,
              fill: players[0].score / maxScore,
              mirrored: false,
            ),
          ),
          const _VsBadge(),
          Expanded(
            child: _PlayerBattleCard(
              name: players[1].name,
              photoUrl: players[1].photoUrl,
              score: players[1].score,
              color: colorFor(1),
              isCurrentTurn: room.currentTurn == 1,
              fill: players[1].score / maxScore,
              mirrored: true,
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < players.length; i++) ...[
            SizedBox(
              width: 180,
              child: _PlayerBattleCard(
                name: players[i].name,
                photoUrl: players[i].photoUrl,
                score: players[i].score,
                color: colorFor(i),
                isCurrentTurn: room.currentTurn == i,
                fill: players[i].score / maxScore,
                mirrored: false,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PlayerBattleCard extends StatelessWidget {
  const _PlayerBattleCard({
    required this.name,
    required this.photoUrl,
    required this.score,
    required this.color,
    required this.isCurrentTurn,
    required this.fill,
    required this.mirrored,
  });

  final String name;
  final String? photoUrl;
  final int score;
  final Color color;
  final bool isCurrentTurn;
  final double fill;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
        ],
      ),
      child: UserAvatar(name: name, photoUrl: photoUrl, size: 32),
    );

    final info = Column(
      crossAxisAlignment: mirrored
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: mirrored
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 13,
              color: AppColors.arenaGold,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: mirrored ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            color: Colors.black.withValues(alpha: 0.35),
            child: Align(
              alignment: mirrored
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fill.clamp(0.04, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color.lerp(color, Colors.white, 0.4)!, color],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            '$score pts',
            key: ValueKey(score),
            style: TextStyle(
              color: AppColors.onArena.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );

    final children = <Widget>[
      avatar,
      const SizedBox(width: 10),
      Expanded(child: info),
    ];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isCurrentTurn ? 1.0 : 0.6,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: mirrored ? Alignment.centerRight : Alignment.centerLeft,
            end: mirrored ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              color.withValues(alpha: 0.55),
              color.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentTurn ? color : color.withValues(alpha: 0.3),
            width: isCurrentTurn ? 2.2 : 1,
          ),
          boxShadow: isCurrentTurn
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(children: mirrored ? children.reversed.toList() : children),
      ),
    );
  }
}

class _VsBadge extends StatelessWidget {
  const _VsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.arenaGold, AppColors.arenaGlow],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.arenaGlow.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        'VS',
        style: GoogleFonts.luckiestGuy(
          fontSize: 14,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
