/// Lightweight, key-less AI for SOS. Picks a move with simple 1-ply lookahead:
///   1. Take the highest-scoring move available right now.
///   2. Otherwise play the move that leaves the opponent the fewest points.
///
/// Pure Dart — no Flutter, no Firebase, easy to unit-test.
library;

import 'dart:math';

import 'sos_engine.dart';

enum BotDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case BotDifficulty.easy:
        return 'Apprentice';
      case BotDifficulty.medium:
        return 'Tactician';
      case BotDifficulty.hard:
        return 'Grandmaster';
    }
  }

  String get emoji {
    switch (this) {
      case BotDifficulty.easy:
        return '🤖';
      case BotDifficulty.medium:
        return '⚔️';
      case BotDifficulty.hard:
        return '🧠';
    }
  }

  String get description {
    switch (this) {
      case BotDifficulty.easy:
        return 'Casual AI with relaxed play & occasional mistakes';
      case BotDifficulty.medium:
        return 'Balanced opponent that seizes scoring opportunities';
      case BotDifficulty.hard:
        return 'Calculates greedy combos and defends against traps';
    }
  }
}

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

  /// Chooses the bot's next move based on the specified difficulty.
  BotMove? chooseMoveWithDifficulty(
    List<String> board,
    BotDifficulty difficulty, [
    Random? random,
  ]) {
    final rng = random ?? Random();
    final empties = <int>[];
    for (var i = 0; i < board.length; i++) {
      if (board[i].isEmpty) empties.add(i);
    }
    if (empties.isEmpty) return null;

    switch (difficulty) {
      case BotDifficulty.easy:
        // 55% chance of making a completely random move
        if (rng.nextDouble() < 0.55) {
          final pos = empties[rng.nextInt(empties.length)];
          final letter = _letters[rng.nextInt(_letters.length)];
          return BotMove(pos, letter);
        }
        // Otherwise attempt a simple immediate SOS check
        final simpleMove = _findImmediateScoringMove(board, empties, rng);
        if (simpleMove != null) return simpleMove;
        final pos = empties[rng.nextInt(empties.length)];
        final letter = _letters[rng.nextInt(_letters.length)];
        return BotMove(pos, letter);

      case BotDifficulty.medium:
        // Always grabs any immediate scoring move
        final scoringMove = _findImmediateScoringMove(board, empties, rng);
        if (scoringMove != null) return scoringMove;
        // If no scoring move, picks a random valid cell
        final pos = empties[rng.nextInt(empties.length)];
        final letter = _letters[rng.nextInt(_letters.length)];
        return BotMove(pos, letter);

      case BotDifficulty.hard:
        // 1. Greedy best immediate score
        final scoringMove = _findImmediateScoringMove(board, empties, rng);
        if (scoringMove != null) return scoringMove;

        // 2. Defensive lookahead: minimize opponent's best reply
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

  BotMove? _findImmediateScoringMove(
    List<String> board,
    List<int> empties,
    Random rng,
  ) {
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
    if (bestScore > 0 && scoring.isNotEmpty) {
      return scoring[rng.nextInt(scoring.length)];
    }
    return null;
  }

  /// Default backwards-compatible move chooser (defaults to hard lookahead).
  BotMove? chooseMove(List<String> board, [Random? random]) {
    return chooseMoveWithDifficulty(board, BotDifficulty.hard, random);
  }
}
