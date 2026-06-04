import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/user_providers.dart';
import '../../../routes/route_names.dart';

class GameModeSelectScreen extends ConsumerWidget {
  const GameModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(
                  label: 'Same Device',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.groups_outlined,
                        size: 14,
                        color: AppColors.onSurfaceMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LOCAL',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurfaceMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _AnimatedPassPlayCard(
                  onTap: () => context.push(RouteNames.localSetup),
                ),
                const SizedBox(height: 24),
                const _SectionLabel(label: 'Online', trailing: _OnlineBadge()),
                const SizedBox(height: 14),
                _OnlineGrid(
                  onQuickMatch: () =>
                      context.push('${RouteNames.onlineLobby}?mode=quick'),
                  onRanked: () =>
                      context.push('${RouteNames.onlineLobby}?mode=ranked'),
                  onPrivateRoom: () =>
                      context.push('${RouteNames.onlineLobby}?mode=private'),
                  onFriendChallenge: () =>
                      context.push('${RouteNames.onlineLobby}?mode=friend'),
                ),
                const SizedBox(height: 26),
                const _SectionLabel(
                  label: 'Solo Fun',
                  trailing: _SoloBadge(),
                ),
                const SizedBox(height: 12),
                _SoloPlayCard(
                  onTap: () => context.push(RouteNames.flappyGame),
                ),
                const SizedBox(height: 36),
                const _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5E2CA8), // Premium deep purple
                    Color(0xFF321A68), // Rich indigo
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: -40,
                    top: -40,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withValues(alpha: 0.22),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    bottom: -30,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.25),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: 0.08,
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                  const Positioned(
                    left: 32,
                    top: 36,
                    child: _FloatingBannerToken(
                      letter: 'S',
                      color: AppColors.accent,
                      floatOffset: -3.0,
                    ),
                  ),
                  const Positioned(
                    right: 36,
                    top: 20,
                    child: _FloatingBannerToken(
                      letter: 'O',
                      color: AppColors.secondary,
                      floatOffset: 2.0,
                    ),
                  ),
                  const Positioned(
                    right: 88,
                    bottom: 16,
                    child: _FloatingBannerToken(
                      letter: 'S',
                      color: AppColors.primaryContainer,
                      floatOffset: -1.0,
                    ),
                  ),

                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    color: AppColors.secondary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SOS ARENA PRO',
                                    style: GoogleFonts.luckiestGuy(
                                      fontSize: 12,
                                      color: AppColors.secondary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Compete & Win',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 20,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Connect with players worldwide',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.luckiestGuy(
            fontSize: 13,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _OnlineBadge extends ConsumerStatefulWidget {
  const _OnlineBadge();

  @override
  ConsumerState<_OnlineBadge> createState() => _OnlineBadgeState();
}

class _OnlineBadgeState extends ConsumerState<_OnlineBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onlineCountAsync = ref.watch(onlineCountProvider);
    final count = onlineCountAsync.valueOrNull ?? 0;
    final countText = count > 0 ? '$count Online' : 'Online';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _anim,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            countText,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPassPlayCard extends StatefulWidget {
  const _AnimatedPassPlayCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AnimatedPassPlayCard> createState() => _AnimatedPassPlayCardState();
}

class _AnimatedPassPlayCardState extends State<_AnimatedPassPlayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
        );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.player3.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.player3.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.player3.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.groups_2_rounded,
                      color: AppColors.player3,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Pass & Play',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 18,
                                color: AppColors.onSurface,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.player3.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'OFFLINE',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.player3,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Up to 4 players on one screen',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.outline,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoloBadge extends StatelessWidget {
  const _SoloBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sports_esports_rounded,
            size: 13,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 5),
          Text(
            'NO WIFI NEEDED',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoloPlayCard extends StatefulWidget {
  const _SoloPlayCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SoloPlayCard> createState() => _SoloPlayCardState();
}

class _SoloPlayCardState extends State<_SoloPlayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withValues(alpha: 0.14),
                AppColors.tertiary.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.flutter_dash,
                    color: AppColors.secondary,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Flappy Dash',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 18,
                            color: AppColors.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'SOLO',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No one around to challenge right now? Take flight on '
                      'your own and beat your best score!',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.secondary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineGrid extends StatelessWidget {
  const _OnlineGrid({
    required this.onQuickMatch,
    required this.onRanked,
    required this.onPrivateRoom,
    required this.onFriendChallenge,
  });
  final VoidCallback onQuickMatch;
  final VoidCallback onRanked;
  final VoidCallback onPrivateRoom;
  final VoidCallback onFriendChallenge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _AnimatedGridCard(
                imagePath: 'assets/icons/quick_match.png',
                title: 'Quick Match',
                sub: 'Instant random match',
                bgColor: const Color(0xFFEDF4FF),
                borderColor: const Color(0xFFD4E6FF),
                onTap: onQuickMatch,
                floatDuration: const Duration(milliseconds: 2200),
              ),
              const SizedBox(height: 14),
              _AnimatedGridCard(
                imagePath: 'assets/icons/private_room.png',
                title: 'Private Room',
                sub: 'Play with specific code',
                bgColor: const Color(0xFFFAF0FF),
                borderColor: const Color(0xFFF0D5FF),
                onTap: onPrivateRoom,
                floatDuration: const Duration(milliseconds: 2350),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              _AnimatedGridCard(
                imagePath: 'assets/icons/ranked_match.png',
                title: 'Ranked Match',
                sub: 'Climb the global leaderboard',
                bgColor: const Color(0xFFFFF7ED),
                borderColor: const Color(0xFFFFE5D0),
                onTap: onRanked,
                floatDuration: const Duration(milliseconds: 2500),
              ),
              const SizedBox(height: 14),
              _AnimatedGridCard(
                imagePath: 'assets/icons/friend_challenge.png',
                title: 'Friend Challenge',
                sub: 'Invite your online friends',
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFDCF7E9),
                onTap: onFriendChallenge,
                floatDuration: const Duration(milliseconds: 2600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedGridCard extends StatefulWidget {
  const _AnimatedGridCard({
    required this.imagePath,
    required this.title,
    required this.sub,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
    required this.floatDuration,
  });

  final String imagePath;
  final String title;
  final String sub;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;
  final Duration floatDuration;

  @override
  State<_AnimatedGridCard> createState() => _AnimatedGridCardState();
}

class _AnimatedGridCardState extends State<_AnimatedGridCard>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Float animation (up & down)
    _floatController = AnimationController(
      vsync: this,
      duration: widget.floatDuration,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Entrance animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
        );

    // Start entrance animation immediately
    _entryController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Card container
                Container(
                  margin: const EdgeInsets.only(top: 32),
                  width: double.infinity,
                  height: 146,
                  decoration: BoxDecoration(
                    color: widget.bgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: widget.borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: widget.borderColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 48, 12, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 15,
                            color: AppColors.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Center(
                            child: Text(
                              widget.sub,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceMuted,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Overflowing 3D floating Icon
                Positioned(
                  top: 0,
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          _floatAnimation.value - 14,
                        ), // pushed top outside the border
                        child: child,
                      );
                    },
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(widget.imagePath, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingBannerToken extends StatefulWidget {
  const _FloatingBannerToken({
    required this.letter,
    required this.color,
    required this.floatOffset,
  });

  final String letter;
  final Color color;
  final double floatOffset;

  @override
  State<_FloatingBannerToken> createState() => _FloatingBannerTokenState();
}

class _FloatingBannerTokenState extends State<_FloatingBannerToken>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 2000 + (widget.floatOffset.abs() * 300).toInt(),
      ),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -4.0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value + widget.floatOffset),
          child: child,
        );
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.15),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            widget.letter,
            style: GoogleFonts.luckiestGuy(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 1.5,
              color: AppColors.primary.withOpacity(0.2),
            ),
            const SizedBox(width: 10),
            Text(
              '★ UNLEASH THE GAMER WITHIN ★',
              style: GoogleFonts.luckiestGuy(
                fontSize: 10,
                color: AppColors.primary.withOpacity(0.4),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 24,
              height: 1.5,
              color: AppColors.primary.withOpacity(0.2),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Crafted with ❤️ by The SOSO',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SOS ARENA · v1.0.0 · © 2026 soso',
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceMuted.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
