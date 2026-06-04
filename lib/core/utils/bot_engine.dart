/// Lightweight, key-less AI for SOS. Picks a move with simple 1-ply lookahead:
///   1. Take the highest-scoring move available right now.
///   2. Otherwise play the move that leaves the opponent the fewest points.
///
/// Pure Dart — no Flutter, no Firebase, easy to unit-test.
library;

import 'dart:math';

import 'sos_engine.dart';

class BotMove {
  final int position;
  final SosLetter letter;
  const BotMove(this.position, this.letter);

  String get letterStr => letter == SosLetter.s ? 'S' : 'O';
}

class BotEngine {
  BotEngine(this.size) : _engine = SosEngine(size);

  final int size;
  final SosEngine _engine;

  static const _letters = [SosLetter.s, SosLetter.o];

  /// Chooses the bot's next move, or null if the board is full.
  BotMove? chooseMove(List<String> board, [Random? random]) {
    final rng = random ?? Random();
    final empties = <int>[];
    for (var i = 0; i < board.length; i++) {
      if (board[i].isEmpty) empties.add(i);
    }
    if (empties.isEmpty) return null;

    // 1. Greedy — best immediate scoring move.
    var bestScore = 0;
    final scoring = <BotMove>[];
    for (final pos in empties) {
      for (final letter in _letters) {
        final n = _engine
            .findSosCreated(board: board, pos: pos, letter: letter)
            .length;
        if (n > bestScore) {
          bestScore = n;
          scoring
            ..clear()
            ..add(BotMove(pos, letter));
        } else if (n == bestScore && n > 0) {
          scoring.add(BotMove(pos, letter));
        }
      }
    }
    if (bestScore > 0) {
      return scoring[rng.nextInt(scoring.length)];
    }

    // 2. Defensive — minimise the opponent's best reply.
    int? minOpponent;
    final safe = <BotMove>[];
    for (final pos in empties) {
      for (final letter in _letters) {
        final next = [...board]..[pos] = letter == SosLetter.s ? 'S' : 'O';
        var oppBest = 0;
        for (final p2 in empties) {
          if (p2 == pos) continue;
          for (final l2 in _letters) {
            final c = _engine
                .findSosCreated(board: next, pos: p2, letter: l2)
                .length;
            if (c > oppBest) oppBest = c;
          }
        }
        if (minOpponent == null || oppBest < minOpponent) {
          minOpponent = oppBest;
          safe
            ..clear()
            ..add(BotMove(pos, letter));
        } else if (oppBest == minOpponent) {
          safe.add(BotMove(pos, letter));
        }
      }
    }
    return safe[rng.nextInt(safe.length)];
  }
}
