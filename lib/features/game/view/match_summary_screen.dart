import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/game_room.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/game_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../routes/route_names.dart';

class MatchSummaryScreen extends ConsumerStatefulWidget {
  const MatchSummaryScreen({super.key, required this.roomId});
  final String roomId;
  @override
  ConsumerState<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends ConsumerState<MatchSummaryScreen> {
  bool _statsApplied = false;

  Future<void> _applyStats(GameRoom room) async {
    if (_statsApplied) return;
    _statsApplied = true;
    final me = ref.read(currentUidProvider);
    if (me == null) return;
    final myPlayer = room.players.firstWhere((p) => p.uid == me, orElse: () => room.players.first);
    final won = room.winnerId == me;
    await ref.read(userRepositoryProvider).applyMatchResult(
          uid: me,
          pointsDelta: myPlayer.score + (won ? AppConstants.pointsPerWin : 0),
          won: won,
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncRoom = ref.watch(gameRoomProvider(widget.roomId));
    return Scaffold(
      appBar: AppBar(title: const Text('Match Summary'), automaticallyImplyLeading: false),
      body: asyncRoom.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(message: '$e'),
        data: (room) {
          if (room == null) return const ErrorView(message: 'Room not found');
          WidgetsBinding.instance.addPostFrameCallback((_) => _applyStats(room));

          final me = ref.read(currentUidProvider);
          final ranked = [...room.players]..sort((a, b) => b.score.compareTo(a.score));
          final winnerName = room.winnerId == null
              ? 'Tie'
              : room.players.firstWhere((p) => p.uid == room.winnerId).name;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events, color: AppColors.oColor, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          room.winnerId == null ? 'It\'s a tie!' : '$winnerName wins',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SectionCard(
                      child: ListView.separated(
                        itemCount: ranked.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (_, i) {
                          final p = ranked[i];
                          final isMe = p.uid == me;
                          return Row(
                            children: [
                              Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 12),
                              UserAvatar(name: p.name, photoUrl: p.photoUrl, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isMe ? '${p.name} (You)' : p.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text('${p.score} pts', style: const TextStyle(color: AppColors.onSurfaceMuted)),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    expanded: true,
                    label: 'Back to lobby',
                    onPressed: () => context.go(RouteNames.home),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
