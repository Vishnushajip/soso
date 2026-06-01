import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/leaderboard_entry.dart';
import '../../../providers/leaderboard_providers.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: LeaderboardKind.values.length, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [for (final k in LeaderboardKind.values) Tab(text: k.title)],
          labelColor: AppColors.sColor,
          unselectedLabelColor: AppColors.onSurfaceMuted,
          indicatorColor: AppColors.sColor,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [for (final k in LeaderboardKind.values) _LeaderboardPage(kind: k)],
          ),
        ),
      ],
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
        ref.read(leaderboardControllerProvider(widget.kind).notifier).loadMore();
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
    final state = ref.watch(leaderboardControllerProvider(widget.kind));
    if (state.loading && state.entries.isEmpty) return const AppLoader();
    if (state.error != null && state.entries.isEmpty) {
      return ErrorView(
        message: '${state.error}',
        onRetry: () =>
            ref.read(leaderboardControllerProvider(widget.kind).notifier).loadMore(reset: true),
      );
    }
    if (state.entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SectionCard(child: Text('No data yet.', style: TextStyle(color: AppColors.onSurfaceMuted))),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(leaderboardControllerProvider(widget.kind).notifier).loadMore(reset: true),
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: state.entries.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          if (i == state.entries.length) {
            return const Padding(padding: EdgeInsets.all(16), child: AppLoader());
          }
          final e = state.entries[i];
          return SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#${e.rank}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.highlight),
                  ),
                ),
                UserAvatar(
                  name: e.user.name,
                  photoUrl: e.user.photoUrl,
                  frameColor: e.user.avatarFrameColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(e.user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (e.user.customTitle != null && e.user.customTitle!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                e.user.customTitle!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${e.user.wins}W · ${e.user.losses}L · ${FormatUtils.winRatePct(e.user.wins, e.user.matchesPlayed)} WR',
                        style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.kind == LeaderboardKind.winRate
                      ? '${e.value.toStringAsFixed(0)}%'
                      : FormatUtils.compactNumber(e.value),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
