/// Pure SOS rules. No Flutter, no Firebase. Easy to unit-test.
///
/// Board is stored row-major as a `List<String>` of length `size*size`,
/// where empty cells are `''` and filled cells are `'S'` or `'O'`.
library;

enum SosLetter { s, o }

class SosLine {
  final int a; // start cell index
  final int b; // middle cell index
  final int c; // end cell index
  const SosLine(this.a, this.b, this.c);

  List<int> get cells => [a, b, c];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SosLine &&
        ((other.a == a && other.b == b && other.c == c) ||
         (other.a == c && other.b == b && other.c == a));
  }

  @override
  int get hashCode {
    final low = a < c ? a : c;
    final high = a < c ? c : a;
    return Object.hash(low, b, high);
  }
}

class SosEngine {
  final int size;
  SosEngine(this.size) : assert(size >= 3);

  static const _dxs = [1, 0, 1, -1];
  static const _dys = [0, 1, 1, 1];

  int idx(int x, int y) => y * size + x;
  int x(int i) => i % size;
  int y(int i) => i ~/ size;

  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < size && y < size;

  /// Returns every SOS line created by placing [letter] at [pos] on [board].
  /// The placement itself is NOT applied — caller decides whether to commit.
  List<SosLine> findSosCreated({
    required List<String> board,
    required int pos,
    required SosLetter letter,
  }) {
    final px = x(pos);
    final py = y(pos);
    final placed = letter == SosLetter.s ? 'S' : 'O';

    String at(int x, int y) {
      if (!inBounds(x, y)) return '#';
      if (idx(x, y) == pos) return placed;
      return board[idx(x, y)];
    }

    final lines = <SosLine>[];

    for (var d = 0; d < _dxs.length; d++) {
      final dx = _dxs[d];
      final dy = _dys[d];

      // The placed letter can occupy position 0, 1, or 2 of the SOS triple.
      // Offsets describe where in the triple the placed letter sits.
      for (final offset in const [0, 1, 2]) {
        final ax = px - offset * dx;
        final ay = py - offset * dy;
        final bx = ax + dx;
        final by = ay + dy;
        final cx = ax + 2 * dx;
        final cy = ay + 2 * dy;

        if (!inBounds(ax, ay) || !inBounds(cx, cy)) continue;

        if (at(ax, ay) == 'S' && at(bx, by) == 'O' && at(cx, cy) == 'S') {
          final line = SosLine(idx(ax, ay), idx(bx, by), idx(cx, cy));
          // Avoid duplicates from different rotations of the same line.
          if (!lines.any((l) => l.a == line.a && l.b == line.b && l.c == line.c)) {
            lines.add(line);
          }
        }
      }
    }

    return lines;
  }

  /// Finds all completed SOS lines currently present on the board.
  List<SosLine> findAllSos(List<String> board) {
    final lines = <SosLine>[];
    for (var i = 0; i < board.length; i++) {
      if (board[i] == 'S') {
        final px = x(i);
        final py = y(i);

        for (var d = 0; d < _dxs.length; d++) {
          final dx = _dxs[d];
          final dy = _dys[d];

          final bx = px + dx;
          final by = py + dy;
          final cx = px + 2 * dx;
          final cy = py + 2 * dy;

          if (inBounds(bx, by) && inBounds(cx, cy)) {
            final idxB = idx(bx, by);
            final idxC = idx(cx, cy);

            if (board[idxB] == 'O' && board[idxC] == 'S') {
              lines.add(SosLine(i, idxB, idxC));
            }
          }
        }
      }
    }
    return lines;
  }

  bool isFull(List<String> board) => board.every((c) => c.isNotEmpty);

  List<String> emptyBoard() => List<String>.filled(size * size, '');
}
