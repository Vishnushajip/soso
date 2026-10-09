import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_entry.dart';
import '../repositories/leaderboard_repository.dart';
import 'repository_providers.dart';

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool loading;
  final bool hasMore;
  final Object? error;
  const LeaderboardState({
    this.entries = const [],
    this.loading = false,
    this.hasMore = true,
    this.error,
  });
  LeaderboardState copyWith({List<LeaderboardEntry>? entries, bool? loading, bool? hasMore, Object? error}) =>
      LeaderboardState(
        entries: entries ?? this.entries,
        loading: loading ?? this.loading,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

class LeaderboardController extends FamilyNotifier<LeaderboardState, LeaderboardKind> {
  late LeaderboardRepository _repo;
  dynamic _cursor; // last DocumentSnapshot for pagination

  @override
  LeaderboardState build(LeaderboardKind kind) {
    _repo = ref.read(leaderboardRepositoryProvider);
    // Initial fetch.
    Future.microtask(() => loadMore(reset: true));
    return const LeaderboardState(loading: true);
  }

  Future<void> loadMore({bool reset = false}) async {
    if (state.loading && !reset) return;
    if (!reset && !state.hasMore) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final page = await _repo.page(
        kind: arg,
        after: reset ? null : _cursor,
        rankBase: reset ? 0 : state.entries.length,
      );
      _cursor = page.lastDoc;
      state = LeaderboardState(
        entries: reset ? page.entries : [...state.entries, ...page.entries],
        hasMore: page.hasMore,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }
}

final leaderboardControllerProvider =
    NotifierProvider.family<LeaderboardController, LeaderboardState, LeaderboardKind>(
  LeaderboardController.new,
);
