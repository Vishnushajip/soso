import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final asyncRoom = ref.watch(gameRoomProvider(widget.roomId));
    final me = ref.watch(currentUidProvider);

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
                        disabled: !myTurn,
                        onTap: (i) => _place(room, i),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
