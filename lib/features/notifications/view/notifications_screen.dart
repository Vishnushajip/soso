import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/models/friend_request.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/friend_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/routes/route_names.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider);
    final me = ref.watch(currentUidProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Notifications',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          if (me != null)
            TextButton(
              onPressed: () => ref.read(notificationRepositoryProvider).markAllRead(me),
              child: Text(
                'Mark all read',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: list.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(message: '$e'),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.08),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Caught Up!',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 18,
                        color: AppColors.onSurface,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You're all caught up. No new alerts.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: notifs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = notifs[i];
              return _NotificationItem(notification: n);
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUidProvider);
    final fromUid = notification.data['fromUid'] as String?;
    final requestId = notification.data['requestId'] as String?;

    if (notification.type == AppNotificationType.friendRequest && fromUid != null) {
      final userAsync = ref.watch(userByUidProvider(fromUid));
      final incomingRequests = ref.watch(incomingRequestsProvider).valueOrNull ?? [];
      
      // Find matching FriendRequest
      final friendRequest = incomingRequests.cast<FriendRequest?>().firstWhere(
        (r) => r?.id == requestId || r?.fromUid == fromUid,
        orElse: () => null,
      );

      return userAsync.when(
        data: (user) {
          final name = user?.name ?? 'Someone';
          final photoUrl = user?.photoUrl;
          final isPending = friendRequest != null;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: notification.read
                    ? AppColors.primary.withOpacity(0.05)
                    : AppColors.primary.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(notification.read ? 0.01 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: GestureDetector(
                    onTap: () {
                      ref.read(notificationRepositoryProvider).markRead(notification.id);
                      context.push('${RouteNames.profileDetail}?uid=$fromUid');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: UserAvatar(
                        name: name,
                        photoUrl: photoUrl,
                        size: 44,
                      ),
                    ),
                  ),
                  title: GestureDetector(
                    onTap: () {
                      ref.read(notificationRepositoryProvider).markRead(notification.id);
                      context.push('${RouteNames.profileDetail}?uid=$fromUid');
                    },
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          color: AppColors.onSurface,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          const TextSpan(text: ' sent you a friend request'),
                        ],
                      ),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      FormatUtils.relativeTime(notification.createdAt),
                      style: GoogleFonts.outfit(
                        color: AppColors.onSurfaceMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted, size: 20),
                    onPressed: () => ref.read(notificationRepositoryProvider).delete(notification.id),
                  ),
                  onTap: () {
                    ref.read(notificationRepositoryProvider).markRead(notification.id);
                    context.push('${RouteNames.profileDetail}?uid=$fromUid');
                  },
                ),
                const SizedBox(height: 12),
                if (isPending) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _CompactButton(
                        label: 'View Profile',
                        icon: Icons.person_rounded,
                        color: AppColors.primary,
                        onPressed: () {
                          ref.read(notificationRepositoryProvider).markRead(notification.id);
                          context.push('${RouteNames.profileDetail}?uid=$fromUid');
                        },
                      ),
                      const SizedBox(width: 8),
                      _CompactButton(
                        label: 'Decline',
                        icon: Icons.close_rounded,
                        color: AppColors.danger,
                        onPressed: () async {
                          try {
                            await ref.read(friendRepositoryProvider).rejectRequest(friendRequest);
                            ref.read(notificationRepositoryProvider).markRead(notification.id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _CompactButton(
                        label: 'Accept',
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        onPressed: () async {
                          try {
                            final me = ref.read(currentUserProvider).valueOrNull;
                            await ref.read(friendRepositoryProvider)
                                .acceptRequest(friendRequest, me?.name ?? 'A user');
                            ref.read(soundServiceProvider).play(AppSound.friendAccept);
                            ref.read(notificationRepositoryProvider).markRead(notification.id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Already Friends',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const _NotificationContainerLoader(),
        error: (err, _) => _NotificationFallbackTile(
          notification: notification,
          onTap: () {
            ref.read(notificationRepositoryProvider).markRead(notification.id);
            context.push('${RouteNames.profileDetail}?uid=$fromUid');
          },
        ),
      );
    }

    final senderId = notification.data['senderId'] as String?;
    final roomId = notification.data['roomId'] as String?;

    if (notification.type == AppNotificationType.message && senderId != null && roomId != null) {
      final userAsync = ref.watch(userByUidProvider(senderId));

      return userAsync.when(
        data: (user) {
          final name = user?.name ?? 'Someone';
          final photoUrl = user?.photoUrl;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: notification.read
                    ? AppColors.primary.withOpacity(0.05)
                    : AppColors.primary.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(notification.read ? 0.01 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: GestureDetector(
                onTap: () {
                  ref.read(notificationRepositoryProvider).markRead(notification.id);
                  if (me != null) {
                    ref.read(chatRepositoryProvider).markRead(roomId: roomId, uid: me);
                  }
                  context.push('${RouteNames.chatRoom}?roomId=$roomId');
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: UserAvatar(
                    name: name,
                    photoUrl: photoUrl,
                    size: 44,
                  ),
                ),
              ),
              title: GestureDetector(
                onTap: () {
                  ref.read(notificationRepositoryProvider).markRead(notification.id);
                  if (me != null) {
                    ref.read(chatRepositoryProvider).markRead(roomId: roomId, uid: me);
                  }
                  context.push('${RouteNames.chatRoom}?roomId=$roomId');
                },
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      color: AppColors.onSurface,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const TextSpan(text: ' sent you a message'),
                    ],
                  ),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: AppColors.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FormatUtils.relativeTime(notification.createdAt),
                      style: GoogleFonts.outfit(
                        color: AppColors.onSurfaceMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted, size: 20),
                onPressed: () => ref.read(notificationRepositoryProvider).delete(notification.id),
              ),
              onTap: () {
                ref.read(notificationRepositoryProvider).markRead(notification.id);
                if (me != null) {
                  ref.read(chatRepositoryProvider).markRead(roomId: roomId, uid: me);
                }
                context.push('${RouteNames.chatRoom}?roomId=$roomId');
              },
            ),
          );
        },
        loading: () => const _NotificationContainerLoader(),
        error: (err, _) => _NotificationFallbackTile(
          notification: notification,
          onTap: () {
            ref.read(notificationRepositoryProvider).markRead(notification.id);
            if (me != null) {
              ref.read(chatRepositoryProvider).markRead(roomId: roomId, uid: me);
            }
            context.push('${RouteNames.chatRoom}?roomId=$roomId');
          },
        ),
      );
    }

    // Default general notification
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.06),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: notification.read ? AppColors.surfaceAlt : AppColors.primary.withOpacity(0.12),
          child: Icon(
            _iconFor(notification.type),
            color: notification.read ? AppColors.onSurfaceMuted : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${notification.body}\n${FormatUtils.relativeTime(notification.createdAt)}',
            style: GoogleFonts.outfit(
              color: AppColors.onSurfaceMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted, size: 20),
          onPressed: () => ref.read(notificationRepositoryProvider).delete(notification.id),
        ),
        onTap: () => ref.read(notificationRepositoryProvider).markRead(notification.id),
      ),
    );
  }

  IconData _iconFor(AppNotificationType type) => switch (type) {
        AppNotificationType.friendRequest => Icons.person_add_rounded,
        AppNotificationType.friendAccepted => Icons.handshake_rounded,
        AppNotificationType.message => Icons.chat_bubble_rounded,
        AppNotificationType.matchInvite => Icons.sports_esports_rounded,
        AppNotificationType.matchStarted => Icons.play_arrow_rounded,
        AppNotificationType.rankUp => Icons.trending_up_rounded,
        AppNotificationType.reward => Icons.card_giftcard_rounded,
        AppNotificationType.generic => Icons.notifications_rounded,
      };
}

class _CompactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CompactButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationContainerLoader extends StatelessWidget {
  const _NotificationContainerLoader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

class _NotificationFallbackTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationFallbackTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: notification.read ? AppColors.surfaceAlt : AppColors.primary.withOpacity(0.12),
          child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${notification.body}\n${FormatUtils.relativeTime(notification.createdAt)}',
          style: GoogleFonts.outfit(color: AppColors.onSurfaceMuted, fontSize: 12),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted, size: 20),
          onPressed: () {},
        ),
        onTap: onTap,
      ),
    );
  }
}
