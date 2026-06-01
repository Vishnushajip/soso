import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class SosoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SosoAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBack,
    this.automaticallyImplyLeading = true,
  });

  final Widget title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;

    Widget? leadingWidget;
    if (showBackButton && canPop && automaticallyImplyLeading) {
      leadingWidget = Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            onTap: onBack ?? () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AppBar(
          automaticallyImplyLeading: false,
          leading: leadingWidget,
          leadingWidth: leadingWidget != null ? 54 : 0,
          titleSpacing: leadingWidget != null ? 8 : 16,
          title: title is Text
              ? Text(
                  (title as Text).data ?? '',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.onSurface,
                  ),
                )
              : title,
          actions: actions,
          elevation: 0,
          backgroundColor: AppColors.bg.withValues(alpha: 0.8),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
