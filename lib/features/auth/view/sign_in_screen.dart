import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_providers.dart';
import '../../../repositories/auth_repository.dart';

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
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _BackgroundDecor(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const _LogoSection(),
                  const Spacer(flex: 3),
                  const _BoardPreview(),
                  const Spacer(flex: 2),
                  _SignInButton(
                    busy: busy,
                    onTap: () => notifier.signInWithGoogle(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'By continuing you agree to our Terms & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: AppColors.onSurfaceMuted.withOpacity(0.7),
                      fontSize: 11,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
        backgroundColor: AppColors.board,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign-in Failed',
          style: GoogleFonts.luckiestGuy(
            color: AppColors.danger,
            letterSpacing: 1,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(color: AppColors.onSurface, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
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
        Positioned(
          top: -60,
          left: -60,
          child: _DecorCircle(
            size: 200,
            color: AppColors.sColor.withOpacity(0.06),
          ),
        ),
        Positioned(
          top: size.height * 0.15,
          right: -40,
          child: _DecorCircle(
            size: 140,
            color: AppColors.oColor.withOpacity(0.07),
          ),
        ),
        Positioned(
          bottom: size.height * 0.18,
          left: -30,
          child: _DecorCircle(
            size: 120,
            color: AppColors.highlight.withOpacity(0.06),
          ),
        ),
        Positioned(
          bottom: -50,
          right: -50,
          child: _DecorCircle(
            size: 180,
            color: AppColors.secondary.withOpacity(0.06),
          ),
        ),
        ..._buildDots(size),
      ],
    );
  }

  List<Widget> _buildDots(Size size) {
    final positions = [
      (0.12, 0.12),
      (0.88, 0.08),
      (0.05, 0.45),
      (0.92, 0.38),
      (0.18, 0.78),
      (0.80, 0.72),
      (0.50, 0.06),
      (0.60, 0.92),
    ];
    final colors = [
      AppColors.sColor,
      AppColors.oColor,
      AppColors.highlight,
      AppColors.secondary,
      AppColors.primary,
      AppColors.sColor,
      AppColors.oColor,
      AppColors.highlight,
    ];
    return List.generate(positions.length, (i) {
      final p = positions[i];
      return Positioned(
        left: size.width * p.$1 - 5,
        top: size.height * p.$2 - 5,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors[i % colors.length].withOpacity(0.25),
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlowLetter(letter: 'S', color: AppColors.sColor),
            _GlowLetter(letter: 'O', color: AppColors.oColor),
            _GlowLetter(letter: 'S', color: AppColors.sColor),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ARENA',
          style: GoogleFonts.luckiestGuy(
            fontSize: 18,
            color: AppColors.onSurfaceMuted,
            letterSpacing: 10,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Text(
            'Place S · Place O · Score Combos · Win',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppColors.onSurfaceMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowLetter extends StatelessWidget {
  const _GlowLetter({required this.letter, required this.color});
  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          letter,
          style: GoogleFonts.luckiestGuy(
            fontSize: 72,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8
              ..strokeJoin = StrokeJoin.round
              ..color = color.withOpacity(0.25),
          ),
        ),
        Text(
          letter,
          style: GoogleFonts.luckiestGuy(
            fontSize: 72,
            color: color,
            shadows: [
              Shadow(color: color.withOpacity(0.5), blurRadius: 20),
              Shadow(color: color.withOpacity(0.3), blurRadius: 40),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview();

  static const _cells = [
    ('S', true),
    ('', false),
    ('O', true),
    ('', false),
    ('S', true),
    ('', false),
    ('O', true),
    ('', false),
    ('S', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'HOW IT WORKS',
          style: GoogleFonts.luckiestGuy(
            fontSize: 12,
            color: AppColors.primary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.board,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.grid.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1,
                ),
                itemCount: 9,
                itemBuilder: (_, i) {
                  final cell = _cells[i];
                  return _BoardCell(letter: cell.$1, isScored: cell.$2);
                },
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: AppColors.sColor, label: 'S tile'),
                  SizedBox(width: 16),
                  _LegendDot(color: AppColors.oColor, label: 'O tile'),
                  SizedBox(width: 16),
                  _LegendDot(color: AppColors.success, label: 'SOS scored'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({required this.letter, required this.isScored});
  final String letter;
  final bool isScored;

  @override
  Widget build(BuildContext context) {
    final hasLetter = letter.isNotEmpty;
    final color = letter == 'S'
        ? AppColors.sColor
        : letter == 'O'
        ? AppColors.oColor
        : AppColors.grid;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isScored
            ? AppColors.success.withOpacity(0.15)
            : hasLetter
            ? color.withOpacity(0.10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isScored
              ? AppColors.success.withOpacity(0.6)
              : hasLetter
              ? color.withOpacity(0.4)
              : AppColors.grid.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: isScored
            ? [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Center(
        child: hasLetter
            ? Text(
                letter,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 26,
                  color: isScored ? AppColors.success : color,
                  shadows: isScored
                      ? [
                          Shadow(
                            color: AppColors.success.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              )
            : null,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceMuted,
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.sColor],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.login_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.luckiestGuy(
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 1,
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
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.board,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 30,
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
                        width: 52,
                        height: 52,
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
                            color: AppColors.board,
                          ),
                          child: Center(
                            child: Text(
                              'S',
                              style: GoogleFonts.luckiestGuy(
                                fontSize: 20,
                                color: AppColors.sColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Signing In…',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 20,
                      color: AppColors.onSurface,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Talking to Google',
                    style: GoogleFonts.outfit(
                      color: AppColors.onSurfaceMuted,
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
