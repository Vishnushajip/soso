import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/user_providers.dart';
import '../../../routes/route_names.dart';

class GameModeSelectScreen extends ConsumerWidget {
  const GameModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi ${user?.name ?? 'Player'} 👋',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick a mode and start a match.',
                  style: TextStyle(color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ModeTile(
            icon: Icons.bolt,
            color: AppColors.sColor,
            title: 'Quick Match',
            subtitle: 'Get matched with a random opponent online',
            onTap: () => context.push('${RouteNames.onlineLobby}?mode=quick'),
          ),
          const SizedBox(height: 12),
          _ModeTile(
            icon: Icons.emoji_events_outlined,
            color: AppColors.oColor,
            title: 'Ranked Match',
            subtitle: 'Compete for points on the leaderboards',
            onTap: () => context.push('${RouteNames.onlineLobby}?mode=ranked'),
          ),
          const SizedBox(height: 12),
          _ModeTile(
            icon: Icons.vpn_key_outlined,
            color: AppColors.highlight,
            title: 'Private Room',
            subtitle: 'Create or join a room with a code',
            onTap: () => context.push('${RouteNames.onlineLobby}?mode=private'),
          ),
          const SizedBox(height: 12),
          _ModeTile(
            icon: Icons.group,
            color: AppColors.success,
            title: 'Friend Challenge',
            subtitle: 'Invite a friend to a match',
            onTap: () => context.push('${RouteNames.onlineLobby}?mode=friend'),
          ),
          const SizedBox(height: 12),
          _ModeTile(
            icon: Icons.phone_android,
            color: AppColors.player3,
            title: 'Local Multiplayer',
            subtitle: '2–4 players on the same device',
            onTap: () => context.push(RouteNames.localSetup),
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SectionCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}
