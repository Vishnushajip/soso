import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/guest_google_prompt_dialog.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/models/chat_room.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/chat_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/routes/route_names.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(myChatRoomsProvider);
    final me = ref.watch(currentUidProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.18),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          'Chats',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _GlobalChatBanner(),
            const SizedBox(height: 14),
            const _SectionLabel(
              label: 'Direct Messages',
              icon: Icons.chat_bubble_rounded,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: rooms.when(
                loading: () => const AppLoader(),
                error: (e, _) => ErrorView(message: '$e'),
                data: (list) {
                  final direct = list
                      .where((r) => r.type == ChatRoomType.direct)
                      .toList();
                  if (direct.isEmpty) return const _EmptyState();
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: direct.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final room = direct[i];
                      final otherUid = me == null ? '' : room.otherUid(me);
                      final other = ref
                          .watch(userByUidProvider(otherUid))
                          .valueOrNull;
                      final unread = room.unreadCount[me] ?? 0;
                      return _ChatCard(
                        room: room,
                        other: other,
                        unread: unread,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (!GuestGooglePromptDialog.allowAction(
                            context,
                            ref,
                            feature: 'Direct Chat',
                            description: 'Sign in with Google to chat with your friends!',
                          )) {
                            return;
                          }
                          if (me != null) {
                            ref.read(chatRepositoryProvider).markRead(roomId: room.id, uid: me);
                          }
                          context.push(
                            '${RouteNames.chatRoom}?roomId=${room.id}',
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalChatBanner extends ConsumerWidget {
  const _GlobalChatBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (!GuestGooglePromptDialog.allowAction(
          context,
          ref,
          feature: 'Global Chat',
          description: 'Sign in with Google to join the global chat!',
        )) {
          return;
        }
        context.push(RouteNames.globalChat);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.highlight.withOpacity(0.90),
              AppColors.oColor.withOpacity(0.80),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.20), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.highlight.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.public_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Global Chat',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 17,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Open arena — chat with everyone!',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
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
            letterSpacing: 1.5,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
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
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Chats Yet!',
              style: GoogleFonts.luckiestGuy(
                fontSize: 20,
                color: AppColors.onSurface,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a friend first — then you can chat privately!',
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

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.room,
    required this.other,
    required this.unread,
    required this.onTap,
  });

  final ChatRoom room;
  final dynamic other;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOnline = other?.isOnline ?? false;
    final hasUnread = unread > 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasUnread
                ? AppColors.sColor.withOpacity(0.40)
                : isOnline
                ? AppColors.success.withOpacity(0.28)
                : AppColors.primary.withOpacity(0.10),
            width: hasUnread ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: hasUnread
                  ? AppColors.sColor.withOpacity(0.12)
                  : AppColors.primary.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                UserAvatar(
                  name: other?.name,
                  photoUrl: other?.photoUrl,
                  online: isOnline,
                  size: 50,
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
                          other?.name ?? 'Friend',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 15,
                            color: AppColors.onSurface,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (isOnline) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Online',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.lastMessage ?? 'Say hi 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                      color: hasUnread
                          ? AppColors.onSurface
                          : AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  FormatUtils.relativeTime(room.lastMessageAt),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: hasUnread
                        ? AppColors.sColor
                        : AppColors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 5),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.sColor, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sColor.withOpacity(0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 11,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
