import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          if (e is AuthException && e.code == 'cancelled') return;
          _showError(context, e);
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.arenaBgBottom,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BackgroundDecor(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 32,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),
                              const _LogoSection(),
                              const SizedBox(height: 64),
                              _SignInButton(
                                busy: busy,
                                onTap: () => notifier.signInWithGoogle(),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'By continuing you agree to our Terms & Privacy Policy.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: AppColors.onArenaMuted.withOpacity(
                                    0.5,
                                  ),
                                  fontSize: 11,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (busy) const _SignInOverlay(),
        ],
      ),
    );
  }

  void _showError(BuildContext context, Object error) {
    final message = error is AuthException ? error.message : error.toString();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.arenaStone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.arenaStoneEdge, width: 1.5),
        ),
        title: Text(
          'Sign-in Failed',
          style: GoogleFonts.luckiestGuy(
            color: AppColors.danger,
            letterSpacing: 1,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(color: AppColors.onArena, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: AppColors.inversePrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.arenaBgTop, AppColors.arenaBgBottom],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -80,
          left: -80,
          child: _DecorCircle(
            size: 260,
            color: AppColors.sColor.withOpacity(0.08),
          ),
        ),
        Positioned(
          top: size.height * 0.22,
          right: -60,
          child: _DecorCircle(
            size: 180,
            color: AppColors.oColor.withOpacity(0.09),
          ),
        ),
        Positioned(
          bottom: size.height * 0.20,
          left: -40,
          child: _DecorCircle(
            size: 150,
            color: AppColors.arenaGlow.withOpacity(0.07),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -60,
          child: _DecorCircle(
            size: 220,
            color: AppColors.primaryContainer.withOpacity(0.10),
          ),
        ),
        ..._buildDots(size),
      ],
    );
  }

  List<Widget> _buildDots(Size size) {
    final positions = [
      (0.10, 0.10),
      (0.88, 0.07),
      (0.04, 0.48),
      (0.94, 0.35),
      (0.15, 0.80),
      (0.82, 0.74),
      (0.50, 0.05),
      (0.62, 0.93),
    ];
    final colors = [
      AppColors.sColor,
      AppColors.oColor,
      AppColors.arenaGold,
      AppColors.inversePrimary,
      AppColors.arenaGlow,
      AppColors.sColor,
      AppColors.oColor,
      AppColors.arenaGold,
    ];
    return List.generate(positions.length, (i) {
      final p = positions[i];
      return Positioned(
        left: size.width * p.$1 - 4,
        top: size.height * p.$2 - 4,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colors[i % colors.length].withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.sColor.withOpacity(0.35),
                blurRadius: 40,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: AppColors.oColor.withOpacity(0.2),
                blurRadius: 60,
                spreadRadius: 8,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'SOS ARENA',
          style: GoogleFonts.luckiestGuy(
            fontSize: 32,
            color: AppColors.onArena,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Place · Score · Dominate',
          style: GoogleFonts.outfit(
            color: AppColors.onArenaMuted.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PillBadge(label: 'S', color: AppColors.sColor),
            SizedBox(width: 6),
            _PillBadge(label: 'O', color: AppColors.oColor),
            SizedBox(width: 6),
            _PillBadge(label: 'S', color: AppColors.sColor),
          ],
        ),
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)],
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.luckiestGuy(
            fontSize: 20,
            color: color,
            shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryContainer, AppColors.sColor],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.sColor.withOpacity(0.5),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.primaryContainer.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.login_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Continue with Google',
              style: GoogleFonts.luckiestGuy(
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInOverlay extends StatefulWidget {
  const _SignInOverlay();

  @override
  State<_SignInOverlay> createState() => _SignInOverlayState();
}

class _SignInOverlayState extends State<_SignInOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _spin;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _spin = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withOpacity(0.65),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.arenaStone,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.arenaStoneEdge, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sColor.withOpacity(0.18),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _spin,
                    builder: (_, _) => Transform.rotate(
                      angle: _spin.value,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppColors.sColor,
                              AppColors.oColor,
                              AppColors.sColor,
                            ],
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.arenaStone,
                          ),
                          child: Center(
                            child: Text(
                              'S',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 22,
                                color: AppColors.sColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Signing In…',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 20,
                      color: AppColors.onArena,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Talking to Google',
                    style: GoogleFonts.outfit(
                      color: AppColors.onArenaMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
