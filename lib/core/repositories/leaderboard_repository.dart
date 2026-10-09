import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardPage {
  final List<LeaderboardEntry> entries;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  const LeaderboardPage({required this.entries, this.lastDoc, required this.hasMore});
}

class LeaderboardRepository {
  LeaderboardRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Future<LeaderboardPage> page({
    required LeaderboardKind kind,
    int pageSize = AppConstants.leaderboardPageSize,
    DocumentSnapshot<Map<String, dynamic>>? after,
    int rankBase = 0,
  }) async {
    Query<Map<String, dynamic>> q = _users.orderBy(kind.sortField, descending: true);
    if (kind == LeaderboardKind.winRate) {
      q = q.orderBy('matchesPlayed', descending: true);
    }
    q = q.limit(pageSize);
    if (after != null) q = q.startAfterDocument(after);

    final snap = await q.get();
    final entries = <LeaderboardEntry>[];
    for (var i = 0; i < snap.docs.length; i++) {
      final user = AppUser.fromDoc(snap.docs[i]);
      entries.add(LeaderboardEntry(
        user: user,
        rank: rankBase + i + 1,
        value: _value(user, kind),
      ));
    }
    return LeaderboardPage(
      entries: entries,
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length == pageSize,
    );
  }

  num _value(AppUser u, LeaderboardKind k) => switch (k) {
        LeaderboardKind.global => u.totalPoints,
        LeaderboardKind.weekly => u.weeklyPoints,
        LeaderboardKind.monthly => u.monthlyPoints,
        LeaderboardKind.wins => u.wins,
        LeaderboardKind.winRate => (u.winRate * 100),
      };
}
