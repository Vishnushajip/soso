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
import '../../../providers/user_providers.dart';
import '../../../routes/route_names.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user.when(
      loading: () => const AppLoader(),
      error: (e, _) => ErrorView(message: '$e'),
      data: (u) {
        if (u == null) return const ErrorView(message: 'No profile');
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SectionCard(
                child: Row(
                  children: [
                    UserAvatar(photoUrl: u.photoUrl, name: u.name, size: 60, online: u.isOnline),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          Text(u.email, style: const TextStyle(color: AppColors.onSurfaceMuted)),
                          const SizedBox(height: 4),
                          Text(
                            u.isOnline ? 'Online' : 'Last seen ${FormatUtils.relativeTime(u.lastSeen)}',
                            style: TextStyle(color: u.isOnline ? AppColors.success : AppColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _Stat(label: 'Total Points', value: '${u.totalPoints}', color: AppColors.sColor)),
                        Expanded(child: _Stat(label: 'Matches', value: '${u.matchesPlayed}', color: AppColors.highlight)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(child: _Stat(label: 'Wins', value: '${u.wins}', color: AppColors.success)),
                        Expanded(child: _Stat(label: 'Losses', value: '${u.losses}', color: AppColors.danger)),
                        Expanded(child: _Stat(label: 'Win %', value: FormatUtils.winRatePct(u.wins, u.matchesPlayed), color: AppColors.oColor)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  children: [
                    _Link(label: 'About App', icon: Icons.info_outline, onTap: () => context.push(RouteNames.about)),
                    _Link(label: 'Privacy Policy', icon: Icons.privacy_tip_outlined, onTap: () => context.push(RouteNames.privacy)),
                    _Link(label: 'Terms & Conditions', icon: Icons.gavel, onTap: () => context.push(RouteNames.terms)),
                    _Link(label: 'Contact Support', icon: Icons.support_agent, onTap: () => context.push(RouteNames.contact)),
                    _Link(label: 'Settings', icon: Icons.settings_outlined, onTap: () => context.push(RouteNames.settings)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                expanded: true,
                variant: AppButtonVariant.danger,
                icon: Icons.logout,
                label: 'Log out',
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label; final String value; final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.icon, required this.onTap});
  final String label; final IconData icon; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.sColor),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
      onTap: onTap,
    );
  }
}
