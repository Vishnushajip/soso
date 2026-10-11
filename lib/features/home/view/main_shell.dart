import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soso/features/update/view/update_dialog.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/chat_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/guest_google_prompt_dialog.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../rewards/view/daily_reward_dialog.dart';



class MainShell extends ConsumerWidget {
  const MainShell({
    super.key,
    this.navigationShell,
    this.child,
  });

  final StatefulNavigationShell? navigationShell;
  final Widget? child;

  static const _tabs = [
    _TabData(
      path: RouteNames.home,
      label: 'Play',
      icon: Icons.sports_esports_outlined,
      activeIcon: Icons.sports_esports_rounded,
    ),
    _TabData(
      path: RouteNames.friends,
      label: 'Friends',
      icon: Icons.group_outlined,
      activeIcon: Icons.group_rounded,
    ),
    _TabData(
      path: RouteNames.shop,
      label: 'Shop',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
    ),
    _TabData(
      path: RouteNames.leaderboard,
      label: 'Ranks',
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events_rounded,
    ),
    _TabData(
      path: RouteNames.profile,
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  int _indexOfLocation(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(soundServiceProvider).startBgm();
    });

    final selected = navigationShell?.currentIndex ??
        _indexOfLocation(GoRouterState.of(context).matchedLocation);

    final unread = ref.watch(
      unreadNotificationsCountProvider.select((v) => v.valueOrNull ?? 0),
    );
    final unreadMessages = ref.watch(unreadMessagesCountProvider);
    final name = ref.watch(
      currentUserProvider.select((u) => u.valueOrNull?.name ?? ''),
    );
    final photoUrl = ref.watch(
      currentUserProvider.select((u) => u.valueOrNull?.photoUrl),
    );
    final frameColor = ref.watch(
      currentUserProvider.select((u) => u.valueOrNull?.avatarFrameColor),
    );
    final points = ref.watch(
      currentUserProvider.select((u) => u.valueOrNull?.totalPoints ?? 0),
    );
    final streak = ref.watch(
      currentUserProvider.select((u) => u.valueOrNull?.dailyStreak ?? 0),
    );
    final canClaim = ref.watch(
      currentUserProvider.select((u) => u.valueOrNull?.canClaimDailyReward ?? false),
    );
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    final haptic = ref.read(hapticServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 10,
        title: _AppBarTitle(
          name: name,
          firstLetter: firstLetter,
          selectedLabel: _tabs[selected].label,
          photoUrl: photoUrl,
          frameColor: frameColor,
        ),
        actions: [
          _StreakPill(
            streak: streak,
            canClaim: canClaim,
            onTap: () {
              haptic.fire(HapticEvent.tap);
              ref.read(soundServiceProvider).play(AppSound.buttonClick);
              DailyRewardDialog.show(context);
            },
          ),
          const SizedBox(width: 4),
          _PointsPill(points: points),
          const SizedBox(width: 4),
          _NotificationBell(
            unread: unread,
            onTap: () {
              haptic.fire(HapticEvent.tap);
              ref.read(soundServiceProvider).play(AppSound.buttonClick);
              context.push(RouteNames.notifications);
            },
          ),
          const SizedBox(width: 4),
          _MessagesButton(
            unread: unreadMessages,
            onTap: () {
              haptic.fire(HapticEvent.tap);
              ref.read(soundServiceProvider).play(AppSound.buttonClick);
              if (!GuestGooglePromptDialog.allowAction(
                context,
                ref,
                feature: 'Messages & Chat',
                description:
                    'Guest accounts cannot use chat. Sign in with Google to message friends and chat in real-time!',
              )) {
                return;
              }
              context.push(RouteNames.chatList);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppUpdateGate(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: navigationShell ?? child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: _GameNavBar(
          selected: selected,
          tabs: _tabs,
          onTap: (i) {
            haptic.fire(HapticEvent.selection);
            if (navigationShell != null) {
              navigationShell!.goBranch(
                i,
                initialLocation: i == navigationShell!.currentIndex,
              );
            } else {
              if (i == selected) return;
              context.go(_tabs[i].path);
            }
          },
        ),
      ),
    );
  }
}

class _TabData {
  const _TabData({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({
    required this.name,
    required this.firstLetter,
    required this.selectedLabel,
    this.photoUrl,
    this.frameColor,
  });

  final String name;
  final String firstLetter;
  final String selectedLabel;
  final String? photoUrl;
  final String? frameColor;

  IconData _subIcon() {
    switch (selectedLabel) {
      case 'Play':
        return Icons.sports_esports_rounded;
      case 'Friends':
        return Icons.group_rounded;
      case 'Shop':
        return Icons.storefront_rounded;
      case 'Ranks':
        return Icons.emoji_events_rounded;
      default:
        return Icons.account_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AvatarBubble(
          firstLetter: firstLetter,
          photoUrl: photoUrl,
          name: name,
          frameColor: frameColor,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.isNotEmpty ? name : 'Player',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 14,
                  color: AppColors.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_subIcon(), size: 13, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    selectedLabel == 'Play' ? 'Arena' : selectedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarBubble extends StatefulWidget {
  const _AvatarBubble({
    required this.firstLetter,
    this.photoUrl,
    this.name,
    this.frameColor,
  });
  final String firstLetter;
  final String? photoUrl;
  final String? name;
  final String? frameColor;

  @override
  State<_AvatarBubble> createState() => _AvatarBubbleState();
}

class _AvatarBubbleState extends State<_AvatarBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.25, end: 0.60).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableMotion) {
      return _buildContent(1.0, 0.35);
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) =>
          _buildContent(_scaleAnimation.value, _glowAnimation.value),
    );
  }

  Widget _buildContent(double scale, double glowOpacity) {
    final hasPhoto = widget.photoUrl != null && widget.photoUrl!.isNotEmpty;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.sColor],
          ),
          border: Border.all(color: AppColors.secondary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: glowOpacity),
              blurRadius: 10 + (glowOpacity * 6),
              spreadRadius: glowOpacity * 1.2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: hasPhoto
              ? UserAvatar(
                  photoUrl: widget.photoUrl,
                  name: widget.name,
                  size: 36,
                  frameColor: widget.frameColor,
                )
              : Text(
                  widget.firstLetter,
                  style: GoogleFonts.luckiestGuy(
                    color: Colors.white,
                    fontSize: 17,
                    letterSpacing: 0,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PointsPill extends StatefulWidget {
  const _PointsPill({required this.points});
  final int points;

  @override
  State<_PointsPill> createState() => _PointsPillState();
}

class _PointsPillState extends State<_PointsPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 11),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.points}',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 13,
                      color: AppColors.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (!disableMotion)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, _) {
                        return FractionallySizedBox(
                          alignment: Alignment(_shimmerAnimation.value, 0.0),
                          widthFactor: 0.45,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.35),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({
    required this.streak,
    required this.canClaim,
    required this.onTap,
  });

  final int streak;
  final bool canClaim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 11),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: canClaim
              ? const Color(0xFFFF6D00).withValues(alpha: 0.18)
              : AppColors.arenaGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canClaim
                ? const Color(0xFFFF6D00)
                : AppColors.arenaGold.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: canClaim
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              canClaim ? '🔥' : '⚡',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: GoogleFonts.luckiestGuy(
                fontSize: 13,
                color: canClaim ? const Color(0xFFFFAB00) : Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
            if (canClaim) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3D00),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatefulWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
    required this.badgeColors,
    required this.accentColor,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;
  final List<Color> badgeColors;
  final Color accentColor;

  @override
  State<_HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<_HeaderActionButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late final AnimationController _badgePulse;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _badgePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _badgePulse, curve: Curves.easeInOut),
    );
    if (widget.badgeCount > 0) {
      _badgePulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _HeaderActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badgeCount > 0 && !_badgePulse.isAnimating) {
      _badgePulse.repeat(reverse: true);
    } else if (widget.badgeCount == 0 && _badgePulse.isAnimating) {
      _badgePulse.stop();
      _badgePulse.value = 0.0;
    }
  }

  @override
  void dispose() {
    _badgePulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasBadge = widget.badgeCount > 0;
    final disableMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
              scale: _isPressed ? 0.88 : (_isHovered ? 1.05 : 1.0),
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOutCubic,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceContainerLowest,
                      _isHovered ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: hasBadge
                        ? widget.accentColor.withValues(alpha: 0.38)
                        : AppColors.primary.withValues(alpha: _isHovered ? 0.25 : 0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasBadge
                          ? widget.accentColor.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    widget.icon,
                    if (hasBadge)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: AnimatedBuilder(
                          animation: _badgePulse,
                          builder: (context, child) {
                            final scale = (!disableMotion) ? _pulseScale.value : 1.0;
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.5,
                              vertical: 1.5,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.badgeColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.bg,
                                width: 1.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.badgeColors.first.withValues(alpha: 0.55),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.badgeCount > 99
                                  ? '99+'
                                  : '${widget.badgeCount}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatefulWidget {
  const _NotificationBell({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _chimeController;
  late final Animation<double> _swingAnimation;

  @override
  void initState() {
    super.initState();
    _chimeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _swingAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -0.16)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.16, end: 0.14)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.14, end: -0.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.08, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 25),
    ]).animate(_chimeController);

    if (widget.unread > 0) {
      _chimeController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unread > 0 && !_chimeController.isAnimating) {
      _chimeController.repeat();
    } else if (widget.unread == 0 && _chimeController.isAnimating) {
      _chimeController.stop();
      _chimeController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _chimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return _HeaderActionButton(
      tooltip: 'Notifications',
      onTap: widget.onTap,
      badgeCount: widget.unread,
      badgeColors: const [Color(0xFFFF3B30), Color(0xFFDC2626)],
      accentColor: const Color(0xFFFFB300),
      icon: AnimatedBuilder(
        animation: _chimeController,
        builder: (context, child) {
          final angle =
              (!disableMotion && widget.unread > 0) ? _swingAnimation.value : 0.0;
          return Transform.rotate(
            angle: angle,
            alignment: const Alignment(0.0, -0.6),
            child: child,
          );
        },
        child: SvgPicture.asset(
          'assets/icons/bell_flaticon.svg',
          width: 22,
          height: 22,
        ),
      ),
    );
  }
}

class _MessagesButton extends StatefulWidget {
  const _MessagesButton({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  State<_MessagesButton> createState() => _MessagesButtonState();
}

class _MessagesButtonState extends State<_MessagesButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
    ]).animate(_pulseController);

    if (widget.unread > 0) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MessagesButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unread > 0 && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (widget.unread == 0 && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return _HeaderActionButton(
      tooltip: 'Messages',
      onTap: widget.onTap,
      badgeCount: widget.unread,
      badgeColors: const [Color(0xFF0091EA), Color(0xFF2979FF)],
      accentColor: const Color(0xFF0284C7),
      icon: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = (!disableMotion && widget.unread > 0)
              ? _scaleAnimation.value
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: SvgPicture.asset(
          'assets/icons/chat_flaticon.svg',
          width: 22,
          height: 22,
        ),
      ),
    );
  }
}

class _GameNavBar extends StatelessWidget {
  const _GameNavBar({
    required this.selected,
    required this.tabs,
    required this.onTap,
  });
  final int selected;
  final List<_TabData> tabs;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom, top: 4),
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Row(
              children: List.generate(tabs.length, (i) {
                return Expanded(
                  child: _NavItem(
                    tab: tabs[i],
                    isSelected: i == selected,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _TabData tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? AppColors.primary
        : (_isHovered ? AppColors.onSurface : AppColors.onSurfaceMuted);
    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.tab.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  width: widget.isSelected ? 26 : 0,
                  height: widget.isSelected ? 3.5 : 0,
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
                AnimatedScale(
                  scale: _isPressed
                      ? 0.92
                      : (widget.isSelected ? 1.18 : (_isHovered ? 1.08 : 1.0)),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    widget.isSelected
                        ? widget.tab.activeIcon
                        : widget.tab.icon,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight:
                        widget.isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: color,
                    letterSpacing: widget.isSelected ? 0.3 : 0,
                  ),
                  child: Text(widget.tab.label),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

