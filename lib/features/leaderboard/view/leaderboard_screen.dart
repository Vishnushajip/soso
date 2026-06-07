import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/leaderboard_entry.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../routes/route_names.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: _RankHeading(),
        ),
        Expanded(child: _LeaderboardPage(kind: LeaderboardKind.global)),
      ],
    );
  }
}

/// Single-rank heading banner. The app now ranks players by Global Points only,
/// so this replaces the previous multi-tab selector.
class _RankHeading extends StatelessWidget {
  const _RankHeading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.sColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Global Rankings',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Top players by total points',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
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

class _LeaderboardPage extends ConsumerStatefulWidget {
  const _LeaderboardPage({required this.kind});
  final LeaderboardKind kind;

  @override
  ConsumerState<_LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<_LeaderboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        ref
            .read(leaderboardControllerProvider(widget.kind).notifier)
            .loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final myUid = ref.watch(currentUidProvider);
    final state = ref.watch(leaderboardControllerProvider(widget.kind));

    if (state.loading && state.entries.isEmpty) return const AppLoader();
    if (state.error != null && state.entries.isEmpty) {
      return ErrorView(
        message: '${state.error}',
        onRetry: () => ref
            .read(leaderboardControllerProvider(widget.kind).notifier)
            .loadMore(reset: true),
      );
    }
    if (state.entries.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.leaderboard_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No data yet!',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 18,
                  color: AppColors.onSurface,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Play matches to appear on the board',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref
          .read(leaderboardControllerProvider(widget.kind).notifier)
          .loadMore(reset: true),
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 32),
        itemCount: state.entries.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == state.entries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: AppLoader(),
            );
          }
          final e = state.entries[i];
          final isMe = e.user.uid == myUid;
          final isTop3 = e.rank <= 3;
          return _LeaderboardCard(
            entry: e,
            kind: widget.kind,
            isMe: isMe,
            isTop3: isTop3,
            onTap: isMe
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    context.push(
                      '${RouteNames.profileDetail}?uid=${e.user.uid}',
                    );
                  },
          );
        },
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.entry,
    required this.kind,
    required this.isMe,
    required this.isTop3,
    required this.onTap,
  });

  final LeaderboardEntry entry;
  final LeaderboardKind kind;
  final bool isMe;
  final bool isTop3;
  final VoidCallback? onTap;

  Color get _rankColor {
    return switch (entry.rank) {
      1 => AppColors.highlight,
      2 => AppColors.onSurfaceMuted,
      3 => AppColors.sColor,
      _ => AppColors.primary,
    };
  }

  String get _rankEmoji {
    return switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#${entry.rank}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary.withOpacity(0.08)
              : isTop3
              ? rankColor.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMe
                ? AppColors.primary.withOpacity(0.40)
                : isTop3
                ? rankColor.withOpacity(0.35)
                : AppColors.primary.withOpacity(0.10),
            width: isMe || isTop3 ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? AppColors.primary.withOpacity(0.12)
                  : isTop3
                  ? rankColor.withOpacity(0.10)
                  : AppColors.primary.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Center(
                child: isTop3
                    ? Text(_rankEmoji, style: const TextStyle(fontSize: 22))
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.20),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#${entry.rank}',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 11,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
              ),
            ),
            Stack(
              children: [
                UserAvatar(
                  name: entry.user.name,
                  photoUrl: entry.user.photoUrl,
                  frameColor: entry.user.avatarFrameColor,
                  size: 46,
                ),
                if (isMe)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 14,
                            color: isMe
                                ? AppColors.primary
                                : AppColors.onSurface,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'You',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 9,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                      if (entry.user.customTitle != null &&
                          entry.user.customTitle!.isNotEmpty &&
                          !isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary.withOpacity(0.8),
                                AppColors.highlight.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.user.customTitle!,
                            style: GoogleFonts.outfit(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${entry.user.wins}W · ${entry.user.losses}L · ${FormatUtils.winRatePct(entry.user.wins, entry.user.matchesPlayed)} WR',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: isTop3 || isMe
                    ? LinearGradient(
                        colors: isMe
                            ? [AppColors.primary, AppColors.sColor]
                            : [rankColor, rankColor.withOpacity(0.75)],
                      )
                    : null,
                color: isTop3 || isMe
                    ? null
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isTop3 || isMe
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.18),
                  width: 1.5,
                ),
                boxShadow: isTop3 || isMe
                    ? [
                        BoxShadow(
                          color: (isMe ? AppColors.primary : rankColor)
                              .withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                kind == LeaderboardKind.winRate
                    ? '${entry.value.toStringAsFixed(0)}%'
                    : FormatUtils.compactNumber(entry.value),
                style: GoogleFonts.luckiestGuy(
                  fontSize: 13,
                  color: isTop3 || isMe ? Colors.white : AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
