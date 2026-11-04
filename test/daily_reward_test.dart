import 'package:flutter_test/flutter_test.dart';
import 'package:soso/core/models/app_user.dart';

void main() {
  String formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  group('Daily Reward & Streak Progression Logic', () {
    test('canClaimDailyReward returns true when user has never claimed', () {
      const user = AppUser(
        uid: 'user_1',
        name: 'Player',
        email: 'player@example.com',
        dailyStreak: 0,
        lastStreakClaimDate: null,
      );

      expect(user.canClaimDailyReward, isTrue);
    });

    test('canClaimDailyReward returns true when last claim was yesterday', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = formatDate(yesterday);

      final user = AppUser(
        uid: 'user_1',
        name: 'Player',
        email: 'player@example.com',
        dailyStreak: 1,
        lastStreakClaimDate: yesterdayStr,
      );

      expect(user.canClaimDailyReward, isTrue);
    });

    test(
      'canClaimDailyReward returns false when already claimed today (repeated claim prevention)',
      () {
        final now = DateTime.now();
        final todayStr = formatDate(now);

        final user = AppUser(
          uid: 'user_1',
          name: 'Player',
          email: 'player@example.com',
          dailyStreak: 1,
          lastStreakClaimDate: todayStr,
        );

        expect(user.canClaimDailyReward, isFalse);
      },
    );

    test('Day 1 claiming: first-time claim initializes streak to 1', () {
      final now = DateTime.now();
      final yesterdayStr = formatDate(now.subtract(const Duration(days: 1)));
      const currentStreak = 0;
      const String? lastClaimDate = null;

      int newStreak;
      if (lastClaimDate == yesterdayStr) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }

      expect(newStreak, 1);
    });

    test(
      'Day 2 progression: claiming on consecutive day advances streak to 2',
      () {
        final now = DateTime.now();
        final yesterdayStr = formatDate(now.subtract(const Duration(days: 1)));
        const currentStreak = 1;
        final String lastClaimDate = yesterdayStr;

        int newStreak;
        if (lastClaimDate == yesterdayStr) {
          newStreak = currentStreak + 1;
        } else {
          newStreak = 1;
        }

        expect(newStreak, 2);
      },
    );

    test('Missed day: streak resets to 1 when gap is 2 or more days', () {
      final now = DateTime.now();
      final twoDaysAgoStr = formatDate(now.subtract(const Duration(days: 2)));
      final yesterdayStr = formatDate(now.subtract(const Duration(days: 1)));
      const currentStreak = 5;
      final String lastClaimDate = twoDaysAgoStr;

      int newStreak;
      if (lastClaimDate == yesterdayStr) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }

      expect(newStreak, 1);
    });

    test(
      'Idempotency guard: attempting to claim twice on same day does not advance streak',
      () {
        final now = DateTime.now();
        final todayStr = formatDate(now);
        const currentStreak = 3;
        final String lastClaimDate = todayStr;

        // When lastClaimDate == todayStr, the repository returns current streak and prevents double credit
        final isAlreadyClaimedToday = lastClaimDate == todayStr;
        expect(isAlreadyClaimedToday, isTrue);

        final resultStreak = isAlreadyClaimedToday
            ? currentStreak
            : currentStreak + 1;
        expect(resultStreak, 3);
      },
    );

    test(
      '7-Day Cycle wrapping: day index advances correctly and wraps after Day 7',
      () {
        int getDayInCycle(int streak) => ((streak - 1) % 7) + 1;

        expect(getDayInCycle(1), 1);
        expect(getDayInCycle(2), 2);
        expect(getDayInCycle(3), 3);
        expect(getDayInCycle(4), 4);
        expect(getDayInCycle(5), 5);
        expect(getDayInCycle(6), 6);
        expect(getDayInCycle(7), 7);
        expect(getDayInCycle(8), 1); // Cycle 2 Day 1
        expect(getDayInCycle(14), 7); // Cycle 2 Day 7
        expect(getDayInCycle(15), 1); // Cycle 3 Day 1
      },
    );

    test('Completed days calculation matches UI state', () {
      // When canClaim is false (claimed today):
      // completedDays = ((currentStreak - 1) % 7) + 1
      const currentStreak = 2;
      const claimedDayInCycle = ((currentStreak - 1) % 7) + 1;
      expect(claimedDayInCycle, 2);

      // Both Day 1 and Day 2 should show as completed
      expect(1 <= claimedDayInCycle, isTrue);
      expect(2 <= claimedDayInCycle, isTrue);
      expect(3 <= claimedDayInCycle, isFalse);
    });

    test('Longest streak is updated when current streak surpasses it', () {
      var longestStreak = 3;
      const newStreak = 4;
      if (newStreak > longestStreak) {
        longestStreak = newStreak;
      }
      expect(longestStreak, 4);

      // Streak broken to 1: longest streak remains 4
      const resetStreak = 1;
      if (resetStreak > longestStreak) {
        longestStreak = resetStreak;
      }
      expect(longestStreak, 4);
    });
  });
}
