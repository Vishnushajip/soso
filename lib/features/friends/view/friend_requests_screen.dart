import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/route_names.dart';

import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/friend_request.dart';
import '../../../providers/friend_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_providers.dart';

final friendRequestsTabProvider = StateProvider<int>((ref) => 0);

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(friendRequestsTabProvider);
    final incoming = ref.watch(incomingRequestsProvider);
    final outgoing = ref.watch(outgoingRequestsProvider);
    final me = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Friend Requests',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            _buildTabs(context, ref),
            const SizedBox(height: 16),
            Expanded(
              child: activeIndex == 0
                  ? _buildIncomingTab(context, ref, incoming, me)
                  : _buildSentTab(context, ref, outgoing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, WidgetRef ref) {
    final incomingCount = ref.watch(incomingRequestsProvider).valueOrNull?.length ?? 0;
    final outgoingCount = ref.watch(outgoingRequestsProvider).valueOrNull?.length ?? 0;
    final activeIndex = ref.watch(friendRequestsTabProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Incoming',
              count: incomingCount,
              active: activeIndex == 0,
              onTap: () => ref.read(friendRequestsTabProvider.notifier).state = 0,
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Sent',
              count: outgoingCount,
              active: activeIndex == 1,
              onTap: () => ref.read(friendRequestsTabProvider.notifier).state = 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<FriendRequest>> incoming,
    dynamic me,
  ) {
    return incoming.when(
      loading: () => const AppLoader(),
      error: (e, _) => ErrorView(message: '$e'),
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyState(
            icon: Icons.mark_email_read_rounded,
            title: 'All Caught Up!',
            subtitle: 'No incoming friend requests pending.',
          );
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = list[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.push('${RouteNames.profileDetail}?uid=${r.fromUid}');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: UserAvatar(
                        name: r.fromName,
                        photoUrl: r.fromPhoto,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.push('${RouteNames.profileDetail}?uid=${r.fromUid}');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.fromName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Wants to be friends',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ActionButton(
                    icon: Icons.check_rounded,
                    color: AppColors.success,
                    tooltip: 'Accept',
                    onPressed: () async {
                      try {
                        await ref.read(friendRepositoryProvider)
                            .acceptRequest(r, me?.name ?? 'A user');
                        ref.read(soundServiceProvider).play(AppSound.friendAccept);
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
                  _ActionButton(
                    icon: Icons.close_rounded,
                    color: AppColors.danger,
                    tooltip: 'Reject',
                    onPressed: () async {
                      try {
                        await ref.read(friendRepositoryProvider).rejectRequest(r);
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
            );
          },
        );
      },
    );
  }

  Widget _buildSentTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<FriendRequest>> outgoing,
  ) {
    return outgoing.when(
      loading: () => const AppLoader(),
      error: (e, _) => ErrorView(message: '$e'),
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyState(
            icon: Icons.send_and_archive_rounded,
            title: 'No Sent Requests',
            subtitle: 'Try adding friends by typing their name or player ID.',
          );
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = list[i];
            return _SentRequestRow(request: r);
          },
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.sColor],
                )
              : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.luckiestGuy(
                fontSize: 14,
                color: active ? Colors.white : AppColors.onSurfaceMuted,
                letterSpacing: 1.2,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: active ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(
                color: color.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _SentRequestRow extends ConsumerWidget {
  final FriendRequest request;
  const _SentRequestRow({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByUidProvider(request.toUid));

    return userAsync.when(
      data: (user) {
        final displayName = user?.name ?? request.toName ?? 'To: ${request.toUid}';
        final displayPhoto = user?.photoUrl ?? request.toPhoto;
        final displayId = user?.uniqueId ?? '';
        final displayTitle = user?.customTitle ?? '';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.push('${RouteNames.profileDetail}?uid=${request.toUid}');
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.12),
                      width: 1.5,
                    ),
                  ),
                  child: UserAvatar(
                    name: displayName,
                    photoUrl: displayPhoto,
                    size: 44,
                    online: user?.isOnline ?? false,
                    frameColor: user?.avatarFrameColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.push('${RouteNames.profileDetail}?uid=${request.toUid}');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              fontSize: 15,
                            ),
                          ),
                        if (displayTitle.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              displayTitle.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayId.isNotEmpty ? 'ID: $displayId' : 'Pending Request',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceMuted.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Pending',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurfaceMuted,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppColors.danger,
                tooltip: 'Cancel Request',
                onPressed: () async {
                  try {
                    await ref.read(friendRepositoryProvider).rejectRequest(request);
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
        );
      },
      loading: () => const ContainerLoader(),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading details for ${request.toUid}',
                style: GoogleFonts.outfit(color: AppColors.danger, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContainerLoader extends StatelessWidget {
  const ContainerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.luckiestGuy(
                fontSize: 18,
                color: AppColors.onSurface,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
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
}
