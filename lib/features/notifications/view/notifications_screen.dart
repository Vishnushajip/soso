import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../models/notification_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../../providers/repository_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(AppNotificationType type) => switch (type) {
        AppNotificationType.friendRequest => Icons.person_add,
        AppNotificationType.friendAccepted => Icons.handshake,
        AppNotificationType.message => Icons.chat_bubble,
        AppNotificationType.matchInvite => Icons.sports_esports,
        AppNotificationType.matchStarted => Icons.play_arrow,
        AppNotificationType.rankUp => Icons.trending_up,
        AppNotificationType.reward => Icons.card_giftcard,
        AppNotificationType.generic => Icons.notifications,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider);
    final me = ref.watch(currentUidProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: me == null
                ? null
                : () => ref.read(notificationRepositoryProvider).markAllRead(me),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: list.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(message: '$e'),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: SectionCard(child: Text("You're all caught up.", style: TextStyle(color: AppColors.onSurfaceMuted))),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = notifs[i];
              return SectionCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: n.read ? AppColors.surfaceAlt : AppColors.sColor,
                    child: Icon(_iconFor(n.type), color: n.read ? AppColors.onSurfaceMuted : AppColors.bg),
                  ),
                  title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${n.body}\n${FormatUtils.relativeTime(n.createdAt)}',
                    style: const TextStyle(color: AppColors.onSurfaceMuted),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onSurfaceMuted),
                    onPressed: () => ref.read(notificationRepositoryProvider).delete(n.id),
                  ),
                  onTap: () => ref.read(notificationRepositoryProvider).markRead(n.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
