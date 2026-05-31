import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../providers/auth_providers.dart';
import '../../../routes/route_names.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  void _navigate(BuildContext context, AsyncValue<Object?> auth) {
    if (auth.isLoading) return;
    final target = auth.valueOrNull != null ? RouteNames.home : RouteNames.signIn;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(target);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _navigate(context, ref.read(authStateProvider));
    ref.listen<AsyncValue<Object?>>(
      authStateProvider,
      (_, next) => _navigate(context, next),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SOS',
              style: GoogleFonts.outfit(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                color: AppColors.sColor,
                letterSpacing: 6,
              ),
            ),
            Text(
              'ARENA',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: AppColors.onSurfaceMuted,
                letterSpacing: 12,
              ),
            ),
            const SizedBox(height: 36),
            const AppLoader(label: 'Warming up the board…'),
          ],
        ),
      ),
    );
  }
}
