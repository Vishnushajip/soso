import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/repositories/auth_repository.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(authControllerProvider);
    final notifier = ref.read(authControllerProvider.notifier);
    final busy = controller.isLoading;

    // Retained exact error handling logic
    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          if (e is AuthException && e.code == 'cancelled') return;
          _showError(context, e);
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.black, // Dark sleek base
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Animated Background
          const _AnimatedAmbientBackground(),

          // 2. Main Content
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Staggered Entrance Animations
                          const _FadeSlide(delay: 0, child: _ModernLogoSection()),
                          const SizedBox(height: 52),
                          _FadeSlide(
                            delay: 200,
                            child: _GlassCard(
                              child: Column(
                                children: [
                                  Text(
                                    'WELCOME TO THE ARENA',
                                    style: GoogleFonts.luckiestGuy(
                                      color: Colors.white,
                                      fontSize: 16,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Sign in to sync your rank, coins & friends',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(alpha: 0.65),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _GoogleSignInButton(
                                    busy: busy,
                                    onTap: () => notifier.signInWithGoogle(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _FadeSlide(
                            delay: 400,
                            child: Text(
                              'By continuing you agree to our\nTerms & Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                                height: 1.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top Right Discreet Guest Mode Button (Privacy Policy Compliance)
                Positioned(
                  top: 14,
                  right: 18,
                  child: _FadeSlide(
                    delay: 150,
                    child: _TopGuestButton(
                      busy: busy,
                      onTap: () => notifier.signInAsGuest(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Loading Overlay
          if (busy) const _ModernSignInOverlay(),
        ],
      ),
    );
  }

  void _showError(BuildContext context, Object error) {
    final message = error is AuthException ? error.message : error.toString();
    showDialog<void>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppColors.arenaStone.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.sColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.sColor),
              const SizedBox(width: 12),
              Text(
                'AUTHENTICATION NOTICE',
                style: GoogleFonts.luckiestGuy(
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  color: AppColors.sColor,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A smooth, continuously moving background to give a "live" game feel without freezing UI.
class _AnimatedAmbientBackground extends StatefulWidget {
  const _AnimatedAmbientBackground();

  @override
  State<_AnimatedAmbientBackground> createState() =>
      _AnimatedAmbientBackgroundState();
}

class _AnimatedAmbientBackgroundState extends State<_AnimatedAmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Extremely slow, smooth rotation
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.arenaBgTop, AppColors.arenaBgBottom],
                ),
              ),
            ),
            // Floating orbs that rotate around the screen
            Positioned(
              top: -100 + (math.sin(_controller.value * 2 * math.pi) * 50),
              left: -50 + (math.cos(_controller.value * 2 * math.pi) * 50),
              child: const _GlowOrb(color: AppColors.sColor, size: 400),
            ),
            Positioned(
              bottom: -150 + (math.cos(_controller.value * 2 * math.pi) * 50),
              right: -100 + (math.sin(_controller.value * 2 * math.pi) * 50),
              child: const _GlowOrb(color: AppColors.oColor, size: 500),
            ),
            // A subtle grid or noise overlay could go here to make it more "Arena" like
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 60,
                sigmaY: 60,
              ), // Blends the orbs smoothly
              child: Container(color: Colors.transparent),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
    );
  }
}

/// Reusable Glassmorphism Card
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Modern Logo redesign with 3D/Neon effects
class _ModernLogoSection extends StatelessWidget {
  const _ModernLogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App Icon wrapped in a glowing hexagon or sleek circle
        Container(
          width: 110,
          height: 110,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.sColor, AppColors.oColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sColor.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: AppColors.oColor.withValues(alpha: 0.2),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.arenaBgBottom,
            ),
            padding: const EdgeInsets.all(6),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'SOS ARENA',
          style: GoogleFonts.luckiestGuy(
            fontSize: 42,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Colors.white, Colors.white70],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: AppColors.sColor.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            'PLACE • SCORE • DOMINATE',
            style: GoogleFonts.outfit(
              color: AppColors.arenaGold,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Google Sign-In Button with vibrant arena gradient and official 4-color Google G logo
class _GoogleSignInButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;

  const _GoogleSignInButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.sColor, AppColors.primaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sColor.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withValues(alpha: 0.16),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clean official 4-color Google G Logo in white badge
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.string(
                    _kGoogleLogoSvg,
                    height: 18,
                    width: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'SIGN IN WITH GOOGLE',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
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

/// Discreet Top-Right Guest Button for App Store / Google Play Privacy Policy Compliance
class _TopGuestButton extends StatelessWidget {
  const _TopGuestButton({
    required this.busy,
    required this.onTap,
  });

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withValues(alpha: 0.12),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: Colors.white.withValues(alpha: 0.75),
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                'Play as Guest',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
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

const String _kGoogleLogoSvg = '''<svg viewBox="0 0 48 48" width="48" height="48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
<path fill="none" d="M0 0h48v48H0z"/>
</svg>''';

/// A highly polished, modern loading overlay using Backdrop Blur
class _ModernSignInOverlay extends StatefulWidget {
  const _ModernSignInOverlay();

  @override
  State<_ModernSignInOverlay> createState() => _ModernSignInOverlayState();
}

class _ModernSignInOverlayState extends State<_ModernSignInOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.arenaStone.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.sColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sColor.withValues(alpha: 0.2),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modern Dual-Ring Loader
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, child) => Transform.rotate(
                            angle: _ctrl.value * 2 * math.pi,
                            child: child,
                          ),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.sColor.withValues(alpha: 0.1),
                                width: 4,
                              ),
                              gradient: const SweepGradient(
                                colors: [Colors.transparent, AppColors.sColor],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.arenaStone,
                          ),
                          child: Center(
                            child: Text(
                              'S',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 24,
                                color: AppColors.sColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ESTABLISHING UPLINK...',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2,
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

/// Helper widget to Stagger-animate children in
class _FadeSlide extends StatefulWidget {
  final Widget child;
  final int delay;

  const _FadeSlide({required this.child, required this.delay});

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide> {
  bool _start = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _start = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _start ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _start ? Offset.zero : const Offset(0, 0.2),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
        child: widget.child,
      ),
    );
  }
}
