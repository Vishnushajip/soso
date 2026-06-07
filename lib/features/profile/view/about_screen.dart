import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cartoon_scaffold.dart';
import '../../../providers/app_update_providers.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionLabel = ref.watch(appVersionLabelProvider);
    return CartoonScaffold(
      title: 'About',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GameCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.sColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Env.appName,
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 18,
                          color: AppColors.onSurface,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        versionLabel.isEmpty
                            ? 'Version …'
                            : 'Version $versionLabel',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.onSurfaceMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel(label: 'The Game', icon: Icons.info_rounded),
          const SizedBox(height: 10),
          const GameCard(
            child: InfoText(
              'SOS Arena is a real-time multiplayer SOS game. Place letters, '
              'build SOS combos, and climb the global leaderboard. Challenge '
              'friends, chat between matches, and unlock cosmetics in the shop.',
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel(label: 'Highlights', icon: Icons.star_rounded),
          const SizedBox(height: 10),
          const GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoText('Real-time online matches & local pass-and-play', bullet: true),
                SizedBox(height: 10),
                InfoText('Global rankings by total points', bullet: true),
                SizedBox(height: 10),
                InfoText('Friends, chat & challenges', bullet: true),
                SizedBox(height: 10),
                InfoText('Sound & haptic feedback you can tune in Settings', bullet: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Made with ❤️ for SOS fans',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
