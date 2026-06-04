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
import '../../../providers/auth_providers.dart';
import '../../../providers/friend_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../routes/route_names.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendships = ref.watch(friendshipsProvider);
    final pending = ref.watch(incomingRequestsProvider).valueOrNull ?? const [];
    final me = ref.watch(currentUidProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionRow(pending: pending.length),
          const SizedBox(height: 14),
          Expanded(
            child: friendships.when(
              loading: () => const AppLoader(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (list) {
                if (list.isEmpty) return const _EmptyState();
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final f = list[i];
                    final otherUid = f.otherUid(me ?? '');
                    final other = ref
                        .watch(userByUidProvider(otherUid))
                        .valueOrNull;
                    return _FriendCard(
                      other: other,
                      otherUid: otherUid,
                      me: me,
                      ref: ref,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.pending});
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            label: 'Add Friend',
            icon: Icons.person_add_rounded,
            color: AppColors.primary,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(RouteNames.addFriend);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            label: pending > 0 ? 'Requests ($pending)' : 'Requests',
            icon: Icons.mark_email_unread_rounded,
            color: pending > 0 ? AppColors.secondary : AppColors.onSurfaceMuted,
            hasBadge: pending > 0,
            badgeCount: pending,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(RouteNames.friendRequests);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.hasBadge = false,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool hasBadge;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.30), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 20),
                if (hasBadge)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 13,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.18),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.group_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Friends Yet!',
              style: GoogleFonts.luckiestGuy(
                fontSize: 20,
                color: AppColors.onSurface,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Invite someone to a match and build your squad!',
              textAlign: TextAlign.center,
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
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.other,
    required this.otherUid,
    required this.me,
    required this.ref,
  });

  final dynamic other;
  final String otherUid;
  final String? me;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isOnline = other?.isOnline ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? AppColors.success.withOpacity(0.30)
              : AppColors.primary.withOpacity(0.10),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? AppColors.success.withOpacity(0.08)
                : AppColors.primary.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                UserAvatar(
                  photoUrl: other?.photoUrl,
                  name: other?.name,
                  online: isOnline,
                  frameColor: other?.avatarFrameColor,
                  size: 48,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
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
                          other?.name ?? 'Player',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 15,
                            color: AppColors.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (other?.customTitle != null &&
                          other!.customTitle!.isNotEmpty) ...[
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
                            other!.customTitle!,
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
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppColors.success
                              : AppColors.onSurfaceMuted.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline
                            ? 'Online now'
                            : 'Last seen ${FormatUtils.relativeTime(other?.lastSeen)}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOnline
                              ? AppColors.success
                              : AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoundIconBtn(
                  icon: Icons.sports_esports_rounded,
                  color: AppColors.secondary,
                  tooltip: 'Challenge',
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    if (me == null) return;
                    final myUser = ref.read(currentUserProvider).valueOrNull;
                    if (myUser == null) return;
                    
                    try {
                      await ref.read(chatRepositoryProvider).sendChallenge(
                        me: me!,
                        myName: myUser.name,
                        otherUid: otherUid,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Challenge sent!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to send challenge: $e')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 6),
                _RoundIconBtn(
                  icon: Icons.chat_bubble_rounded,
                  color: AppColors.primary,
                  tooltip: 'Chat',
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    if (me == null) return;
                    final room = await ref
                        .read(chatRepositoryProvider)
                        .openDirectChat(me: me!, other: otherUid);
                    if (context.mounted)
                      context.push('${RouteNames.chatRoom}?roomId=${room.id}');
                  },
                ),
                const SizedBox(width: 6),
                _RoundIconBtn(
                  icon: Icons.person_remove_rounded,
                  color: AppColors.danger,
                  tooltip: 'Remove',
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await ref
                        .read(friendRepositoryProvider)
                        .removeFriend(me: me ?? '', other: otherUid);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
