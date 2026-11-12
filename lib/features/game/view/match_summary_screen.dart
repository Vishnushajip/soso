import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_banner_ad.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/models/game_room.dart';
import '../../../core/models/match_record.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/game_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/routes/route_names.dart';
import '../widgets/confetti_shower.dart';

final matchAwardedPointsProvider = StateProvider.autoDispose<int?>(
  (ref) => null,
);
final matchStatsAppliedProvider = StateProvider.family<bool, String>(
  (ref, roomId) => false,
);
final restartMatchLoadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class MatchSummaryScreen extends ConsumerStatefulWidget {
  const MatchSummaryScreen({super.key, required this.roomId});
  final String roomId;
  @override
  ConsumerState<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends ConsumerState<MatchSummaryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _glowCtrl;
  late final Animation<double> _panelScale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _panelScale = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutBack,
    );
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyStats(GameRoom room) async {
    if (ref.read(matchStatsAppliedProvider(widget.roomId))) return;
    ref.read(matchStatsAppliedProvider(widget.roomId).notifier).state = true;
    final me = ref.read(currentUidProvider);

    final isWinner = me != null && room.winnerId == me;
    final isDraw = room.winnerId == null;
    final result = isDraw ? 'draw' : (isWinner ? 'win' : 'loss');
    ref.read(trackingServiceProvider).matchCompleted(
          mode: room.type.name,
          result: result,
          matchKey: 'online_${room.id}',
        );

    if (me == null) return;
    final myPlayer = room.players.firstWhere(
      (p) => p.uid == me,
      orElse: () => room.players.first,
    );
    final won = room.winnerId == me;
    final delta = myPlayer.score + (won ? AppConstants.pointsPerWin : 0);

    ref.read(soundServiceProvider).play(won ? AppSound.win : AppSound.lose);
    ref
        .read(hapticServiceProvider)
        .fire(won ? HapticEvent.win : HapticEvent.lose);

    await ref
        .read(userRepositoryProvider)
        .applyMatchResult(uid: me, pointsDelta: delta, won: won);

    final p1 = room.players.isNotEmpty
        ? room.players[0]
        : const GamePlayer(uid: '', name: 'Player 1');
    final p2 = room.players.length > 1
        ? room.players[1]
        : const GamePlayer(uid: '', name: 'Player 2');
    final winnerIndex = room.winnerId == null
        ? null
        : (room.winnerId == p1.uid ? 0 : (room.winnerId == p2.uid ? 1 : null));
    final winnerName = room.winnerId == null
        ? null
        : (room.winnerId == p1.uid ? p1.name : p2.name);

    final record = MatchRecord(
      id: room.id,
      gameType: room.type.name,
      boardSize: room.boardSize,
      p1Name: p1.name,
      p1Score: p1.score,
      p1PhotoUrl: p1.photoUrl,
      p2Name: p2.name,
      p2Score: p2.score,
      p2PhotoUrl: p2.photoUrl,
      winnerName: winnerName,
      winnerIndex: winnerIndex,
      playedAt: room.finishedAt ?? DateTime.now(),
      moves: const [],
    );
    ref.read(matchHistoryRepositoryProvider).saveMatch(uid: me, match: record);

    if (mounted) {
      ref.read(matchAwardedPointsProvider.notifier).state = delta;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRoom = ref.watch(gameRoomProvider(widget.roomId));
    final me = ref.watch(currentUidProvider);
    final awardedPoints = ref.watch(matchAwardedPointsProvider);
    final isRestarting = ref.watch(restartMatchLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.arenaBgBottom,
      body: Stack(
        children: [
          const Positioned.fill(child: _ArenaBackdrop()),
          asyncRoom.when(
            loading: () => const AppLoader(label: 'Tallying scores…'),
            error: (e, _) => ErrorView(message: '$e'),
            data: (room) {
              if (room == null) {
                return const ErrorView(message: 'Room not found');
              }

              // If match was restarted, navigate both players back to the game board
              if (room.status == GameRoomStatus.active) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.pushReplacement(
                      '${RouteNames.gameBoard}?roomId=${room.id}',
                    );
                  }
                });
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && room.status == GameRoomStatus.finished)
                  _applyStats(room);
              });

              final ranked = [...room.players]
                ..sort((a, b) => b.score.compareTo(a.score));
              final isTie = room.winnerId == null;
              final iWon = room.winnerId != null && room.winnerId == me;
              final winner = isTie
                  ? null
                  : room.players.firstWhere(
                      (p) => p.uid == room.winnerId,
                      orElse: () => ranked.first,
                    );
              final canRestart =
                  room.type == GameRoomType.friend ||
                  room.type == GameRoomType.private;

              return Stack(
                children: [
                  SafeArea(
                    child: FadeTransition(
                      opacity: _fade,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            ScaleTransition(
                              scale: _panelScale,
                              child: _CrownPanel(
                                glow: _glowCtrl,
                                isTie: isTie,
                                iWon: iWon,
                                winnerName: winner?.name,
                                awardedPoints: awardedPoints,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: AppColors.arenaGold,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'FINAL STANDINGS',
                                  style: GoogleFonts.luckiestGuy(
                                    fontSize: 14,
                                    color: AppColors.onArena,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: ranked.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final p = ranked[i];
                                  return _RankRow(
                                    rank: i + 1,
                                    name: p.name,
                                    photoUrl: p.photoUrl,
                                    score: p.score,
                                    isMe: p.uid == me,
                                    isWinner: !isTie && p.uid == room.winnerId,
                                    delay: i,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (canRestart) ...[
                              _PrimaryButton(
                                label: isRestarting
                                    ? 'Restarting Match…'
                                    : 'Restart Match',
                                icon: Icons.replay_rounded,
                                isLoading: isRestarting,
                                onTap: () async {
                                  if (isRestarting) return;
                                  ref
                                          .read(
                                            restartMatchLoadingProvider
                                                .notifier,
                                          )
                                          .state =
                                      true;
                                  ref
                                      .read(soundServiceProvider)
                                      .play(AppSound.buttonClick);
                                  ref
                                      .read(hapticServiceProvider)
                                      .fire(HapticEvent.tap);
                                  try {
                                    await ref
                                        .read(gameRepositoryProvider)
                                        .restartRoom(roomId: room.id);
                                  } catch (e) {
                                    ref
                                            .read(
                                              restartMatchLoadingProvider
                                                  .notifier,
                                            )
                                            .state =
                                        false;
                                    if (context.mounted) {
                                      AppSnackBar.showError(
                                        context,
                                        'Could not restart match: $e',
                                      );
                                    }
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                              _SecondaryButton(
                                label: 'Back to Lobby',
                                icon: Icons.home_rounded,
                                onTap: () => context.go(RouteNames.home),
                              ),
                            ] else ...[
                              _PrimaryButton(
                                label: 'Back to Lobby',
                                icon: Icons.home_rounded,
                                onTap: () => context.go(RouteNames.home),
                              ),
                            ],
                            // Banner below the action buttons: the match is
                            // already over, so it never interrupts play.
                            const SizedBox(height: 12),
                            const AppBannerAd(placement: 'match_summary'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (iWon)
                    const Positioned.fill(
                      child: IgnorePointer(child: ConfettiShower()),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ArenaBackdrop extends StatelessWidget {
  const _ArenaBackdrop();

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
            center: Alignment(0, -0.4),
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

class _CrownPanel extends StatelessWidget {
  const _CrownPanel({
    required this.glow,
    required this.isTie,
    required this.iWon,
    required this.winnerName,
    required this.awardedPoints,
  });

  final Animation<double> glow;
  final bool isTie;
  final bool iWon;
  final String? winnerName;
  final int? awardedPoints;

  @override
  Widget build(BuildContext context) {
    final accent = isTie
        ? AppColors.arenaGold
        : iWon
        ? AppColors.success
        : AppColors.arenaPink;
    final emoji = isTie
        ? '🤝'
        : iWon
        ? '🏆'
        : '🎯';
    final title = isTie
        ? "It's a Tie!"
        : iWon
        ? 'Victory!'
        : '${winnerName ?? 'Opponent'} Wins';
    final subtitle = isTie
        ? 'Evenly matched warriors'
        : iWon
        ? 'You ruled the arena'
        : 'Better luck next round';

    return AnimatedBuilder(
      animation: glow,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.arenaStone, AppColors.arenaStoneEdge],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withOpacity(0.55), width: 2),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.18 + glow.value * 0.22),
                blurRadius: 28 + glow.value * 16,
                spreadRadius: glow.value * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent.withOpacity(0.35), Colors.transparent],
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 46)),
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.luckiestGuy(
              fontSize: 30,
              color: accent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onArenaMuted,
            ),
          ),
          if (awardedPoints != null && awardedPoints! > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, AppColors.arenaGold],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+$awardedPoints profile points',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.name,
    required this.photoUrl,
    required this.score,
    required this.isMe,
    required this.isWinner,
    required this.delay,
  });

  final int rank;
  final String name;
  final String? photoUrl;
  final int score;
  final bool isMe;
  final bool isWinner;
  final int delay;

  String get _medal {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlight = isMe ? AppColors.arenaGold : AppColors.arenaStoneEdge;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay * 90),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset((1 - t) * 28, 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.arenaStone.withOpacity(isMe ? 0.95 : 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlight.withOpacity(isMe ? 0.7 : 0.45),
            width: isMe ? 2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Center(
                child: Text(
                  _medal,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: rank <= 3 ? 22 : 15,
                    color: AppColors.onArenaMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            UserAvatar(name: name, photoUrl: photoUrl, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onArena,
                      ),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.arenaGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'YOU',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 9,
                          color: AppColors.arenaGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  if (isWinner) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.arenaGold,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$score',
              style: GoogleFonts.luckiestGuy(
                fontSize: 18,
                color: isMe ? AppColors.arenaGold : AppColors.onArena,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'pts',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onArenaMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.sColor],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 10),
            ] else ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.luckiestGuy(
                fontSize: 17,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.arenaStone,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.arenaGold.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.onArenaMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.luckiestGuy(
                fontSize: 15,
                color: AppColors.onArenaMuted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
