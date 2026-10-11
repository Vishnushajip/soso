import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_record.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

final matchHistoryProvider = FutureProvider.autoDispose<List<MatchRecord>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  final repo = ref.watch(matchHistoryRepositoryProvider);
  return repo.getRecentMatches(uid);
});

final matchRecordByIdProvider =
    FutureProvider.autoDispose.family<MatchRecord?, String>((ref, matchId) async {
  final uid = ref.watch(currentUidProvider);
  final repo = ref.watch(matchHistoryRepositoryProvider);
  return repo.getMatchById(uid, matchId);
});
