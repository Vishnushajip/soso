import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
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
      next.whenOrNull(error: (e, _) {
        if (e is AuthException && e.code == 'cancelled') return;
        _showError(context, e);
      });
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    Env.appName,
                    style: GoogleFonts.outfit(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: AppColors.sColor,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Place S. Place O. Score combos. Win the board.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 16),
                  ),
                  const Spacer(),
                  AppButton(
                    expanded: true,
                    icon: Icons.login,
                    label: 'Continue with Google',
                    busy: busy,
                    onPressed: busy ? null : () => notifier.signInWithGoogle(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By continuing you agree to our Terms & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.onSurfaceMuted.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
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
        title: const Text('Sign-in failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SignInOverlay extends StatelessWidget {
  const _SignInOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.55),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.board,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grid),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(AppColors.sColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Signing in…',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Talking to Google',
                    style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
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
