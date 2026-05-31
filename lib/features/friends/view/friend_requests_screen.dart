import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../providers/friend_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_providers.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingRequestsProvider);
    final outgoing = ref.watch(outgoingRequestsProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Incoming', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            incoming.when(
              loading: () => const AppLoader(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (list) {
                if (list.isEmpty) {
                  return const SectionCard(child: Text('No incoming requests'));
                }
                return Column(
                  children: [
                    for (final r in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SectionCard(
                          child: Row(
                            children: [
                              UserAvatar(name: r.fromName, photoUrl: r.fromPhoto),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(r.fromName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              IconButton(
                                tooltip: 'Accept',
                                icon: const Icon(Icons.check_circle, color: AppColors.success),
                                onPressed: () async {
                                  await ref.read(friendRepositoryProvider)
                                      .acceptRequest(r, me?.name ?? 'A user');
                                  ref.read(soundServiceProvider).play(AppSound.friendAccept);
                                },
                              ),
                              IconButton(
                                tooltip: 'Reject',
                                icon: const Icon(Icons.cancel, color: AppColors.danger),
                                onPressed: () => ref.read(friendRepositoryProvider).rejectRequest(r),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('Sent', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            outgoing.when(
              loading: () => const AppLoader(),
              error: (e, _) => ErrorView(message: '$e'),
              data: (list) => list.isEmpty
                  ? const SectionCard(child: Text('No pending sent requests'))
                  : Column(
                      children: [
                        for (final r in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SectionCard(
                              child: Row(
                                children: [
                                  const Icon(Icons.outgoing_mail, color: AppColors.onSurfaceMuted),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text('To: ${r.toUid}',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  const Text('Pending', style: TextStyle(color: AppColors.onSurfaceMuted)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

