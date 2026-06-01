import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_providers.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  Future<void> _buyCustomization({
    required BuildContext context,
    required WidgetRef ref,
    required String uid,
    required String type, // 'title' or 'border'
    required String value,
    required int cost,
    required int currentPoints,
  }) async {
    if (currentPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough points! You need $cost pts (you have $currentPoints).'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      await ref.read(userRepositoryProvider).purchaseCustomization(
            uid: uid,
            type: type,
            value: value,
            cost: cost,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully unlocked "$value"!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _buySpell({
    required BuildContext context,
    required WidgetRef ref,
    required String uid,
    required String itemId,
    required String label,
    required int cost,
    required int currentPoints,
  }) async {
    if (currentPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough points! You need $cost pts (you have $currentPoints).'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      await ref.read(userRepositoryProvider).purchaseTool(
            uid: uid,
            itemId: itemId,
            cost: cost,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully purchased 1 $label!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _claimGift({
    required BuildContext context,
    required WidgetRef ref,
    required String uid,
  }) async {
    try {
      await ref.read(userRepositoryProvider).claimFreePoints(uid, 500);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claimed +500 test points! Enjoy shopping! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SOS Shop',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: userAsync.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(message: '$e'),
        data: (u) {
          if (u == null) return const ErrorView(message: 'Profile not found');

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Premium points display banner
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF5E2CA8),
                          Color(0xFF321A68),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5E2CA8).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars,
                          color: Color(0xFFFD9D06),
                          size: 40,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${u.totalPoints} PTS',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Available points balance',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _claimGift(context: context, ref: ref, uid: u.uid),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFD9D06).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFFFD9D06),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  color: Color(0xFFFD9D06),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+500 PTS',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFD9D06),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Glassmorphic navigation tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.onSurfaceMuted,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Customizations'),
                      Tab(text: 'Magic Spells'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Shop items tabs
                Expanded(
                  child: TabBarView(
                    children: [
                      // CUSTOMIZATIONS TAB
                      ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Exclusive Titles',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _ShopItemRow(
                                  title: 'Title: "SOS Legend"',
                                  desc: 'Display an exclusive gold legend badge',
                                  icon: Icons.verified_user,
                                  cost: 150,
                                  color: AppColors.secondary,
                                  active: u.customTitle == 'SOS Legend',
                                  onTap: () => _buyCustomization(
                                    context: context,
                                    ref: ref,
                                    uid: u.uid,
                                    type: 'title',
                                    value: 'SOS Legend',
                                    cost: 150,
                                    currentPoints: u.totalPoints,
                                  ),
                                ),
                                const Divider(height: 24),
                                _ShopItemRow(
                                  title: 'Title: "Tactician"',
                                  desc: 'Display a tactical expert badge',
                                  icon: Icons.military_tech,
                                  cost: 100,
                                  color: AppColors.primaryContainer,
                                  active: u.customTitle == 'Tactician',
                                  onTap: () => _buyCustomization(
                                    context: context,
                                    ref: ref,
                                    uid: u.uid,
                                    type: 'title',
                                    value: 'Tactician',
                                    cost: 100,
                                    currentPoints: u.totalPoints,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Glowing Borders',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _ShopItemRow(
                                  title: 'Frame: Champion Gold',
                                  desc: 'Gold glowing ring around all your avatars',
                                  icon: Icons.workspace_premium,
                                  cost: 300,
                                  color: const Color(0xFFFD9D06),
                                  active: u.avatarFrameColor == 'gold',
                                  onTap: () => _buyCustomization(
                                    context: context,
                                    ref: ref,
                                    uid: u.uid,
                                    type: 'border',
                                    value: 'gold',
                                    cost: 300,
                                    currentPoints: u.totalPoints,
                                  ),
                                ),
                                const Divider(height: 24),
                                _ShopItemRow(
                                  title: 'Frame: Neon Blue',
                                  desc: 'Glow electric blue ring around your avatars',
                                  icon: Icons.blur_circular,
                                  cost: 150,
                                  color: const Color(0xFF3B82F6),
                                  active: u.avatarFrameColor == 'neon_blue',
                                  onTap: () => _buyCustomization(
                                    context: context,
                                    ref: ref,
                                    uid: u.uid,
                                    type: 'border',
                                    value: 'neon_blue',
                                    cost: 150,
                                    currentPoints: u.totalPoints,
                                  ),
                                ),
                                const Divider(height: 24),
                                _ShopItemRow(
                                  title: 'Frame: Emerald',
                                  desc: 'Vibrant forest green avatar boundary ring',
                                  icon: Icons.stars,
                                  cost: 100,
                                  color: const Color(0xFF10B981),
                                  active: u.avatarFrameColor == 'vibrant_green',
                                  onTap: () => _buyCustomization(
                                    context: context,
                                    ref: ref,
                                    uid: u.uid,
                                    type: 'border',
                                    value: 'vibrant_green',
                                    cost: 100,
                                    currentPoints: u.totalPoints,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),

                      // MAGIC SPELLS TAB
                      ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'In-Game Spells',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Purchase powerful magical assistance to use during matches!',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _ShopSpellRow(
                                  title: 'Time Rewind (Undo)',
                                  desc: 'Undo your last move in Local Match',
                                  icon: Icons.undo,
                                  cost: 50,
                                  color: const Color(0xFF8B5CF6),
                                  quantity: u.inventory['undo_move'] ?? 0,
                                  onTap: () => _buySpell(
                                    context: context,
                                    ref: ref,
                                    uid: u.uid,
                                    itemId: 'undo_move',
                                    label: 'Undo Spell',
                                    cost: 50,
                                    currentPoints: u.totalPoints,
                                  ),
                                ),
                                const Divider(height: 24),
                                _ShopSpellRow(
                                  title: 'Cell Eraser (Erase)',
                                  desc: 'Erase any cell on the board during your turn',
                                  icon: Icons.delete_sweep,
                                  cost: 100,
                                  color: const Color(0xFFEF4444),
                                  quantity: u.inventory['erase_cell'] ?? 0,
                                  onTap: () => _buySpell(
                                    context: context,
                                    ref: ref,
                                    uid: u.uid,
                                    itemId: 'erase_cell',
                                    label: 'Erase Spell',
                                    cost: 100,
                                    currentPoints: u.totalPoints,
                                  ),
                                ),
                                const Divider(height: 24),
                                _ShopSpellRow(
                                  title: 'Hint Vision (Hint)',
                                  desc: 'Glow empty slots that form an immediate SOS',
                                  icon: Icons.lightbulb,
                                  cost: 30,
                                  color: const Color(0xFFEAB308),
                                  quantity: u.inventory['hint_vision'] ?? 0,
                                  onTap: () => _buySpell(
                                    context: context,
                                    ref: ref,
                                    uid: u.uid,
                                    itemId: 'hint_vision',
                                    label: 'Hint Vision Spell',
                                    cost: 30,
                                    currentPoints: u.totalPoints,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShopItemRow extends StatelessWidget {
  const _ShopItemRow({
    required this.title,
    required this.desc,
    required this.icon,
    required this.cost,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String title;
  final String desc;
  final IconData icon;
  final int cost;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11)),
      trailing: InkWell(
        onTap: active ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppColors.success : AppColors.secondary,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active) ...[
                const Icon(Icons.check, color: AppColors.success, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Equipped',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
              ] else ...[
                const Icon(Icons.stars, color: AppColors.secondary, size: 12),
                const SizedBox(width: 4),
                Text(
                  '$cost',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopSpellRow extends StatelessWidget {
  const _ShopSpellRow({
    required this.title,
    required this.desc,
    required this.icon,
    required this.cost,
    required this.color,
    required this.quantity,
    required this.onTap,
  });

  final String title;
  final String desc;
  final IconData icon;
  final int cost;
  final Color color;
  final int quantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Owned: $quantity',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(desc, style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11)),
      trailing: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.secondary,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: AppColors.secondary, size: 12),
              const SizedBox(width: 4),
              Text(
                'Buy ($cost)',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
