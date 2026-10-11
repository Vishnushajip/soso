import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';

final dailyRewardClaimLoadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

class DailyRewardDialog extends ConsumerWidget {
  const DailyRewardDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const DailyRewardDialog(),
    );
  }

  static const List<_DayRewardSpec> _rewards = [
    _DayRewardSpec(day: 1, points: 50, spellName: null, spellIcon: Icons.stars_rounded),
    _DayRewardSpec(day: 2, points: 100, spellName: null, spellIcon: Icons.stars_rounded),
    _DayRewardSpec(day: 3, points: 150, spellName: 'Undo Move', spellIcon: Icons.undo_rounded),
    _DayRewardSpec(day: 4, points: 200, spellName: null, spellIcon: Icons.stars_rounded),
    _DayRewardSpec(day: 5, points: 300, spellName: 'Erase Cell', spellIcon: Icons.delete_sweep_rounded),
    _DayRewardSpec(day: 6, points: 400, spellName: null, spellIcon: Icons.stars_rounded),
    _DayRewardSpec(day: 7, points: 600, spellName: 'Vision + Erase', spellIcon: Icons.auto_awesome_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isLoading = ref.watch(dailyRewardClaimLoadingProvider);

    final currentStreak = user?.dailyStreak ?? 0;
    final canClaim = user?.canClaimDailyReward ?? false;
    // Current day in 7-day cycle:
    // If can claim: next day to claim is (currentStreak % 7) + 1 if claimed yesterday, or 1 if broken streak
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    final isConsecutive = user?.lastStreakClaimDate == yesterdayStr;
    final nextDayToClaim = canClaim
        ? (isConsecutive ? ((currentStreak % 7) + 1) : 1)
        : (((currentStreak - 1) % 7) + 1);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: AppColors.arenaStone,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.arenaGold.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.arenaGold.withValues(alpha: 0.2),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Close and Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              '$currentStreak Day Streak',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 13,
                                color: AppColors.secondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(soundServiceProvider).play(AppSound.buttonClick);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.arenaBgBottom,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.onArenaMuted.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.onArenaMuted,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Big Icon and Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.arenaGold.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🎁', style: TextStyle(fontSize: 42)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DAILY LOGIN REWARDS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 22,
                        color: AppColors.arenaGold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Claim rewards every consecutive day to earn bonus points & magic spells!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.onArenaMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 7 Day Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rewards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.76,
                ),
                itemBuilder: (context, i) {
                  final spec = _rewards[i];
                  final isTargetDay = spec.day == nextDayToClaim;
                  final isClaimed = !canClaim && spec.day <= nextDayToClaim;
                  final isAvailableToClaim = canClaim && isTargetDay;

                  return _DayRewardCard(
                    spec: spec,
                    isClaimed: isClaimed,
                    isAvailable: isAvailableToClaim,
                    isTarget: isTargetDay,
                  );
                },
              ),

              const SizedBox(height: 20),

              // Action Claim Button
              GestureDetector(
                onTap: (isLoading || !canClaim)
                    ? null
                    : () async {
                        final uid = ref.read(currentUidProvider);
                        if (uid == null) return;
                        ref
                            .read(dailyRewardClaimLoadingProvider.notifier)
                            .state = true;
                        try {
                          final result = await ref
                              .read(userRepositoryProvider)
                              .claimDailyReward(uid: uid);
                          ref
                              .read(soundServiceProvider)
                              .play(AppSound.rankUp);
                          ref
                              .read(hapticServiceProvider)
                              .fire(HapticEvent.win);
                          if (context.mounted) {
                            AppSnackBar.showSuccess(
                              context,
                              result.message,
                            );
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          ref
                              .read(dailyRewardClaimLoadingProvider.notifier)
                              .state = false;
                          if (context.mounted) {
                            AppSnackBar.showError(
                              context,
                              'Failed to claim reward: $e',
                            );
                          }
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: canClaim
                          ? [AppColors.secondary, AppColors.arenaGold]
                          : [
                              AppColors.onArenaMuted.withValues(alpha: 0.2),
                              AppColors.onArenaMuted.withValues(alpha: 0.15)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: canClaim
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppColors.onArenaMuted.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: canClaim
                        ? [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                canClaim
                                    ? Icons.card_giftcard_rounded
                                    : Icons.check_circle_rounded,
                                color: canClaim
                                    ? Colors.white
                                    : AppColors.onArenaMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                canClaim
                                    ? 'CLAIM DAY $nextDayToClaim REWARD'
                                    : 'COME BACK TOMORROW',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 16,
                                  color: canClaim
                                      ? Colors.white
                                      : AppColors.onArenaMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayRewardSpec {
  final int day;
  final int points;
  final String? spellName;
  final IconData spellIcon;

  const _DayRewardSpec({
    required this.day,
    required this.points,
    required this.spellName,
    required this.spellIcon,
  });
}

class _DayRewardCard extends StatelessWidget {
  const _DayRewardCard({
    required this.spec,
    required this.isClaimed,
    required this.isAvailable,
    required this.isTarget,
  });

  final _DayRewardSpec spec;
  final bool isClaimed;
  final bool isAvailable;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    final borderColor = isAvailable
        ? AppColors.arenaGold
        : isClaimed
            ? AppColors.success.withValues(alpha: 0.6)
            : AppColors.onArenaMuted.withValues(alpha: 0.25);

    return Container(
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.secondary.withValues(alpha: 0.18)
            : AppColors.arenaBgBottom,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isAvailable ? 2.0 : 1.2,
        ),
        boxShadow: isAvailable
            ? [
                BoxShadow(
                  color: AppColors.arenaGold.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DAY ${spec.day}',
            style: GoogleFonts.luckiestGuy(
              fontSize: 11,
              color: isAvailable
                  ? AppColors.arenaGold
                  : isClaimed
                      ? AppColors.success
                      : AppColors.onArenaMuted,
              letterSpacing: 0.5,
            ),
          ),
          Icon(
            isClaimed
                ? Icons.check_circle_rounded
                : spec.spellIcon,
            color: isClaimed
                ? AppColors.success
                : isAvailable
                    ? AppColors.arenaGold
                    : AppColors.onArenaMuted,
            size: 24,
          ),
          Text(
            '+${spec.points}',
            style: GoogleFonts.luckiestGuy(
              fontSize: 12,
              color: isAvailable ? Colors.white : AppColors.onArena,
            ),
          ),
          if (spec.spellName != null)
            Text(
              spec.spellName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
        ],
      ),
    );
  }
}
