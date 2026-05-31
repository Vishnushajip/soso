import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/chat_room.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/chat_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../routes/route_names.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(myChatRoomsProvider);
    final me = ref.watch(currentUidProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.highlight,
                child: Icon(Icons.public, color: Colors.white),
              ),
              title: const Text('Global Chat', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Open chat for everyone', style: TextStyle(color: AppColors.onSurfaceMuted)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
              onTap: () => context.push(RouteNames.globalChat),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: rooms.when(
              loading: () => const AppLoader(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (list) {
                final direct = list.where((r) => r.type == ChatRoomType.direct).toList();
                if (direct.isEmpty) {
                  return const SectionCard(
                    child: Text(
                      'No private chats yet. Send a friend request first — you can only chat with accepted friends.',
                      style: TextStyle(color: AppColors.onSurfaceMuted),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: direct.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final room = direct[i];
                    final otherUid = me == null ? '' : room.otherUid(me);
                    final other = ref.watch(userByUidProvider(otherUid)).valueOrNull;
                    final unread = room.unreadCount[me] ?? 0;
                    return SectionCard(
                      child: InkWell(
                        onTap: () => context.push('${RouteNames.chatRoom}?roomId=${room.id}'),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              UserAvatar(
                                name: other?.name, photoUrl: other?.photoUrl,
                                online: other?.isOnline ?? false,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(other?.name ?? 'Friend', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(
                                      room.lastMessage ?? 'Say hi 👋',
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.onSurfaceMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    FormatUtils.relativeTime(room.lastMessageAt),
                                    style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  if (unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.sColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
