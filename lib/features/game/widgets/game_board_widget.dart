import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/utils/sos_engine.dart';

class GameBoardWidget extends StatefulWidget {
  const GameBoardWidget({
    super.key,
    required this.size,
    required this.board,
    required this.onTap,
    this.highlightCells = const {},
    this.disabled = false,
    this.sosLines = const [],
    this.lineColors = const {},
    this.lastPlacedPosition,
    this.theme = BoardTheme.classic,
  });

  final int size;
  final List<String> board;
  final void Function(int index) onTap;
  final Set<int> highlightCells;
  final bool disabled;
  final List<SosLine> sosLines;
  final Map<SosLine, Color> lineColors;
  final int? lastPlacedPosition;
  final BoardTheme theme;

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _animProgress;
  List<SosLine> _animatingLines = const [];
  List<SosLine> _pastLines = const [];

  @override
  void initState() {
    super.initState();
    _pastLines = List<SosLine>.from(widget.sosLines);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animProgress = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant GameBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if new SOS lines were added
    final newLines = widget.sosLines
        .where((l) => !_containsLine(oldWidget.sosLines, l))
        .toList();
    if (newLines.isNotEmpty) {
      _animatingLines = newLines;
      _pastLines = oldWidget.sosLines
          .where((l) => !newLines.contains(l))
          .toList();
      _animCtrl.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _animatingLines = const [];
            _pastLines = List<SosLine>.from(widget.sosLines);
          });
        }
      });
    } else {
      _pastLines = List<SosLine>.from(widget.sosLines);
    }
  }

  bool _containsLine(List<SosLine> list, SosLine line) {
    return list.any(
      (l) =>
          (l.a == line.a && l.b == line.b && l.c == line.c) ||
          (l.a == line.c && l.b == line.b && l.c == line.a),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.theme.boardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.theme.boardBorderColor,
            width: widget.theme.isGlossy ? 2 : 1,
          ),
          boxShadow: widget.theme.isGlossy
              ? [
                  BoxShadow(
                    color: widget.theme.highlightColor.withValues(alpha: 0.18),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            RepaintBoundary(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.size,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: widget.size * widget.size,
                itemBuilder: (_, i) {
                  final v = widget.board[i];
                  final isHighlighted = widget.highlightCells.contains(i);
                  final isLastPlaced = widget.lastPlacedPosition == i;

                  final linesWithCell = widget.sosLines.where(
                    (line) => line.cells.contains(i),
                  );
                  final isCellInSos = linesWithCell.isNotEmpty;
                  final cellSosColor = isCellInSos
                      ? widget.lineColors[linesWithCell.last]
                      : null;

                  if (widget.theme.isGlossy) {
                    return _ArenaCell(
                      value: v,
                      size: widget.size,
                      isHighlighted: isHighlighted,
                      isLastPlaced: isLastPlaced,
                      isInSos: isCellInSos,
                      sosColor: cellSosColor,
                      theme: widget.theme,
                      onTap: widget.disabled ? null : () => widget.onTap(i),
                    );
                  }

                  final color = v == 'S'
                      ? widget.theme.sColor
                      : v == 'O'
                      ? widget.theme.oColor
                      : AppColors.onSurface;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? widget.theme.highlightColor.withValues(alpha: 0.35)
                          : isLastPlaced
                          ? AppColors.secondary.withValues(alpha: 0.25)
                          : isCellInSos
                          ? (cellSosColor ?? widget.theme.highlightColor)
                                .withValues(alpha: 0.16)
                          : widget.theme.cellBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isHighlighted
                          ? Border.all(
                              color: widget.theme.highlightColor,
                              width: 2,
                            )
                          : isLastPlaced
                          ? Border.all(color: AppColors.secondary, width: 2)
                          : isCellInSos
                          ? Border.all(
                              color:
                                  (cellSosColor ?? widget.theme.highlightColor)
                                      .withValues(alpha: 0.5),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isCellInSos
                          ? [
                              BoxShadow(
                                color:
                                    (cellSosColor ??
                                            widget.theme.highlightColor)
                                        .withValues(alpha: 0.15),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: widget.disabled ? null : () => widget.onTap(i),
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
                                fontSize: widget.size <= 6 ? 28 : 20,
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
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _animProgress,
                    builder: (context, _) => CustomPaint(
                      painter: SosStrikePainter(
                        lines: _pastLines,
                        animatingLines: _animatingLines,
                        animationProgress: _animProgress.value,
                        boardSize: widget.size,
                        lineColors: widget.lineColors,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SosStrikePainter extends CustomPainter {
  static final Paint _glowPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

  static final Paint _corePaint = Paint()..strokeCap = StrokeCap.round;

  final List<SosLine> lines;
  final List<SosLine> animatingLines;
  final double animationProgress;
  final int boardSize;
  final Map<SosLine, Color> lineColors;

  SosStrikePainter({
    required this.lines,
    required this.animatingLines,
    required this.animationProgress,
    required this.boardSize,
    required this.lineColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lines.isEmpty && animatingLines.isEmpty) return;

    final cellWidth = size.width / boardSize;
    final cellHeight = size.height / boardSize;

    Offset getCellCenter(int index) {
      final row = index ~/ boardSize;
      final col = index % boardSize;
      final x = col * cellWidth + cellWidth / 2;
      final y = row * cellHeight + cellHeight / 2;
      return Offset(x, y);
    }

    // Cached paint objects to avoid allocating in tight animation loops
    void drawGlowingLine(
      Canvas canvas,
      Offset start,
      Offset end,
      Color color,
      double width, {
      double glowOpacity = 0.35,
    }) {
      _glowPaint
        ..color = color.withValues(alpha: glowOpacity)
        ..strokeWidth = width * 2.2;
      canvas.drawLine(start, end, _glowPaint);

      _corePaint
        ..color = color
        ..strokeWidth = width;
      canvas.drawLine(start, end, _corePaint);
    }

    // Draw completed static lines
    for (final l in lines) {
      final start = getCellCenter(l.a);
      final end = getCellCenter(l.c);
      final color = lineColors[l] ?? AppColors.primary.withValues(alpha: 0.8);
      drawGlowingLine(canvas, start, end, color, 3.5, glowOpacity: 0.4);
    }

    // Draw newly animated lines
    for (final l in animatingLines) {
      final start = getCellCenter(l.a);
      final end = getCellCenter(l.c);
      final currentEnd = Offset(
        start.dx + (end.dx - start.dx) * animationProgress,
        start.dy + (end.dy - start.dy) * animationProgress,
      );
      final color = lineColors[l] ?? AppColors.secondary.withValues(alpha: 0.9);
      drawGlowingLine(canvas, start, currentEnd, color, 4.5, glowOpacity: 0.45);
    }
  }

  @override
  bool shouldRepaint(covariant SosStrikePainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.animatingLines != animatingLines ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.boardSize != boardSize ||
        oldDelegate.lineColors != lineColors;
  }
}

/// Convert a list of SOS lines into the flat set of cell indices it lights up.
Set<int> sosLineCells(Iterable<SosLine> lines) => {
  for (final l in lines) ...l.cells,
};

/// A single glossy 3D "gem" socket used by the dark battle-arena board skin.
class _ArenaCell extends StatelessWidget {
  const _ArenaCell({
    required this.value,
    required this.size,
    required this.isHighlighted,
    required this.isLastPlaced,
    required this.isInSos,
    required this.sosColor,
    required this.theme,
    required this.onTap,
  });

  final String value;
  final int size;
  final bool isHighlighted;
  final bool isLastPlaced;
  final bool isInSos;
  final Color? sosColor;
  final BoardTheme theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final filled = value.isNotEmpty;
    final base = value == 'S'
        ? theme.sColor
        : value == 'O'
        ? theme.oColor
        : theme.cellBgColor;

    // Empty socket vs. raised gem.
    final Color light = Color.lerp(base, Colors.white, 0.42)!;
    final Color dark = Color.lerp(base, Colors.black, 0.40)!;

    // Outline + glow priority: hint > last placed > SOS member > neutral.
    final Color edge = isHighlighted
        ? theme.highlightColor
        : isLastPlaced
        ? Colors.white
        : isInSos
        ? (sosColor ?? theme.highlightColor)
        : (filled
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05));
    final bool glows = isHighlighted || isLastPlaced || isInSos;
    final Color glowColor = isHighlighted
        ? theme.highlightColor
        : isLastPlaced
        ? Colors.white
        : (sosColor ?? base);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: filled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [light, base, dark],
                stops: const [0.0, 0.5, 1.0],
              )
            : LinearGradient(colors: [theme.cellBgColor, theme.cellBgColor]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: edge,
          width: (isHighlighted || isLastPlaced) ? 2.2 : 1.4,
        ),
        boxShadow: [
          if (filled)
            const BoxShadow(
              color: Colors.black45,
              blurRadius: 4,
              offset: Offset(0, 3),
            ),
          if (glows)
            BoxShadow(
              color: glowColor.withValues(alpha: 0.55),
              blurRadius: 10,
              spreadRadius: 0.5,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Stack(
            children: [
              // Glossy top highlight on filled gems.
              if (filled)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              Center(
                child: AnimatedScale(
                  scale: filled ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: size <= 6 ? 28 : 20,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 3,
                          offset: Offset(0, 1.5),
                        ),
                      ],
                    ),
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
