import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/guest_google_prompt_dialog.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/models/app_user.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/friend_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/routes/route_names.dart';
import 'edit_profile_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.uid});
  final String? uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(currentUidProvider);
    final isMe = uid == null || uid == myUid;

    final userAsync = isMe
        ? ref.watch(currentUserProvider)
        : ref.watch(userByUidProvider(uid!));

    return userAsync.when(
      loading: () =>
          isMe ? const AppLoader() : const Scaffold(body: AppLoader()),
      error: (e, _) => isMe
          ? ErrorView(message: '$e')
          : Scaffold(
              appBar: AppBar(title: const Text('Profile')),
              body: ErrorView(message: '$e'),
            ),
      data: (u) {
        if (u == null) return const ErrorView(message: 'No profile');

        final friendships = ref.watch(friendshipsProvider).valueOrNull ?? [];
        final incoming = ref.watch(incomingRequestsProvider).valueOrNull ?? [];
        final outgoing = ref.watch(outgoingRequestsProvider).valueOrNull ?? [];
        final currentUser = ref.watch(currentUserProvider).valueOrNull;

        final isFriend = friendships.any((f) => f.users.contains(u.uid));
        final isOutgoingPending = outgoing.any((r) => r.toUid == u.uid);
        final isIncomingPending = incoming.any((r) => r.fromUid == u.uid);

        final content = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(
            children: [
              _HeroHeader(u: u, isMe: isMe),
              const SizedBox(height: 16),

              if (!isMe && currentUser != null) ...[
                _SocialCard(
                  u: u,
                  isFriend: isFriend,
                  isOutgoingPending: isOutgoingPending,
                  isIncomingPending: isIncomingPending,
                  incoming: incoming,
                  currentUser: currentUser,
                  ref: ref,
                ),
                const SizedBox(height: 16),
              ],

              if (isMe) ...[
                // Shop banner has been moved to the bottom navigation bar
              ],

              _StatsCard(u: u),
              const SizedBox(height: 16),

              if (isMe) ...[
                _LinksCard(context: context, ref: ref, u: u),
                const SizedBox(height: 16),
                _LogoutButton(ref: ref),
              ],
            ],
          ),
        );

        if (!isMe) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: AppColors.bg,
              elevation: 0,
              title: Text(
                '${u.name}\'s Profile',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 18,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
            body: content,
          );
        }

        return content;
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.u, required this.isMe});
  final AppUser u;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.85),
                  AppColors.sColor.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Stack(
              children: [
                ...List.generate(
                  6,
                  (i) => Positioned(
                    left: 20.0 + i * 52,
                    top: 10 + (i % 2) * 22.0,
                    child: Text(
                      i % 2 == 0 ? '★' : '◆',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -36),
            child: Column(
              children: [
                GestureDetector(
                  onTap: isMe
                      ? () => EditProfileDialog.show(context, user: u)
                      : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        // Only draw the plain circular ring when the user has no
                        // purchased frame — an owned frame provides its own border.
                        decoration:
                            (u.avatarFrameColor == null ||
                                u.avatarFrameColor!.isEmpty)
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surface, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              )
                            : null,
                        child: UserAvatar(
                          photoUrl: u.photoUrl,
                          name: u.name,
                          size: 80,
                          online: u.isOnline,
                          frameColor: u.avatarFrameColor,
                        ),
                      ),
                      if (isMe)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryContainer,
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.45),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      u.name,
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 22,
                        color: AppColors.onSurface,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => EditProfileDialog.show(context, user: u),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isMe) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => EditProfileDialog.show(context, user: u),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'EDIT PROFILE',
                            style: GoogleFonts.luckiestGuy(
                              color: AppColors.primary,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (u.customTitle != null && u.customTitle!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary.withOpacity(0.9),
                          AppColors.highlight.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      u.customTitle!.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (u.uniqueId.isNotEmpty) _CopyIdChip(uniqueId: u.uniqueId),
                const SizedBox(height: 4),
                Text(
                  u.email,
                  style: GoogleFonts.outfit(
                    color: AppColors.onSurfaceMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyIdChip extends StatelessWidget {
  const _CopyIdChip({required this.uniqueId});
  final String uniqueId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: uniqueId));
        AppSnackBar.showSuccess(context, 'ID copied to clipboard!');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tag_rounded, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              uniqueId,
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.copy_rounded, color: AppColors.primary, size: 12),
          ],
        ),
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.u,
    required this.isFriend,
    required this.isOutgoingPending,
    required this.isIncomingPending,
    required this.incoming,
    required this.currentUser,
    required this.ref,
  });

  final dynamic u;
  final bool isFriend;
  final bool isOutgoingPending;
  final bool isIncomingPending;
  final List incoming;
  final dynamic currentUser;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'SOCIAL', icon: Icons.people_alt_rounded),
          const SizedBox(height: 12),
          if (isFriend)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Friends!',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AppButton(
                  variant: AppButtonVariant.danger,
                  label: 'Unfriend',
                  onPressed: () async {
                    try {
                      await ref
                          .read(friendRepositoryProvider)
                          .removeFriend(me: currentUser.uid, other: u.uid);
                      if (context.mounted) {
                        AppSnackBar.showSuccess(
                          context,
                          'Removed from friends',
                        );
                      }
                    } catch (e) {
                      if (context.mounted)
                        AppSnackBar.showError(context, e.toString());
                    }
                  },
                ),
              ],
            )
          else if (isOutgoingPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.onSurfaceMuted.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.onSurfaceMuted.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.onSurfaceMuted,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Request Pending...',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else if (isIncomingPending)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.highlight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.highlight.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mail_rounded,
                        color: AppColors.highlight,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Wants to be your friend!',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: AppColors.highlight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AppButton(
                  expanded: true,
                  label: 'Accept Request',
                  icon: Icons.check_circle_rounded,
                  onPressed: () async {
                    try {
                      final req = incoming.firstWhere(
                        (r) => r.fromUid == u.uid,
                      );
                      await ref
                          .read(friendRepositoryProvider)
                          .acceptRequest(req, currentUser.name);
                      ref.read(soundServiceProvider).play(AppSound.friendAccept);
                      if (context.mounted)
                        AppSnackBar.showSuccess(context, 'Request accepted!');
                    } catch (e) {
                      if (context.mounted)
                        AppSnackBar.showError(context, e.toString());
                    }
                  },
                ),
              ],
            )
          else
            AppButton(
              expanded: true,
              icon: Icons.person_add_rounded,
              label: 'Send Friend Request',
              onPressed: () async {
                if (!GuestGooglePromptDialog.allowAction(
                  context,
                  ref,
                  feature: 'Friend Requests',
                  description:
                      'Guest accounts cannot send friend requests. Sign in with Google to connect with other players!',
                )) {
                  return;
                }
                try {
                  await ref
                      .read(friendRepositoryProvider)
                      .sendRequest(
                        fromUid: currentUser.uid,
                        fromName: currentUser.name,
                        fromPhoto: currentUser.photoUrl,
                        toUid: u.uid,
                        toName: u.name,
                        toPhoto: u.photoUrl,
                      );
                  ref.read(soundServiceProvider).play(AppSound.friendSent);
                  if (context.mounted)
                    AppSnackBar.showSuccess(context, 'Friend request sent!');
                } catch (e) {
                  if (context.mounted)
                    AppSnackBar.showError(context, e.toString());
                }
              },
            ),
        ],
      ),
    );
  }
}


