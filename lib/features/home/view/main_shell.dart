import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/notification_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../routes/route_names.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabData(
      path: RouteNames.home,
      label: 'Play',
      iconUrl: 'https://img.icons8.com/3d-fluency/94/controller.png',
      iconUrlActive: 'https://img.icons8.com/3d-fluency/94/controller.png',
    ),
    _TabData(
      path: RouteNames.friends,
      label: 'Friends',
      iconUrl: 'https://img.icons8.com/3d-fluency/94/group.png',
      iconUrlActive: 'https://img.icons8.com/3d-fluency/94/group.png',
    ),
    _TabData(
      path: RouteNames.chatList,
      label: 'Chats',
      iconUrl: 'https://img.icons8.com/3d-fluency/94/chat.png',
      iconUrlActive: 'https://img.icons8.com/3d-fluency/94/chat.png',
    ),
    _TabData(
      path: RouteNames.leaderboard,
      label: 'Ranks',
      iconUrl: 'https://img.icons8.com/3d-fluency/94/trophy.png',
      iconUrlActive: 'https://img.icons8.com/3d-fluency/94/trophy.png',
    ),
    _TabData(
      path: RouteNames.profile,
      label: 'Profile',
      iconUrl: 'https://img.icons8.com/3d-fluency/94/user-male-circle.png',
      iconUrlActive:
          'https://img.icons8.com/3d-fluency/94/user-male-circle.png',
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
    final location = GoRouterState.of(context).matchedLocation;
    final selected = _indexOfLocation(location);
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final points = user?.totalPoints ?? 0;
    final firstLetter = (user?.name.isNotEmpty == true)
        ? user!.name[0].toUpperCase()
        : 'P';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: _AppBarTitle(
          user: user,
          firstLetter: firstLetter,
          selectedLabel: _tabs[selected].label,
        ),
        actions: [
          _PointsPill(points: points),
          _NotificationBell(
            unread: unread,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(RouteNames.notifications);
            },
          ),
          _SettingsButton(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(RouteNames.settings);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: child,
      bottomNavigationBar: _GameNavBar(
        selected: selected,
        tabs: _tabs,
        onTap: (i) {
          if (i == selected) return;
          HapticFeedback.selectionClick();
          context.go(_tabs[i].path);
        },
      ),
    );
  }
}

class _TabData {
  const _TabData({
    required this.path,
    required this.label,
    required this.iconUrl,
    required this.iconUrlActive,
  });
  final String path;
  final String label;
  final String iconUrl;
  final String iconUrlActive;
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({
    required this.user,
    required this.firstLetter,
    required this.selectedLabel,
  });

  final dynamic user;
  final String firstLetter;
  final String selectedLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AvatarBubble(firstLetter: firstLetter),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user?.name ?? 'Player',
              style: GoogleFonts.luckiestGuy(
                fontSize: 15,
                color: AppColors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  selectedLabel == 'Play'
                      ? 'https://img.icons8.com/3d-fluency/94/controller.png'
                      : selectedLabel == 'Friends'
                      ? 'https://img.icons8.com/3d-fluency/94/group.png'
                      : selectedLabel == 'Chats'
                      ? 'https://img.icons8.com/3d-fluency/94/chat.png'
                      : selectedLabel == 'Ranks'
                      ? 'https://img.icons8.com/3d-fluency/94/trophy.png'
                      : 'https://img.icons8.com/3d-fluency/94/user-male-circle.png',
                  width: 12,
                  height: 12,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 3),
                Text(
                  selectedLabel == 'Play' ? 'Arena' : selectedLabel,
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
      ],
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.firstLetter});
  final String firstLetter;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: GoogleFonts.luckiestGuy(
            color: Colors.white,
            fontSize: 17,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 11),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            'https://img.icons8.com/3d-fluency/94/star.png',
            width: 16,
            height: 16,
            errorBuilder: (_, _, _) => const Icon(
              Icons.stars_rounded,
              color: AppColors.secondary,
              size: 15,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$points',
            style: GoogleFonts.luckiestGuy(
              fontSize: 13,
              color: AppColors.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.network(
              'https://img.icons8.com/3d-fluency/94/appointment-reminders.png',
              width: 28,
              height: 28,
              errorBuilder: (_, _, _) => Icon(
                Icons.notifications_rounded,
                color: AppColors.onSurface.withOpacity(0.75),
                size: 24,
              ),
            ),
            if (unread > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.bg, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Image.network(
          'https://img.icons8.com/3d-fluency/94/settings.png',
          width: 28,
          height: 28,
          errorBuilder: (_, _, _) => Icon(
            Icons.settings_rounded,
            color: AppColors.onSurface.withOpacity(0.75),
            size: 24,
          ),
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
            color: AppColors.primary.withOpacity(0.12),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom, top: 6),
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
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _TabData tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(
                        color: AppColors.primary.withOpacity(0.22),
                        width: 1.5,
                      )
                    : null,
              ),
              child: AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: ColorFiltered(
                  colorFilter: isSelected
                      ? const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        )
                      : const ColorFilter.mode(
                          Color(0xFF9E9E9E),
                          BlendMode.srcIn,
                        ),
                  child: Image.network(
                    tab.iconUrl,
                    width: 28,
                    height: 28,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.circle,
                      size: 24,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceMuted,
                letterSpacing: isSelected ? 0.4 : 0,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}
