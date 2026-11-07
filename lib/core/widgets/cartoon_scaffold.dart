import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_providers.dart';
import '../routes/route_names.dart';
import '../theme/app_colors.dart';

/// Shared page scaffold matching the cartoon game UI used by Settings/Profile:
/// a tinted background, a rounded "chip" back button, and a Luckiest Guy title.
///
/// Used by the simple content pages (About, Privacy, Terms, Contact) so they
/// share a consistent look with the rest of the app.
class CartoonScaffold extends ConsumerWidget {
  const CartoonScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Semantics(
          button: true,
          label: 'Back',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (onBack != null) {
                onBack!();
                return;
              }
              if (context.canPop()) {
                context.pop();
              } else {
                final auth = ref.read(authStateProvider);
                final loggedIn = auth.valueOrNull != null;
                context.go(loggedIn ? RouteNames.home : RouteNames.signIn);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Tooltip(
              message: 'Back',
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.18),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: body,
        ),
      ),
    );
  }
}

/// Rounded surface card used to group page content. Public counterpart of the
/// private `_GameCard` used in Settings.
class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.14), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Section header with a leading icon and a gradient rule.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.luckiestGuy(
            fontSize: 13,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.3), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}

/// Body copy styled to match the cartoon pages. Use [bullet] for list items.
class InfoText extends StatelessWidget {
  const InfoText(this.text, {super.key, this.bullet = false});
  final String text;
  final bool bullet;

  @override
  Widget build(BuildContext context) {
    final body = Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 13.5,
        height: 1.55,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceMuted,
      ),
    );
    if (!bullet) return body;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
