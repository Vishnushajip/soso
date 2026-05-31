import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/auth_providers.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(authControllerProvider);
    final notifier = ref.read(authControllerProvider.notifier);

    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      });
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
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
                busy: controller.isLoading,
                onPressed: () => notifier.signInWithGoogle(),
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
    );
  }
}