class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.u});
  final dynamic u;

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      child: Column(
        children: [
          const _SectionLabel(label: 'STATS', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBubble(
                  label: 'Points',
                  value: '${u.totalPoints}',
                  color: AppColors.sColor,
                  icon: Icons.stars_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBubble(
                  label: 'Matches',
                  value: '${u.matchesPlayed}',
                  color: AppColors.highlight,
                  icon: Icons.sports_esports_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatBubble(
                  label: 'Wins',
                  value: '${u.wins}',
                  color: AppColors.success,
                  icon: Icons.emoji_events_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBubble(
                  label: 'Losses',
                  value: '${u.losses}',
                  color: AppColors.danger,
                  icon: Icons.close_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBubble(
                  label: 'Win %',
                  value: FormatUtils.winRatePct(u.wins, u.matchesPlayed),
                  color: AppColors.oColor,
                  icon: Icons.percent_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.luckiestGuy(
              fontSize: 20,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceMuted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinksCard extends StatelessWidget {
  const _LinksCard({required this.context, required this.ref, required this.u});
  final BuildContext context;
  final WidgetRef ref;
  final AppUser u;

  @override
  Widget build(BuildContext ctx) {
    final links = [
      (Icons.manage_accounts_rounded, 'Edit Profile', null),
      (Icons.history_rounded, 'Match History', RouteNames.matchHistory),
      (Icons.info_outline_rounded, 'About App', RouteNames.about),
      (Icons.privacy_tip_outlined, 'Privacy Policy', RouteNames.privacy),
      (Icons.gavel_rounded, 'Terms & Conditions', RouteNames.terms),
      (Icons.support_agent_rounded, 'Contact Support', RouteNames.contact),
      (Icons.settings_outlined, 'Settings', RouteNames.settings),
    ];

    return _GameCard(
      child: Column(
        children: [
          const _SectionLabel(label: 'MORE', icon: Icons.apps_rounded),
          const SizedBox(height: 8),
          ...links.asMap().entries.map((entry) {
            final i = entry.key;
            final link = entry.value;
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    if (link.$3 == null) {
                      EditProfileDialog.show(context, user: u);
                    } else {
                      context.push(link.$3!);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            link.$1,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            link.$2,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.onSurfaceMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < links.length - 1)
                  Divider(
                    height: 1,
                    color: AppColors.onSurfaceMuted.withOpacity(0.12),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.ref});
  final WidgetRef ref;

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withValues(alpha: 0.08),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'LOG OUT',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: AppColors.danger,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authControllerProvider.notifier).signOut();
                      },
                      child: Text(
                        'Log Out',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 154,
        child: AppButton(
          expanded: true,
          variant: AppButtonVariant.danger,
          icon: Icons.logout_rounded,
          label: 'Log Out',
          onPressed: () => _showConfirmDialog(context),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.14),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.luckiestGuy(
            fontSize: 13,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}
