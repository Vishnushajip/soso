import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Busy flag while the store link opens, keyed by analytics source so the
/// landing and home instances are independent.
final _launchingProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, _) => false,
);

/// Pressed-down flag for the badge's squash animation.
final _pressedProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, _) => false,
);

/// "Get it on Google Play" promo section — web only.
class PlayStoreSection extends ConsumerWidget {
  const PlayStoreSection({super.key, required this.source});

  /// Analytics source tag (e.g. `landing`, `home`).
  final String source;

  Future<void> _openStore(BuildContext context, WidgetRef ref) async {
    final launching = ref.read(_launchingProvider(source).notifier);
    if (launching.state) return;
    launching.state = true;

    HapticFeedback.lightImpact();
    ref.read(soundServiceProvider).play(AppSound.buttonClick);
    ref.read(trackingServiceProvider).downloadAppClicked(source: source);

    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(AppConstants.playStoreUrl),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {
      ok = false;
    }

    if (context.mounted) {
      launching.state = false;
      if (!ok) {
        AppSnackBar.showError(
          context,
          "Couldn't open Google Play. Please try again.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) return const SizedBox.shrink();

    return _Ambient(
      builder: (context, t) => _AnimatedBorder(
        t: t,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PhoneMockup(t: t),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TAKE THE ARENA\nANYWHERE',
                          style: GoogleFonts.luckiestGuy(
                            color: AppColors.onArena,
                            fontSize: 20,
                            height: 1.1,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withValues(alpha: 0.7),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The Android app is faster, smoother and keeps you '
                          'in the game with instant alerts.',
                          style: GoogleFonts.outfit(
                            color: AppColors.onArenaMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PerkChip(
                    icon: Icons.bolt_rounded,
                    color: AppColors.arenaGold,
                    label: 'Smoother play',
                  ),
                  _PerkChip(
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.arenaBlue,
                    label: 'Match alerts',
                  ),
                  _PerkChip(
                    icon: Icons.vibration_rounded,
                    color: AppColors.arenaPink,
                    label: 'Haptics & sound',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _PlayBadgeButton(
                source: source,
                t: t,
                onTap: () => _openStore(context, ref),
              ),
              const SizedBox(height: 10),
              Text(
                'Free download · Sign in with Google to keep your progress',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: AppColors.onArenaMuted.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drives every looping effect in the section from one ticker.
class _Ambient extends StatefulWidget {
  const _Ambient({required this.builder});
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Ambient> createState() => _AmbientState();
}

class _AmbientState extends State<_Ambient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => widget.builder(context, _c.value),
  );
}

class _AnimatedBorder extends StatelessWidget {
  const _AnimatedBorder({required this.t, required this.child});
  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: SweepGradient(
          transform: GradientRotation(t * 2 * math.pi),
          colors: const [
            AppColors.arenaBlue,
            AppColors.arenaStoneEdge,
            AppColors.arenaGold,
            AppColors.arenaPink,
            AppColors.arenaStoneEdge,
            AppColors.arenaBlue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.arenaStone, AppColors.arenaCell],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(t * 2 * math.pi);
    return Transform.translate(
      offset: Offset(0, wave * 4),
      child: Transform.rotate(
        angle: -0.12 + wave * 0.03,
        child: Container(
          width: 74,
          height: 128,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.arenaBgBottom,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.arenaStoneEdge, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.arenaBlue.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: Offset(0, 8 - wave * 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.arenaBgTop, AppColors.arenaBgBottom],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _MiniBoard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBoard extends StatelessWidget {
  const _MiniBoard();

  static const _cells = ['S', 'O', 'S', '', 'O', '', 'S', '', 'O'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          for (var i = 0; i < _cells.length; i++)
            Container(
              width: 14.6,
              height: 14.6,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < 3
                    ? AppColors.arenaGold.withValues(alpha: 0.2)
                    : AppColors.arenaCell,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _cells[i],
                style: GoogleFonts.luckiestGuy(
                  fontSize: 9,
                  height: 1,
                  color: _cells[i] == 'S' ? AppColors.sColor : AppColors.oColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PerkChip extends StatelessWidget {
  const _PerkChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.onArena,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Google Play–style store badge with a shine sweep and press squash.
class _PlayBadgeButton extends ConsumerWidget {
  const _PlayBadgeButton({
    required this.source,
    required this.t,
    required this.onTap,
  });

  final String source;
  final double t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pressed = ref.watch(_pressedProvider(source));
    final busy = ref.watch(_launchingProvider(source));
    final pressedCtl = ref.read(_pressedProvider(source).notifier);
    // Shine crosses the badge during the first 35% of each loop.
    final shine = (t / 0.35).clamp(0.0, 1.0);

    return Semantics(
      button: true,
      label: 'Get it on Google Play',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => pressedCtl.state = true,
          onTapUp: (_) => pressedCtl.state = false,
          onTapCancel: () => pressedCtl.state = false,
          onTap: busy ? null : onTap,
          child: AnimatedScale(
            scale: pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.arenaBgBottom,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.onArenaMuted.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.arenaBlue.withValues(
                      alpha: pressed ? 0.15 : 0.3,
                    ),
                    blurRadius: pressed ? 8 : 18,
                    offset: Offset(0, pressed ? 2 : 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  children: [
                    Center(
                      child: busy
                          ? Text(
                              'Opening Google Play…',
                              style: GoogleFonts.outfit(
                                color: AppColors.onArena,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CustomPaint(
                                  size: Size(26, 28),
                                  painter: _PlayLogoPainter(),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GET IT ON',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.onArena,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Google Play',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.onArena,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    if (shine > 0 && shine < 1)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: FractionalTranslation(
                            translation: Offset(shine * 2.4 - 1.2, 0),
                            child: Transform(
                              transform: Matrix4.skewX(-0.4),
                              alignment: Alignment.center,
                              child: FractionallySizedBox(
                                widthFactor: 0.25,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.onArena.withValues(alpha: 0),
                                        AppColors.onArena.withValues(
                                          alpha: 0.18,
                                        ),
                                        AppColors.onArena.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
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

/// Four-colour "play" triangle in the style of the Google Play mark.
class _PlayLogoPainter extends CustomPainter {
  const _PlayLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const left = Offset.zero;
    final bottomLeft = Offset(0, h);
    final tip = Offset(w, h / 2);
    final mid = Offset(w * 0.48, h / 2);

    void tri(List<Offset> pts, Color color) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(path, Paint()..color = color);
    }

    tri([left, mid, bottomLeft], AppColors.arenaBlue);
    tri([left, tip, mid], AppColors.tertiaryContainer);
    tri([bottomLeft, mid, tip], AppColors.arenaPink);
    // Gold wedge near the tip.
    tri([
      Offset(w * 0.66, h * 0.34),
      tip,
      Offset(w * 0.66, h * 0.66),
      mid,
    ], AppColors.arenaGold);
  }

  @override
  bool shouldRepaint(_PlayLogoPainter oldDelegate) => false;
}
