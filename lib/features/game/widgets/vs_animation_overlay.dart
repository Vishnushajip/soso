import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/widgets/user_avatar.dart';

class VsAnimationOverlay extends ConsumerStatefulWidget {
  const VsAnimationOverlay({
    super.key,
    required this.p1Name,
    this.p1Photo,
    required this.p2Name,
    this.p2Photo,
    this.p1Color,
    this.p2Color,
    this.playerNames,
    this.playerPhotos,
    this.playerColors,
    required this.onComplete,
    this.title = 'MATCH STARTING',
  });

  final String p1Name;
  final String? p1Photo;
  final String p2Name;
  final String? p2Photo;
  final Color? p1Color;
  final Color? p2Color;
  final List<String>? playerNames;
  final List<String?>? playerPhotos;
  final List<Color>? playerColors;
  final String title;
  final VoidCallback onComplete;

  @override
  ConsumerState<VsAnimationOverlay> createState() => _VsAnimationOverlayState();
}

class _VsAnimationOverlayState extends ConsumerState<VsAnimationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double> _bgScale;
  late Animation<double> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _p1Slide;
  late Animation<Offset> _p2Slide;
  late Animation<Offset> _p3Slide;
  late Animation<Offset> _p4Slide;
  late Animation<double> _p1Fade;
  late Animation<double> _p2Fade;
  late Animation<double> _p3Fade;
  late Animation<double> _p4Fade;
  late Animation<double> _vsScale;
  late Animation<double> _vsRotate;
  late Animation<double> _shockwaveScale;
  late Animation<double> _shockwaveOpacity;
  late Animation<double> _exitFade;
  late Animation<double> _pulse;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    ref.read(soundServiceProvider).play(AppSound.versus);

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _bgScale = Tween<double>(begin: 1.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<double>(begin: -24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
      ),
    );

    final totalPlayers = widget.playerNames?.length ?? 2;

    _p1Slide = Tween<Offset>(
      begin: totalPlayers == 4
          ? const Offset(-1.6, -1.6)
          : const Offset(-1.6, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.10, 0.48, curve: Curves.easeOutBack),
      ),
    );

    _p2Slide = Tween<Offset>(
      begin: totalPlayers == 4
          ? const Offset(1.6, -1.6)
          : const Offset(1.6, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.10, 0.48, curve: Curves.easeOutBack),
      ),
    );

    _p3Slide = Tween<Offset>(
      begin: totalPlayers == 4
          ? const Offset(-1.6, 1.6)
          : const Offset(0, 1.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.10, 0.48, curve: Curves.easeOutBack),
      ),
    );

    _p4Slide = Tween<Offset>(
      begin: const Offset(1.6, 1.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.10, 0.48, curve: Curves.easeOutBack),
      ),
    );

    _p1Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.10, 0.30, curve: Curves.easeOut),
      ),
    );

    _p2Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.10, 0.30, curve: Curves.easeOut),
      ),
    );

    _p3Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.10, 0.30, curve: Curves.easeOut),
      ),
    );

    _p4Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.10, 0.30, curve: Curves.easeOut),
      ),
    );

    _vsScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.36, 0.65, curve: Curves.elasticOut),
      ),
    );

    _vsRotate = Tween<double>(begin: -0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.36, 0.65, curve: Curves.elasticOut),
      ),
    );

    _shockwaveScale = Tween<double>(begin: 0.6, end: 2.4).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.44, 0.70, curve: Curves.easeOut),
      ),
    );

    _shockwaveOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.44, 0.70, curve: Curves.easeOut),
      ),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.86, 1.0, curve: Curves.easeInOut),
      ),
    );

    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _shimmer = _shimmerCtrl;

    _mainCtrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.playerNames ?? [widget.p1Name, widget.p2Name];

    final List<String?> photos = [];
    if (widget.playerPhotos != null) {
      photos.addAll(widget.playerPhotos!);
    } else {
      photos.addAll([widget.p1Photo, widget.p2Photo]);
    }
    while (photos.length < names.length) {
      photos.add(null);
    }

    final List<Color> colors = [];
    if (widget.playerColors != null) {
      colors.addAll(widget.playerColors!);
    } else {
      colors.addAll([
        widget.p1Color ?? AppColors.player1,
        widget.p2Color ?? AppColors.player2,
      ]);
    }
    while (colors.length < names.length) {
      colors.add(AppColors.playerPalette[colors.length % AppColors.playerPalette.length]);
    }

    final size = MediaQuery.sizeOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_mainCtrl, _pulseCtrl, _shimmerCtrl]),
      builder: (context, _) {
        return Opacity(
          opacity: _exitFade.value,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackground(size, colors),
                _buildDividerLine(size, colors.length),
                _buildShockwave(size),
                _buildContent(size, names, photos, colors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(Size size, List<Color> colors) {
    return Transform.scale(
      scale: _bgScale.value,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < colors.length; i++)
            _buildRadialGlow(size, colors[i], i, colors.length),
          Container(color: AppColors.overlay),
        ],
      ),
    );
  }

  Widget _buildRadialGlow(Size size, Color color, int index, int total) {
    Alignment alignment;
    if (total == 2) {
      alignment = index == 0 ? Alignment.centerLeft : Alignment.centerRight;
    } else if (total == 3) {
      alignment = switch (index) {
        0 => Alignment.topLeft,
        1 => Alignment.topRight,
        _ => Alignment.bottomCenter,
      };
    } else {
      alignment = switch (index) {
        0 => Alignment.topLeft,
        1 => Alignment.topRight,
        2 => Alignment.bottomLeft,
        _ => Alignment.bottomRight,
      };
    }

    return Align(
      alignment: alignment,
      child: Container(
        width: size.width * 0.6,
        height: size.height * 0.6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.24),
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDividerLine(Size size, int total) {
    if (total == 2) {
      return Center(
        child: Container(
          width: 1,
          height: size.height * 0.38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 1.5,
            height: size.height * 0.45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: size.width * 0.6,
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShockwave(Size size) {
    return Center(
      child: Transform.scale(
        scale: _shockwaveScale.value,
        child: Opacity(
          opacity: _shockwaveOpacity.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Size size, List<String> names, List<String?> photos, List<Color> colors) {
    final total = names.length;
    final scaleFactor = total > 2 ? 0.78 : 1.0;

    if (total == 2) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, _titleSlide.value),
            child: Opacity(opacity: _titleFade.value, child: _buildTitle()),
          ),
          SizedBox(height: size.height * 0.06),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SlideTransition(
                  position: _p1Slide,
                  child: Opacity(
                    opacity: _p1Fade.value,
                    child: _buildPlayerCard(names[0], photos[0], colors[0], scaleFactor),
                  ),
                ),
              ),
              _buildVsCircle(scaleFactor),
              Expanded(
                child: SlideTransition(
                  position: _p2Slide,
                  child: Opacity(
                    opacity: _p2Fade.value,
                    child: _buildPlayerCard(names[1], photos[1], colors[1], scaleFactor),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.translate(
          offset: Offset(0, _titleSlide.value),
          child: Opacity(opacity: _titleFade.value, child: _buildTitle()),
        ),
        SizedBox(height: size.height * 0.04),
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: SlideTransition(
                        position: _p1Slide,
                        child: Opacity(
                          opacity: _p1Fade.value,
                          child: _buildPlayerCard(names[0], photos[0], colors[0], scaleFactor),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SlideTransition(
                        position: _p2Slide,
                        child: Opacity(
                          opacity: _p2Fade.value,
                          child: _buildPlayerCard(names[1], photos[1], colors[1], scaleFactor),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (total == 3) ...[
                      const Spacer(),
                      Expanded(
                        child: SlideTransition(
                          position: _p3Slide,
                          child: Opacity(
                            opacity: _p3Fade.value,
                            child: _buildPlayerCard(names[2], photos[2], colors[2], scaleFactor),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ] else ...[
                      Expanded(
                        child: SlideTransition(
                          position: _p3Slide,
                          child: Opacity(
                            opacity: _p3Fade.value,
                            child: _buildPlayerCard(names[2], photos[2], colors[2], scaleFactor),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SlideTransition(
                          position: _p4Slide,
                          child: Opacity(
                            opacity: _p4Fade.value,
                            child: _buildPlayerCard(names[3], photos[3], colors[3], scaleFactor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            _buildVsCircle(scaleFactor),
          ],
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (_, child) {
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.4),
                  Colors.white,
                  Colors.white.withValues(alpha: 0.4),
                ],
                stops: [
                  (_shimmer.value - 0.3).clamp(0.0, 1.0),
                  _shimmer.value.clamp(0.0, 1.0),
                  (_shimmer.value + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(bounds),
              child: child!,
            );
          },
          child: Text(
            widget.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 5.0,
          ),
        ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1.5,
          width: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.secondary.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(
    String name,
    String? photo,
    Color color,
    double scaleFactor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAvatarRing(name, photo, color, scaleFactor),
        SizedBox(height: 16 * scaleFactor),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15 * scaleFactor,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
        SizedBox(height: 6 * scaleFactor),
        Container(
          height: 3,
          width: 36 * scaleFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6 * scaleFactor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarRing(String name, String? photo, Color color, double scaleFactor) {
    final avatarSize = 88.0 * scaleFactor;
    final ringSize = 100.0 * scaleFactor;
    final innerSize = 84.0 * scaleFactor;

    return Transform.scale(
      scale: _pulse.value,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.25), width: 10 * scaleFactor),
            ),
          ),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5 * scaleFactor),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 20 * scaleFactor,
                  spreadRadius: 2 * scaleFactor,
                ),
              ],
            ),
            child: ClipOval(
              child: photo != null && photo.isNotEmpty
                  ? UserAvatar(name: name, photoUrl: photo, size: innerSize)
                  : Container(
                      color: color.withValues(alpha: 0.15),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.outfit(
                            fontSize: 34 * scaleFactor,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVsCircle(double scaleFactor) {
    return Transform.scale(
      scale: _vsScale.value * scaleFactor,
      child: Transform.rotate(
        angle: _vsRotate.value,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.6),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'VS',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
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
