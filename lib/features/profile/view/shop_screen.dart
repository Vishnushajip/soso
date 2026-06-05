import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/customization/avatar_frame.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_providers.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  Future<void> _buyCustomization({
    required BuildContext context,
    required WidgetRef ref,
    required String uid,
    required String type,
    required String value,
    required int cost,
    required int currentPoints,
  }) async {
    if (currentPoints < cost) {
      HapticFeedback.vibrate();
      _showSnack(
        context,
        'Need $cost pts — you have $currentPoints!',
        AppColors.danger,
      );
      return;
    }
    try {
      await ref
          .read(userRepositoryProvider)
          .purchaseCustomization(
            uid: uid,
            type: type,
            value: value,
            cost: cost,
          );
      HapticFeedback.heavyImpact();
      if (context.mounted)
        _showSnack(context, 'Unlocked "$value"! ✨', AppColors.success);
    } catch (e) {
      HapticFeedback.vibrate();
      if (context.mounted) _showSnack(context, '$e', AppColors.danger);
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
      HapticFeedback.vibrate();
      _showSnack(
        context,
        'Need $cost pts — you have $currentPoints!',
        AppColors.danger,
      );
      return;
    }
    try {
      await ref
          .read(userRepositoryProvider)
          .purchaseTool(uid: uid, itemId: itemId, cost: cost);
      HapticFeedback.heavyImpact();
      if (context.mounted)
        _showSnack(
          context,
          '1 $label added to inventory! 🎉',
          AppColors.success,
        );
    } catch (e) {
      HapticFeedback.vibrate();
      if (context.mounted) _showSnack(context, '$e', AppColors.danger);
    }
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.18),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          'SOS Shop',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: _PointsBanner(points: u.totalPoints),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _CartoonTabBar(),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: TabBarView(
                    children: [
                      _CustomizationsTab(
                        u: u,
                        onBuyCustomization: (type, value, cost) =>
                            _buyCustomization(
                              context: context,
                              ref: ref,
                              uid: u.uid,
                              type: type,
                              value: value,
                              cost: cost,
                              currentPoints: u.totalPoints,
                            ),
                      ),
                      _SpellsTab(
                        u: u,
                        onBuySpell: (itemId, label, cost) => _buySpell(
                          context: context,
                          ref: ref,
                          uid: u.uid,
                          itemId: itemId,
                          label: label,
                          cost: cost,
                          currentPoints: u.totalPoints,
                        ),
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

class _PointsBanner extends StatelessWidget {
  const _PointsBanner({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.sColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.stars_rounded,
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
                  '$points PTS',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 26,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Your point balance',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🏆 Earn more',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartoonTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.sColor],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.onSurfaceMuted,
        labelStyle: GoogleFonts.luckiestGuy(fontSize: 13, letterSpacing: 0.8),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        onTap: (_) => HapticFeedback.selectionClick(),
        tabs: const [
          Tab(text: '✨ Customize'),
          Tab(text: '🔮 Spells'),
        ],
      ),
    );
  }
}

class _CustomizationsTab extends StatelessWidget {
  const _CustomizationsTab({required this.u, required this.onBuyCustomization});
  final dynamic u;
  final void Function(String type, String value, int cost) onBuyCustomization;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        _ShopSectionCard(
          label: 'Exclusive Titles',
          icon: Icons.military_tech_rounded,
          iconColor: AppColors.secondary,
          children: [
            for (int i = 0; i < _kTitles.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _CustomizationCard(
                title: _kTitles[i].title,
                desc: _kTitles[i].desc,
                icon: _kTitles[i].icon,
                cost: _kTitles[i].cost,
                color: _kTitles[i].color,
                active: u.customTitle == _kTitles[i].title,
                onTap: () => onBuyCustomization(
                  'title',
                  _kTitles[i].title,
                  _kTitles[i].cost,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        for (final group in _kFrameGroups) ...[
          _ShopSectionCard(
            label: group.label,
            icon: group.icon,
            iconColor: group.color,
            children: [
              for (int i = 0; i < group.frames.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _FrameCard(
                  frame: group.frames[i],
                  active: u.avatarFrameColor == group.frames[i].key,
                  onTap: () => onBuyCustomization(
                    'border',
                    group.frames[i].key,
                    group.frames[i].cost,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// A purchasable display title (stored in `customTitle`).
class _TitleDef {
  const _TitleDef({
    required this.title,
    required this.desc,
    required this.icon,
    required this.cost,
    required this.color,
  });
  final String title;
  final String desc;
  final IconData icon;
  final int cost;
  final Color color;
}

const List<_TitleDef> _kTitles = [
  _TitleDef(
    title: 'Rookie',
    desc: 'Every legend starts somewhere',
    icon: Icons.emoji_people_rounded,
    cost: 500,
    color: AppColors.accent,
  ),
  _TitleDef(
    title: 'Tactician',
    desc: 'A tactical expert badge',
    icon: Icons.military_tech_rounded,
    cost: 2000,
    color: AppColors.primary,
  ),
  _TitleDef(
    title: 'Sharpshooter',
    desc: 'Precision in every move',
    icon: Icons.gps_fixed_rounded,
    cost: 4000,
    color: AppColors.accent,
  ),
  _TitleDef(
    title: 'Strategist',
    desc: 'Always three steps ahead',
    icon: Icons.psychology_rounded,
    cost: 6000,
    color: AppColors.secondary,
  ),
  _TitleDef(
    title: 'Veteran',
    desc: 'Battle-tested and proven',
    icon: Icons.shield_rounded,
    cost: 8000,
    color: AppColors.success,
  ),
  _TitleDef(
    title: 'Prodigy',
    desc: 'A rare natural talent',
    icon: Icons.auto_awesome_rounded,
    cost: 12000,
    color: AppColors.primary,
  ),
  _TitleDef(
    title: 'Mastermind',
    desc: 'The architect of victory',
    icon: Icons.lightbulb_rounded,
    cost: 16000,
    color: AppColors.secondary,
  ),
  _TitleDef(
    title: 'Grandmaster',
    desc: 'Among the very best',
    icon: Icons.emoji_events_rounded,
    cost: 22000,
    color: AppColors.highlight,
  ),
  _TitleDef(
    title: 'Warlord',
    desc: 'Conqueror of the board',
    icon: Icons.local_fire_department_rounded,
    cost: 28000,
    color: AppColors.danger,
  ),
  _TitleDef(
    title: 'Overlord',
    desc: 'Rule the arena with an iron fist',
    icon: Icons.dark_mode_rounded,
    cost: 35000,
    color: AppColors.primary,
  ),
  _TitleDef(
    title: 'SOS Legend',
    desc: 'An exclusive gold legend badge',
    icon: Icons.verified_user_rounded,
    cost: 50000,
    color: AppColors.secondary,
  ),
  _TitleDef(
    title: 'Mythic Ascendant',
    desc: 'The ultimate title — beyond legendary',
    icon: Icons.workspace_premium_rounded,
    cost: 80000,
    color: AppColors.highlight,
  ),
];

/// A shop section grouping related frames.
class _FrameGroup {
  const _FrameGroup({
    required this.label,
    required this.icon,
    required this.color,
    required this.frames,
  });
  final String label;
  final IconData icon;
  final Color color;
  final List<AvatarFrame> frames;
}

/// Frames whose [AvatarFrame.key] is one of [keys], in catalog order.
List<AvatarFrame> _frames(List<String> keys) =>
    kAvatarFrames.where((f) => keys.contains(f.key)).toList();

final List<_FrameGroup> _kFrameGroups = [
  _FrameGroup(
    label: 'Classic Rings',
    icon: Icons.circle_outlined,
    color: AppColors.accent,
    frames: _frames([
      'sky_blue',
      'neon_blue',
      'vibrant_green',
      'crimson_red',
      'sunset_orange',
    ]),
  ),
  _FrameGroup(
    label: 'Gemmed Frames',
    icon: Icons.diamond_outlined,
    color: AppColors.primary,
    frames: _frames(['cyan_teal', 'lime_punch', 'tangerine', 'royal_purple']),
  ),
  _FrameGroup(
    label: 'Jeweled Frames',
    icon: Icons.diamond_rounded,
    color: AppColors.secondary,
    frames: _frames(['bubblegum', 'rose_quartz', 'midnight_blue']),
  ),
  _FrameGroup(
    label: 'Royal Frames',
    icon: Icons.auto_awesome_rounded,
    color: AppColors.success,
    frames: _frames(['emerald_flame', 'toxic_green', 'galaxy_indigo']),
  ),
  _FrameGroup(
    label: 'Legendary Gold',
    icon: Icons.workspace_premium_rounded,
    color: AppColors.highlight,
    frames: _frames(['gold', 'molten_lava', 'celestial_prism']),
  ),
];

/// A purchase card that previews the actual frame shape + glow.
class _FrameCard extends StatelessWidget {
  const _FrameCard({
    required this.frame,
    required this.active,
    required this.onTap,
  });
  final AvatarFrame frame;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = frame.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.08) : AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? color.withOpacity(0.45)
              : AppColors.primary.withOpacity(0.10),
          width: active ? 2 : 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Live preview painted with the SAME painter used on real avatars,
          // so the shop shows exactly what the player will get.
          SizedBox(
            width: 58,
            height: 58,
            child: Center(
              child: SizedBox(
                width: 40 * kFrameScale,
                height: 40 * kFrameScale,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: const Size(40 * kFrameScale, 40 * kFrameScale),
                      painter: AvatarFramePainter(frame),
                    ),
                    ClipPath(
                      clipper: ShapeBorderClipper(
                        shape: frameShapeBorder(frame.shape),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        color: color.withOpacity(0.18),
                        child: Icon(frame.icon, color: color, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        frame.title,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 14,
                          color: AppColors.onSurface,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        frame.shapeLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  frame.desc,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: active
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    onTap();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: active
                    ? null
                    : LinearGradient(colors: [color, color.withOpacity(0.75)]),
                color: active ? AppColors.success.withOpacity(0.12) : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? AppColors.success.withOpacity(0.4)
                      : color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: active
                    ? null
                    : [
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: active
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Owned',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 11,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${frame.cost}',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpellsTab extends StatelessWidget {
  const _SpellsTab({required this.u, required this.onBuySpell});
  final dynamic u;
  final void Function(String itemId, String label, int cost) onBuySpell;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.18),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use spells during matches for a tactical edge!',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ShopSectionCard(
          label: 'Magic Spells',
          icon: Icons.auto_fix_high_rounded,
          iconColor: AppColors.sColor,
          children: [
            _SpellCard(
              title: 'Time Rewind',
              desc: 'Undo your last move in Local Match',
              emoji: '⏪',
              cost: 50,
              color: AppColors.primary,
              quantity: u.inventory['undo_move'] ?? 0,
              onTap: () => onBuySpell('undo_move', 'Undo Spell', 50),
            ),
            const SizedBox(height: 10),
            _SpellCard(
              title: 'Cell Eraser',
              desc: 'Erase any cell on the board during your turn',
              emoji: '🧹',
              cost: 100,
              color: AppColors.danger,
              quantity: u.inventory['erase_cell'] ?? 0,
              onTap: () => onBuySpell('erase_cell', 'Erase Spell', 100),
            ),
            const SizedBox(height: 10),
            _SpellCard(
              title: 'Hint Vision',
              desc: 'Glow empty slots that form an immediate SOS',
              emoji: '💡',
              cost: 30,
              color: AppColors.highlight,
              quantity: u.inventory['hint_vision'] ?? 0,
              onTap: () => onBuySpell('hint_vision', 'Hint Vision Spell', 30),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShopSectionCard extends StatelessWidget {
  const _ShopSectionCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.children,
  });
  final String label;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 14,
                  color: iconColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor.withOpacity(0.3), Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _CustomizationCard extends StatelessWidget {
  const _CustomizationCard({
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.08) : AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? color.withOpacity(0.45)
              : AppColors.primary.withOpacity(0.10),
          width: active ? 2 : 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.28), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 14,
                    color: AppColors.onSurface,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: active
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    onTap();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: active
                    ? null
                    : LinearGradient(colors: [color, color.withOpacity(0.75)]),
                color: active ? AppColors.success.withOpacity(0.12) : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? AppColors.success.withOpacity(0.4)
                      : color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: active
                    ? null
                    : [
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: active
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Owned',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 11,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$cost',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpellCard extends StatelessWidget {
  const _SpellCard({
    required this.title,
    required this.desc,
    required this.emoji,
    required this.cost,
    required this.color,
    required this.quantity,
    required this.onTap,
  });
  final String title;
  final String desc;
  final String emoji;
  final int cost;
  final Color color;
  final int quantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.10),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.28), width: 1.5),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 13,
                        color: AppColors.onSurface,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: quantity > 0
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.onSurfaceMuted.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: quantity > 0
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.onSurfaceMuted.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'x$quantity',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 10,
                          color: quantity > 0
                              ? AppColors.success
                              : AppColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.75)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$cost',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
