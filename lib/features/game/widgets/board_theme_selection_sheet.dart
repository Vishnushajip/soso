import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/board_theme.dart';

class BoardThemeSelectionSheet extends ConsumerWidget {
  const BoardThemeSelectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BoardThemeSelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(boardThemeProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Board Theme',
            style: GoogleFonts.luckiestGuy(
              fontSize: 22,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalize your gameplay experience',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: BoardTheme.allThemes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final theme = BoardTheme.allThemes[index];
                final isSelected = theme.id == currentTheme.id;
                return _ThemeCard(
                  theme: theme,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(boardThemeProvider.notifier).setTheme(theme);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final BoardTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.boardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : theme.boardBorderColor,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _MiniBoardPreview(theme: theme),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.bg.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                theme.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBoardPreview extends StatelessWidget {
  const _MiniBoardPreview({required this.theme});
  final BoardTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (r) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (c) {
            const letters = ['S', 'O', '', 'S', '', 'O', '', 'S', 'O'];
            final idx = r * 3 + c;
            final letter = letters[idx];

            return Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.cellBgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.isGlossy
                      ? theme.highlightColor.withOpacity(0.5)
                      : theme.boardBorderColor,
                  width: 1,
                ),
                gradient: theme.isGlossy && letter.isNotEmpty
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.4),
                          theme.cellBgColor,
                          Colors.black.withOpacity(0.2),
                        ],
                      )
                    : null,
              ),
              child: Center(
                child: letter.isNotEmpty
                    ? Text(
                        letter,
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 10,
                          color: letter == 'S' ? theme.sColor : theme.oColor,
                        ),
                      )
                    : null,
              ),
            );
          }),
        ),
      ),
    );
  }
}
