import 'package:flutter_test/flutter_test.dart';
import 'package:soso/core/utils/sos_engine.dart';

void main() {
  group('SosEngine.findSosCreated', () {
    test('detects a horizontal SOS when the middle O completes it', () {
      final engine = SosEngine(5);
      final board = engine.emptyBoard();
      board[0] = 'S';
      board[2] = 'S';
      final lines = engine.findSosCreated(board: board, pos: 1, letter: SosLetter.o);
      expect(lines.length, 1);
      expect(lines.first.cells, [0, 1, 2]);
    });

    test('detects multiple SOS lines from a single move', () {
      final engine = SosEngine(5);
      final board = engine.emptyBoard();
      // Place: row of S _ S, and a column ending with S at (1,2) so the
      // middle O at (1,1) builds two SOS lines (horizontal + vertical).
      board[engine.idx(0, 1)] = 'S';
      board[engine.idx(2, 1)] = 'S';
      board[engine.idx(1, 0)] = 'S';
      board[engine.idx(1, 2)] = 'S';
      final lines = engine.findSosCreated(
        board: board,
        pos: engine.idx(1, 1),
        letter: SosLetter.o,
      );
      expect(lines.length, 2);
    });

    test('returns empty when the placed letter does not complete an SOS', () {
      final engine = SosEngine(4);
      final board = engine.emptyBoard();
      board[0] = 'S';
      final lines = engine.findSosCreated(board: board, pos: 1, letter: SosLetter.s);
      expect(lines, isEmpty);
    });
  });
}
