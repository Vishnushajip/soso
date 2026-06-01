import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/sos_engine.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../models/game_room.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/game_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../routes/route_names.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/player_score_card.dart';

class GameBoardScreen extends ConsumerStatefulWidget {
  const GameBoardScreen({super.key, required this.roomId});
  final String roomId;

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> {
  SosLetter _letter = SosLetter.s;
  String? _error;
  bool _summaryShown = false;
  bool _eraserMode = false;
  Set<int> _customHighlights = const {};

  Future<void> _place(GameRoom room, int pos) async {
    final me = ref.read(currentUidProvider);
    if (me == null || room.players[room.currentTurn].uid != me) return;
    final letterStr = _letter == SosLetter.s ? 'S' : 'O';
    try {
      final sos = await ref.read(gameRepositoryProvider).placeLetter(
            roomId: room.id, playerId: me, position: pos, letter: letterStr,
          );
      final sound = ref.read(soundServiceProvider);
      sound.play(sos > 0 ? AppSound.sos : AppSound.point);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _showOnlineHints(GameRoom room) {
    final engine = SosEngine(room.boardSize);
    final hints = <int>{};
    for (var i = 0; i < room.board.length; i++) {
      if (room.board[i].isEmpty) {
        final sLines = engine.findSosCreated(board: room.board, pos: i, letter: SosLetter.s);
        final oLines = engine.findSosCreated(board: room.board, pos: i, letter: SosLetter.o);
        if (sLines.isNotEmpty || oLines.isNotEmpty) {
          hints.add(i);
        }
      }
    }
    setState(() => _customHighlights = hints);
  }

  @override
  Widget build(BuildContext context) {
    final asyncRoom = ref.watch(gameRoomProvider(widget.roomId));
    final me = ref.watch(currentUidProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Match')),
      body: asyncRoom.when(
        loading: () => const AppLoader(label: 'Loading room…'),
        error: (e, _) => ErrorView(message: '$e'),
        data: (room) {
          if (room == null) return const ErrorView(message: 'Room not found');

          if (room.status == GameRoomStatus.finished && !_summaryShown) {
            _summaryShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pushReplacement('${RouteNames.matchSummary}?roomId=${room.id}');
              }
            });
          }

          if (room.status == GameRoomStatus.waiting) {
            return _Waiting(room: room);
          }

          final myTurn = me != null && room.players[room.currentTurn].uid == me;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < room.players.length; i++) ...[
                          PlayerScoreCard(
                            name: room.players[i].name,
                            score: room.players[i].score,
                            photoUrl: room.players[i].photoUrl,
                            color: AppColors.playerPalette[i % AppColors.playerPalette.length],
                            isCurrentTurn: i == room.currentTurn,
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
                        size: room.boardSize,
                        board: room.board,
                        highlightCells: _customHighlights,
                        disabled: !myTurn,
                        onTap: (i) async {
                          if (_eraserMode) {
                            if (room.board[i].isNotEmpty && me != null) {
                              try {
                                await ref.read(userRepositoryProvider).consumeTool(
                                      uid: me,
                                      itemId: 'erase_cell',
                                    );
                                await ref.read(gameRepositoryProvider).eraseCellOnline(
                                      roomId: room.id,
                                      position: i,
                                    );
                                setState(() {
                                  _eraserMode = false;
                                  _customHighlights = const {};
                                });
                              } catch (e) {
                                setState(() => _error = e.toString());
                              }
                            }
                          } else {
                            _place(room, i);
                            setState(() => _customHighlights = const {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Online Magic Spells Toolbelt (Erase Cell & Hint Vision)
                  if (myTurn && user != null) ...[
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
                            _eraserMode ? 'SELECT OCCUPIED CELL TO ERASE' : 'CAST MATCH SPELLS',
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
                                label: 'Erase Cell',
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
                                  try {
                                    await ref.read(userRepositoryProvider).purchaseTool(
                                          uid: user.uid,
                                          itemId: 'erase_cell',
                                          cost: 100,
                                        );
                                  } catch (e) {
                                    setState(() => _error = e.toString());
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
                                  try {
                                    await ref.read(userRepositoryProvider).consumeTool(
                                          uid: user.uid,
                                          itemId: 'hint_vision',
                                        );
                                    _showOnlineHints(room);
                                  } catch (e) {
                                    setState(() => _error = e.toString());
                                  }
                                },
                                onBuy: () async {
                                  try {
                                    await ref.read(userRepositoryProvider).purchaseTool(
                                          uid: user.uid,
                                          itemId: 'hint_vision',
                                          cost: 30,
                                        );
                                  } catch (e) {
                                    setState(() => _error = e.toString());
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
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
          );
        },
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

class _Waiting extends ConsumerWidget {
  const _Waiting({required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top, color: AppColors.sColor, size: 40),
              const SizedBox(height: 12),
              const Text('Waiting for opponent…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              if (room.code != null) ...[
                const Text('Share this room code:', style: TextStyle(color: AppColors.onSurfaceMuted)),
                const SizedBox(height: 8),
                SelectableText(
                  room.code!,
                  style: const TextStyle(
                    fontSize: 32, letterSpacing: 6, fontWeight: FontWeight.w800, color: AppColors.highlight,
                  ),
                ),
              ],
              const SizedBox(height: 16),
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
