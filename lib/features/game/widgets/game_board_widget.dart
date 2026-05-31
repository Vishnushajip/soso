import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/sos_engine.dart';

class GameBoardWidget extends StatelessWidget {
  const GameBoardWidget({
    super.key,
    required this.size,
    required this.board,
    required this.onTap,
    this.highlightCells = const {},
    this.disabled = false,
  });

  final int size;
  final List<String> board;
  final void Function(int index) onTap;
  final Set<int> highlightCells;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.board,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: size,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: size * size,
          itemBuilder: (_, i) {
            final v = board[i];
            final isHighlighted = highlightCells.contains(i);
            final color = v == 'S'
                ? AppColors.sColor
                : v == 'O'
                    ? AppColors.oColor
                    : AppColors.onSurface;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppColors.highlight.withValues(alpha: 0.35)
                    : AppColors.grid,
                borderRadius: BorderRadius.circular(8),
                border: isHighlighted
                    ? Border.all(color: AppColors.highlight, width: 2)
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: disabled || v.isNotEmpty ? null : () => onTap(i),
                  child: Center(
                    child: AnimatedScale(
                      scale: v.isEmpty ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Text(
                        v,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: size <= 6 ? 28 : 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Convert a list of SOS lines into the flat set of cell indices it lights up.
Set<int> sosLineCells(Iterable<SosLine> lines) =>
    {for (final l in lines) ...l.cells};
