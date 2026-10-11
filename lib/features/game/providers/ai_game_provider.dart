import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/match_record.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/utils/bot_engine.dart';
import '../../../core/utils/sos_engine.dart';

class AIGameConfig {
  final int boardSize;
  final BotDifficulty difficulty;
  final String playerName;
  final bool magicEnabled;

  const AIGameConfig({
    required this.boardSize,
    required this.difficulty,
    this.playerName = 'Player',
    this.magicEnabled = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIGameConfig &&
          runtimeType == other.runtimeType &&
          boardSize == other.boardSize &&
          difficulty == other.difficulty &&
          playerName == other.playerName &&
          magicEnabled == other.magicEnabled;

  @override
  int get hashCode =>
      boardSize.hashCode ^
      difficulty.hashCode ^
      playerName.hashCode ^
      magicEnabled.hashCode;
}

class AIGameState {
  final AIGameConfig config;
  final List<String> board;
  final int currentTurn; // 0 = Human, 1 = Bot
  final int humanScore;
  final int botScore;
  final Map<SosLine, int> completedSosLines; // line -> playerIndex
  final bool finished;
  final int? winnerIndex; // 0 = Human, 1 = Bot, null = Tie
  final bool isBotThinking;
  final int? lastPlacedPosition;
  final List<MatchMoveRecord> moves;
  final Set<int> customHighlights;

  const AIGameState({
    required this.config,
    required this.board,
    required this.currentTurn,
    required this.humanScore,
    required this.botScore,
    required this.completedSosLines,
    required this.finished,
    this.winnerIndex,
    this.isBotThinking = false,
    this.lastPlacedPosition,
    this.moves = const [],
    this.customHighlights = const {},
  });

  AIGameState copyWith({
    AIGameConfig? config,
    List<String>? board,
    int? currentTurn,
    int? humanScore,
    int? botScore,
    Map<SosLine, int>? completedSosLines,
    bool? finished,
    int? Function()? winnerIndex,
    bool? isBotThinking,
    int? Function()? lastPlacedPosition,
    List<MatchMoveRecord>? moves,
    Set<int>? customHighlights,
  }) {
    return AIGameState(
      config: config ?? this.config,
      board: board ?? this.board,
      currentTurn: currentTurn ?? this.currentTurn,
      humanScore: humanScore ?? this.humanScore,
      botScore: botScore ?? this.botScore,
      completedSosLines: completedSosLines ?? this.completedSosLines,
      finished: finished ?? this.finished,
      winnerIndex: winnerIndex != null ? winnerIndex() : this.winnerIndex,
      isBotThinking: isBotThinking ?? this.isBotThinking,
      lastPlacedPosition: lastPlacedPosition != null
          ? lastPlacedPosition()
          : this.lastPlacedPosition,
      customHighlights: customHighlights ?? this.customHighlights,
    );
  }

  bool get isPlayerTurn => currentTurn == 0;
  bool get playerWon => finished && winnerIndex == 0;
  bool get botWon => finished && winnerIndex == 1;
  bool get isDraw => finished && winnerIndex == null;
  int get playerScore => humanScore;
  int get erasersLeft => 3;
  int get magicSpellsLeft => 2;
  int get consecutiveTurns => 1;
  int? get lastMovePosition => lastPlacedPosition;
}

class AIGameNotifier extends StateNotifier<AIGameState> {
  AIGameNotifier(this.config, this.ref)
      : _sosEngine = SosEngine(config.boardSize),
        _botEngine = BotEngine(config.boardSize),
        super(
          AIGameState(
            config: config,
            board: List.filled(config.boardSize * config.boardSize, ''),
            currentTurn: 0,
            humanScore: 0,
            botScore: 0,
            completedSosLines: const {},
            finished: false,
          ),
        );

  final AIGameConfig config;
  final Ref ref;
  final SosEngine _sosEngine;
  final BotEngine _botEngine;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void placeHuman({required int position, required SosLetter letter}) {
    if (state.finished ||
        state.currentTurn != 0 ||
        state.isBotThinking ||
        state.board[position].isNotEmpty) {
      return;
    }

    final letterStr = letter == SosLetter.s ? 'S' : 'O';
    final newBoard = [...state.board]..[position] = letterStr;

    // Check newly formed SOS lines
    final newLines = _sosEngine.findSosCreated(
      board: state.board,
      pos: position,
      letter: letter,
    );

    final updatedLines = Map<SosLine, int>.from(state.completedSosLines);
    for (final line in newLines) {
      updatedLines[line] = 0; // 0 = Human
    }

    final newHumanScore = state.humanScore + newLines.length;
    final moveRecord = MatchMoveRecord(
      position: position,
      letter: letterStr,
      playerIndex: 0,
      sosCount: newLines.length,
      linesCreated: newLines,
    );
    final updatedMoves = [...state.moves, moveRecord];

    final isBoardFull = !newBoard.any((c) => c.isEmpty);

    if (newLines.isNotEmpty) {
      ref.read(soundServiceProvider).play(AppSound.sos);
    } else {
      ref.read(soundServiceProvider).play(AppSound.point);
    }

    if (isBoardFull) {
      _finishGame(
        board: newBoard,
        humanScore: newHumanScore,
        botScore: state.botScore,
        lines: updatedLines,
        moves: updatedMoves,
      );
      return;
    }

    if (newLines.isNotEmpty) {
      // Human scored! Keeps the turn.
      state = state.copyWith(
        board: newBoard,
        humanScore: newHumanScore,
        completedSosLines: updatedLines,
        lastPlacedPosition: () => position,
        moves: updatedMoves,
        customHighlights: const {},
      );
    } else {
      // No score, pass turn to Bot.
      state = state.copyWith(
        board: newBoard,
        currentTurn: 1,
        lastPlacedPosition: () => position,
        moves: updatedMoves,
        customHighlights: const {},
        isBotThinking: true,
      );
      _scheduleBotMove();
    }
  }

  void _scheduleBotMove() {
    if (_disposed || state.finished) return;

    final delay = Duration(milliseconds: 650 + Random().nextInt(450));
    Future.delayed(delay, () {
      if (_disposed || state.finished || state.currentTurn != 1) return;

      final botMove = _botEngine.chooseMoveWithDifficulty(
        state.board,
        config.difficulty,
      );

      if (botMove == null) {
        _finishGame(
          board: state.board,
          humanScore: state.humanScore,
          botScore: state.botScore,
          lines: state.completedSosLines,
          moves: state.moves,
        );
        return;
      }

      final pos = botMove.position;
      final letStr = botMove.letterStr;
      final newBoard = [...state.board]..[pos] = letStr;

      final newLines = _sosEngine.findSosCreated(
        board: state.board,
        pos: pos,
        letter: botMove.letter,
      );

      final updatedLines = Map<SosLine, int>.from(state.completedSosLines);
      for (final line in newLines) {
        updatedLines[line] = 1; // 1 = Bot
      }

      final newBotScore = state.botScore + newLines.length;
      final moveRecord = MatchMoveRecord(
        position: pos,
        letter: letStr,
        playerIndex: 1,
        sosCount: newLines.length,
        linesCreated: newLines,
      );
      final updatedMoves = [...state.moves, moveRecord];

      if (newLines.isNotEmpty) {
        ref.read(soundServiceProvider).play(AppSound.point);
      }

      final isBoardFull = !newBoard.any((c) => c.isEmpty);

      if (isBoardFull) {
        _finishGame(
          board: newBoard,
          humanScore: state.humanScore,
          botScore: newBotScore,
          lines: updatedLines,
          moves: updatedMoves,
        );
        return;
      }

      if (newLines.isNotEmpty) {
        // Bot scored! Gets another turn.
        state = state.copyWith(
          board: newBoard,
          botScore: newBotScore,
          completedSosLines: updatedLines,
          lastPlacedPosition: () => pos,
          moves: updatedMoves,
          isBotThinking: true,
        );
        _scheduleBotMove();
      } else {
        // Bot passed turn back to human.
        state = state.copyWith(
          board: newBoard,
          currentTurn: 0,
          botScore: newBotScore,
          completedSosLines: updatedLines,
          lastPlacedPosition: () => pos,
          moves: updatedMoves,
          isBotThinking: false,
        );
      }
    });
  }

  void _finishGame({
    required List<String> board,
    required int humanScore,
    required int botScore,
    required Map<SosLine, int> lines,
    required List<MatchMoveRecord> moves,
  }) {
    int? winner;
    String? winnerName;
    if (humanScore > botScore) {
      winner = 0;
      winnerName = config.playerName;
      ref.read(soundServiceProvider).play(AppSound.win);
    } else if (botScore > humanScore) {
      winner = 1;
      winnerName = '${config.difficulty.label} Bot';
      ref.read(soundServiceProvider).play(AppSound.lose);
    }

    state = state.copyWith(
      board: board,
      humanScore: humanScore,
      botScore: botScore,
      completedSosLines: lines,
      moves: moves,
      finished: true,
      winnerIndex: () => winner,
      isBotThinking: false,
    );

    // Save match to Match History!
    final matchId = 'bot_${DateTime.now().millisecondsSinceEpoch}';
    final record = MatchRecord(
      id: matchId,
      gameType: 'bot',
      boardSize: config.boardSize,
      p1Name: config.playerName,
      p1Score: humanScore,
      p2Name: '${config.difficulty.label} Bot',
      p2Score: botScore,
      winnerName: winnerName,
      winnerIndex: winner,
      playedAt: DateTime.now(),
      moves: moves,
    );

    final uid = ref.read(currentUidProvider);
    ref.read(matchHistoryRepositoryProvider).saveMatch(uid: uid, match: record);

    // Apply match result points if signed in
    if (uid != null) {
      final won = winner == 0;
      ref.read(userRepositoryProvider).applyMatchResult(
            uid: uid,
            pointsDelta: humanScore + (won ? 50 : 10),
            won: won,
          );
    }
  }

  void eraseCell(int position) {
    if (state.board[position].isEmpty || state.finished || state.isBotThinking) {
      return;
    }
    final newBoard = [...state.board]..[position] = '';
    state = state.copyWith(
      board: newBoard,
      customHighlights: const {},
    );
  }

  void undoLastMove() {
    if (state.moves.isEmpty || state.finished || state.isBotThinking) return;
    final lastMove = state.moves.last;
    final newBoard = [...state.board]..[lastMove.position] = '';
    final newMoves = state.moves.sublist(0, state.moves.length - 1);

    // Recalculate completed lines
    final allSos = _sosEngine.findAllSos(newBoard);
    final newLines = Map<SosLine, int>.from(state.completedSosLines)
      ..removeWhere((k, _) => !allSos.contains(k));

    state = state.copyWith(
      board: newBoard,
      moves: newMoves,
      completedSosLines: newLines,
      currentTurn: lastMove.playerIndex,
      customHighlights: const {},
    );
  }

  void highlightHint(int position) {
    state = state.copyWith(customHighlights: {position});
  }

  void reset() {
    state = AIGameState(
      config: config,
      board: List.filled(config.boardSize * config.boardSize, ''),
      currentTurn: 0,
      humanScore: 0,
      botScore: 0,
      completedSosLines: const {},
      finished: false,
    );
  }

  void resetGame() => reset();

  void useMagicSpell() {
    final best = _botEngine.chooseMoveWithDifficulty(state.board, BotDifficulty.hard);
    if (best != null) {
      highlightHint(best.position);
    }
  }

  void useEraser(int pos) => eraseCell(pos);
  void makePlayerMove(int pos, SosLetter letter) => placeHuman(position: pos, letter: letter);
}

final aiGameProvider = StateNotifierProvider.autoDispose
    .family<AIGameNotifier, AIGameState, AIGameConfig>((ref, config) {
  return AIGameNotifier(config, ref);
});
