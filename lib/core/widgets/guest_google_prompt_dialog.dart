import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_providers.dart';
import '../providers/service_providers.dart';
import '../providers/user_providers.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';
import 'app_snack_bar.dart';

class GuestGooglePromptDialog extends ConsumerWidget {
  const GuestGooglePromptDialog({
    super.key,
    required this.feature,
    required this.description,
  });

  final String feature;
  final String description;

  /// Returns `true` if the user is allowed to proceed (not a guest),
  /// or `false` if the user is a guest, automatically presenting the prompt.
  static bool allowAction(
    BuildContext context,
    WidgetRef ref, {
    required String feature,
    required String description,
  }) {
    final user = ref.read(currentUserProvider).valueOrNull;
    final isGuest = user == null || user.isGuestUser;
    if (isGuest) {
      show(context, feature: feature, description: description);
      return false;
    }
    return true;
  }

  static Future<void> show(
    BuildContext context, {
    required String feature,
    required String description,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GuestGooglePromptDialog(
        feature: feature,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(authControllerProvider).isLoading;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'GOOGLE SIGN-IN REQUIRED',
                textAlign: TextAlign.center,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                expanded: true,
                busy: busy,
                icon: Icons.login_rounded,
                label: 'Sign In with Google',
                onPressed: () async {
                  ref.read(soundServiceProvider).play(AppSound.buttonClick);
                  await ref
                      .read(authControllerProvider.notifier)
                      .signInWithGoogle();
                  if (context.mounted) {
                    final user = ref.read(currentUserProvider).valueOrNull;
                    if (user != null && !user.isGuestUser) {
                      Navigator.of(context).pop();
                      AppSnackBar.showSuccess(
                        context,
                        'Signed in with Google! Feature unlocked.',
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Maybe Later',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
