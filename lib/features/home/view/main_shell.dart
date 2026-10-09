import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soso/features/update/view/update_dialog.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/routes/route_names.dart';

String _iconUrl(String icon, {Color? color}) {
  final base = 'https://api.iconify.design/$icon.svg';
  if (color == null) return base;
  final hex = color.value.toRadixString(16).padLeft(8, '0').substring(2);
  return '$base?color=%23$hex';
}

class _NetIcon extends StatelessWidget {
  const _NetIcon({required this.icon, required this.size, required this.color});

  final String icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.network(
      _iconUrl(icon, color: color),
      width: size,
      height: size,
      placeholderBuilder: (_) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: size * 0.5,
            height: size * 0.5,
            child: const CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      ),
    );
  }
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabData(
      path: RouteNames.home,
      label: 'Play',
      icon: 'mdi:gamepad-variant-outline',
      activeIcon: 'mdi:gamepad-variant',
    ),
    _TabData(
      path: RouteNames.friends,
      label: 'Friends',
      icon: 'mdi:account-group-outline',
      activeIcon: 'mdi:account-group',
    ),
    _TabData(
      path: RouteNames.shop,
      label: 'Shop',
      icon: 'mdi:storefront-outline',
      activeIcon: 'mdi:storefront',
    ),
    _TabData(
      path: RouteNames.leaderboard,
      label: 'Ranks',
      icon: 'mdi:trophy-outline',
      activeIcon: 'mdi:trophy',
    ),
    _TabData(
      path: RouteNames.profile,
      label: 'Profile',
      icon: 'mdi:account-outline',
      activeIcon: 'mdi:account',
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

    final unread = ref.watch(
      unreadNotificationsCountProvider.select((v) => v.valueOrNull ?? 0),
    );
    final name = ref.watch(
      currentUserProvider.select((u) => u.valueOrNull?.name ?? ''),
    );
    final points = ref.watch(
      currentUserProvider.select((u) => u.valueOrNull?.totalPoints ?? 0),
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
        title: _AppBarTitle(
          name: name,
          firstLetter: firstLetter,
          selectedLabel: _tabs[selected].label,
        ),
        actions: [
          _PointsPill(points: points),
          _NotificationBell(
            unread: unread,
            onTap: () {
              haptic.fire(HapticEvent.tap);
              context.push(RouteNames.notifications);
            },
          ),
          Semantics(
            button: true,
            label: 'Messages',
            child: Tooltip(
              message: 'Messages',
              child: GestureDetector(
                onTap: () {
                  haptic.fire(HapticEvent.tap);
                  context.push(RouteNames.chatList);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  child: _NetIcon(
                    icon: 'mdi:chat',
                    size: 26,
                    color: AppColors.onSurface.withOpacity(0.75),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AppUpdateGate(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: _GameNavBar(
          selected: selected,
          tabs: _tabs,
          onTap: (i) {
            if (i == selected) return;
            haptic.fire(HapticEvent.selection);
            context.go(_tabs[i].path);
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
  final String icon;
  final String activeIcon;
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({
    required this.name,
    required this.firstLetter,
    required this.selectedLabel,
  });

  final String name;
  final String firstLetter;
  final String selectedLabel;

  String _subIcon() {
    switch (selectedLabel) {
      case 'Play':
        return 'mdi:gamepad-variant';
      case 'Friends':
        return 'mdi:account-group';
      case 'Shop':
        return 'mdi:store';
      case 'Ranks':
        return 'mdi:trophy';
      default:
        return 'mdi:account-circle';
    }
  }

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
              name.isNotEmpty ? name : 'Player',
              style: GoogleFonts.luckiestGuy(
                fontSize: 15,
                color: AppColors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NetIcon(icon: _subIcon(), size: 14, color: AppColors.primary),
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
          const _NetIcon(
            icon: 'mdi:star',
            size: 15,
            color: AppColors.secondary,
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
            _NetIcon(
              icon: 'mdi:bell',
              size: 26,
              color: AppColors.onSurface.withOpacity(0.75),
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
    final color = isSelected ? AppColors.primary : AppColors.onSurfaceMuted;
    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 24 : 0,
                height: isSelected ? 3 : 0,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedScale(
                scale: isSelected ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: _NetIcon(
                  icon: isSelected ? tab.activeIcon : tab.icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  letterSpacing: isSelected ? 0.3 : 0,
                ),
                child: Text(tab.label),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
