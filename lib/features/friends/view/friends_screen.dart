import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/friend_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/routes/route_names.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendships = ref.watch(friendshipsProvider);
    final pending = ref.watch(incomingRequestsProvider).valueOrNull ?? const [];
    final me = ref.watch(currentUidProvider);

    return Stack(
      children: [
        const _AnimatedBackdrop(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ActionRow(pending: pending.length),
              const SizedBox(height: 16),
              Expanded(
                child: friendships.when(
                  loading: () => const AppLoader(),
                  error: (e, _) => ErrorView(message: '$e'),
                  data: (list) {
                    if (list.isEmpty) return const _EmptyState();
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24, top: 2),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) {
                        final f = list[i];
                        final otherUid = f.otherUid(me ?? '');
                        final other = ref
                            .watch(userByUidProvider(otherUid))
                            .valueOrNull;
                        return _AnimatedEntry(
                          index: i,
                          child: _FriendCard(
                            other: other,
                            otherUid: otherUid,
                            me: me,
                            ref: ref,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedBackdrop extends StatefulWidget {
  const _AnimatedBackdrop();

  @override
  State<_AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<_AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          return CustomPaint(painter: _BlobPainter(_c.value));
        },
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      (AppColors.primary, 0.0, 0.18, 160.0),
      (AppColors.secondary, 0.33, 0.78, 190.0),
      (AppColors.highlight, 0.66, 0.42, 150.0),
    ];
    for (final (color, phase, baseY, r) in blobs) {
      final a = (t + phase) * 2 * math.pi;
      final dx = size.width * (0.5 + 0.42 * math.cos(a));
      final dy = size.height * (baseY + 0.10 * math.sin(a * 1.3));
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(0.16), color.withOpacity(0.0)],
        ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}

class _AnimatedEntry extends StatefulWidget {
  const _AnimatedEntry({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.pending});
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            label: 'Add Friend',
            icon: Icons.person_add_alt_1_rounded,
            color: AppColors.primary,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(RouteNames.addFriend);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionBtn(
            label: pending > 0 ? 'Requests ($pending)' : 'Requests',
            icon: Icons.mark_email_unread_rounded,
            color: pending > 0 ? AppColors.secondary : AppColors.onSurfaceMuted,
            hasBadge: pending > 0,
            badgeCount: pending,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(RouteNames.friendRequests);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.hasBadge = false,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool hasBadge;
  final int badgeCount;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.hasBadge) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ActionBtn old) {
    super.didUpdateWidget(old);
    if (widget.hasBadge && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.hasBadge && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return _Bouncy(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.22), color.withOpacity(0.10)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.55), width: 2.5),
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(widget.icon, color: color, size: 22),
                if (widget.hasBadge)
                  Positioned(
                    right: -7,
                    top: -7,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.badgeCount}',
                          style: GoogleFonts.baloo2(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatefulWidget {
  const _EmptyState();

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(34),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, AppColors.surface.withOpacity(0.85)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.20),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final bob = math.sin(_c.value * math.pi) * 8;
                return Transform.translate(
                  offset: Offset(0, -bob),
                  child: Transform.rotate(
                    angle: (_c.value - 0.5) * 0.18,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.18),
                      AppColors.primary.withOpacity(0.04),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.30),
                    width: 2.5,
                  ),
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  color: AppColors.primary,
                  size: 46,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Friends Yet!',
              style: GoogleFonts.baloo2(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Invite someone to a match and build your squad!',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                color: AppColors.onSurfaceMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.other,
    required this.otherUid,
    required this.me,
    required this.ref,
  });

  final dynamic other;
  final String otherUid;
  final String? me;
  final WidgetRef ref;

  Future<void> _challenge(BuildContext context) async {
    HapticFeedback.mediumImpact();
    if (me == null) return;
    final myUser = ref.read(currentUserProvider).valueOrNull;
    if (myUser == null) return;
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendChallenge(me: me!, myName: myUser.name, otherUid: otherUid);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Challenge sent!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send challenge: $e')));
      }
    }
  }

  Future<void> _chat(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (me == null) return;
    final room = await ref
        .read(chatRepositoryProvider)
        .openDirectChat(me: me!, other: otherUid);
    if (context.mounted) {
      context.push('${RouteNames.chatRoom}?roomId=${room.id}');
    }
  }

  Future<void> _remove(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _RemoveFriendDialog(name: other?.name ?? 'this player'),
    );
    if (confirmed != true) return;
    HapticFeedback.mediumImpact();
    await ref
        .read(friendRepositoryProvider)
        .removeFriend(me: me ?? '', other: otherUid);
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = other?.isOnline ?? false;
    final accent = isOnline ? AppColors.success : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surface.withOpacity(0.82)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.35), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: UserAvatar(
                          photoUrl: other?.photoUrl,
                          name: other?.name,
                          online: isOnline,
                          frameColor: other?.avatarFrameColor,
                          size: 54,
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                other?.name ?? 'Player',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.baloo2(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (other?.customTitle != null &&
                                other!.customTitle!.isNotEmpty) ...[
                              const SizedBox(width: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.secondary,
                                      AppColors.highlight,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  other!.customTitle!,
                                  style: GoogleFonts.baloo2(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _PulseDot(online: isOnline),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isOnline
                                    ? 'Online now'
                                    : 'Last seen ${FormatUtils.relativeTime(other?.lastSeen)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isOnline
                                      ? AppColors.success
                                      : AppColors.onSurfaceMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ChallengeButton(onTap: () => _challenge(context)),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RoundIconBtn(
                      icon: Icons.chat_bubble_rounded,
                      color: AppColors.primary,
                      tooltip: 'Chat',
                      onTap: () => _chat(context),
                    ),
                    const SizedBox(width: 8),
                    _RoundIconBtn(
                      icon: Icons.person_remove_rounded,
                      color: AppColors.danger,
                      tooltip: 'Remove',
                      onTap: () => _remove(context),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveFriendDialog extends StatelessWidget {
  const _RemoveFriendDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, AppColors.surface.withOpacity(0.92)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.danger.withOpacity(0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withOpacity(0.18),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.danger.withOpacity(0.18),
                    AppColors.danger.withOpacity(0.04),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.danger.withOpacity(0.30),
                  width: 2.5,
                ),
              ),
              child: const Icon(
                Icons.person_remove_rounded,
                color: AppColors.danger,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Remove Friend?',
              style: GoogleFonts.baloo2(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceMuted,
                ),
                children: [
                  const TextSpan(text: 'Are you sure you want to remove '),
                  TextSpan(
                    text: name,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const TextSpan(text: ' from your friends?'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _Bouncy(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.onSurfaceMuted.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.onSurfaceMuted.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.baloo2(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Bouncy(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.danger, Color(0xFFE5484D)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.30),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withOpacity(0.40),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        'Remove',
                        style: GoogleFonts.baloo2(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.online});
  final bool online;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.online) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.online && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.online && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.online) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.onSurfaceMuted.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _ChallengeButton extends StatelessWidget {
  const _ChallengeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Bouncy(
      onTap: onTap,
      child: Tooltip(
        message: 'Challenge',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary, AppColors.highlight],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.30),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_esports_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Challenge',
                style: GoogleFonts.baloo2(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _Bouncy(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.22), color.withOpacity(0.10)],
            ),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withOpacity(0.45), width: 2),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    );
  }
}

class _Bouncy extends StatefulWidget {
  const _Bouncy({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<_Bouncy> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
    _scale = _c.drive(Tween(begin: 1.0, end: 0.92));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
