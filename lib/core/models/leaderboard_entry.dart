import 'app_user.dart';

enum LeaderboardKind { global, weekly, monthly, wins, winRate }

extension LeaderboardKindX on LeaderboardKind {
  String get title => switch (this) {
        LeaderboardKind.global => 'Global Points',
        LeaderboardKind.weekly => 'Weekly Points',
        LeaderboardKind.monthly => 'Monthly Points',
        LeaderboardKind.wins => 'Wins',
        LeaderboardKind.winRate => 'Win Rate',
      };

  String get sortField => switch (this) {
        LeaderboardKind.global => 'totalPoints',
        LeaderboardKind.weekly => 'weeklyPoints',
        LeaderboardKind.monthly => 'monthlyPoints',
        LeaderboardKind.wins => 'wins',
        LeaderboardKind.winRate => 'winRate',
      };
}

class LeaderboardEntry {
  final AppUser user;
  final int rank;
  final num value;
  const LeaderboardEntry({required this.user, required this.rank, required this.value});
}
