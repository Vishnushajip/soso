import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
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
                    UserAvatar(
                      photoUrl: u.photoUrl,
                      name: u.name,
                      size: 60,
                      online: u.isOnline,
                      frameColor: u.avatarFrameColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  u.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          
                          // Display Custom Title Badge if active
                          if (u.customTitle != null && u.customTitle!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.secondary, width: 0.5),
                              ),
                              child: Text(
                                u.customTitle!,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 3),
                          
                          // PUBG-Style Unique ID displaying with interactive click-to-copy
                          if (u.uniqueId.isNotEmpty) ...[
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: u.uniqueId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ID copied to clipboard!')),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ID: ${u.uniqueId}',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.copy,
                                      color: AppColors.primary,
                                      size: 11,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(u.email, style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // SOS Shop Dedicated Navigation Card
              SectionCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'SOS Shop',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  subtitle: const Text(
                    'Unlock glowing avatar frames, cool badges, and magical in-game spells!',
                    style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                  onTap: () => context.push(RouteNames.shop),
                ),
              ),
              const SizedBox(height: 12),
              
              // Statistics
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
              
              // Links
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
