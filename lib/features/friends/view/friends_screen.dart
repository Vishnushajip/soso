import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  icon: Icons.person_add_alt_1,
                  label: 'Add friend',
                  onPressed: () => context.push(RouteNames.addFriend),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.secondary,
                  icon: Icons.mark_email_unread_outlined,
                  label: 'Requests${pending.isEmpty ? '' : ' (${pending.length})'}',
                  onPressed: () => context.push(RouteNames.friendRequests),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: friendships.when(
              loading: () => const AppLoader(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (list) {
                if (list.isEmpty) {
                  return const SectionCard(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group, color: AppColors.onSurfaceMuted, size: 36),
                          SizedBox(height: 8),
                          Text(
                            'No friends yet — invite someone to a match!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final f = list[i];
                    final otherUid = f.otherUid(me ?? '');
                    final other = ref.watch(userByUidProvider(otherUid)).valueOrNull;
                    return SectionCard(
                      child: Row(
                        children: [
                          UserAvatar(
                            photoUrl: other?.photoUrl,
                            name: other?.name,
                            online: other?.isOnline ?? false,
                            frameColor: other?.avatarFrameColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(other?.name ?? 'Player',
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    if (other?.customTitle != null && other!.customTitle!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          other.customTitle!,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  (other?.isOnline ?? false)
                                      ? 'Online'
                                      : 'Last seen ${FormatUtils.relativeTime(other?.lastSeen)}',
                                  style: TextStyle(
                                    color: (other?.isOnline ?? false)
                                        ? AppColors.success
                                        : AppColors.onSurfaceMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Chat',
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () async {
                              if (me == null) return;
                              final room = await ref
                                  .read(chatRepositoryProvider)
                                  .openDirectChat(me: me, other: otherUid);
                              if (context.mounted) {
                                context.push('${RouteNames.chatRoom}?roomId=${room.id}');
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.person_remove_alt_1_outlined, color: AppColors.danger),
                            onPressed: () async {
                              await ref
                                  .read(friendRepositoryProvider)
                                  .removeFriend(me: me ?? '', other: otherUid);
                            },
                          ),
                        ],
                      ),
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
