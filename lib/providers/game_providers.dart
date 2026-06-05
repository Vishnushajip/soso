import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/services/haptic_service.dart';
import '../core/services/sound_service.dart';
import '../core/utils/sos_engine.dart';
import '../models/game_room.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// ---------- LOCAL (single-device) GAME STATE ----------
class LocalPlayer {
  final String name;
  final int score;
  const LocalPlayer({required this.name, this.score = 0});
  LocalPlayer copyWith({String? name, int? score}) =>
      LocalPlayer(name: name ?? this.name, score: score ?? this.score);
}

class LocalGameState {
  final int boardSize;
  final List<String> board;
  final List<LocalPlayer> players;
  final int currentTurn;
  final bool finished;
  final int? winnerIndex;
  final List<SosLine> lastSosLines;
  final Map<SosLine, int> completedSosLines;
  final int? awardedProfilePoints;
  final List<int> customHighlights;

  const LocalGameState({
    required this.boardSize,
    required this.board,
    required this.players,
    this.currentTurn = 0,
    this.finished = false,
    this.winnerIndex,
    this.lastSosLines = const [],
    this.completedSosLines = const {},
    this.awardedProfilePoints,
    this.customHighlights = const [],
  });

  LocalGameState copyWith({
    List<String>? board,
    List<LocalPlayer>? players,
    int? currentTurn,
    bool? finished,
    int? winnerIndex,
    List<SosLine>? lastSosLines,
    Map<SosLine, int>? completedSosLines,
    int? awardedProfilePoints,
    List<int>? customHighlights,
  }) =>
      LocalGameState(
        boardSize: boardSize,
        board: board ?? this.board,
        players: players ?? this.players,
        currentTurn: currentTurn ?? this.currentTurn,
        finished: finished ?? this.finished,
        winnerIndex: winnerIndex ?? this.winnerIndex,
        lastSosLines: lastSosLines ?? this.lastSosLines,
        completedSosLines: completedSosLines ?? this.completedSosLines,
        awardedProfilePoints: awardedProfilePoints ?? this.awardedProfilePoints,
        customHighlights: customHighlights ?? this.customHighlights,
      );
}

class LocalGameConfig {
  final int boardSize;
  final List<String> playerNames;
  const LocalGameConfig({required this.boardSize, required this.playerNames});
}

class LocalGameController extends FamilyNotifier<LocalGameState, LocalGameConfig> {
  late SosEngine _engine;
  late SoundService _sound;
  late HapticService _haptic;
  bool _statsApplied = false;
  final List<LocalGameState> _history = [];

  @override
  LocalGameState build(LocalGameConfig cfg) {
    _engine = SosEngine(cfg.boardSize);
    _sound = ref.read(soundServiceProvider);
    _haptic = ref.read(hapticServiceProvider);
    return LocalGameState(
      boardSize: cfg.boardSize,
      board: _engine.emptyBoard(),
      players: cfg.playerNames.map((n) => LocalPlayer(name: n)).toList(),
    );
  }

  void reset() {
    _statsApplied = false;
    _history.clear();
    state = LocalGameState(
      boardSize: state.boardSize,
      board: _engine.emptyBoard(),
      players: state.players.map((p) => p.copyWith(score: 0)).toList(),
    );
  }

  void undoLocal() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      if (_statsApplied && !state.finished) {
        _statsApplied = false;
      }
    }
  }

  void eraseLocal({required int position}) {
    if (state.finished) return;
    if (state.board[position].isEmpty) return;
    
    _history.add(state);
    
    final newBoard = [...state.board]..[position] = '';
    final newCompletedSos = Map<SosLine, int>.from(state.completedSosLines)
      ..removeWhere((line, _) => line.cells.contains(position));

    state = state.copyWith(
      board: newBoard,
      lastSosLines: const [],
      completedSosLines: newCompletedSos,
      customHighlights: const [],
    );
  }

  void showHintsLocal() {
    final hints = <int>[];
    for (var i = 0; i < state.board.length; i++) {
      if (state.board[i].isEmpty) {
        final sLines = _engine.findSosCreated(board: state.board, pos: i, letter: SosLetter.s);
        final oLines = _engine.findSosCreated(board: state.board, pos: i, letter: SosLetter.o);
        if (sLines.isNotEmpty || oLines.isNotEmpty) {
          hints.add(i);
        }
      }
    }
    state = state.copyWith(customHighlights: hints);
  }

  void place({required int position, required SosLetter letter}) {
    if (state.finished) return;
    if (state.board[position].isNotEmpty) return;

    _history.add(state);

    final lines = _engine.findSosCreated(
      board: state.board,
      pos: position,
      letter: letter,
    );
    final scored = lines.isNotEmpty;
    final newBoard = [...state.board]..[position] = letter == SosLetter.s ? 'S' : 'O';
    final players = [...state.players];
    final newCompletedSos = Map<SosLine, int>.from(state.completedSosLines);

    if (scored) {
      final cur = players[state.currentTurn];
      players[state.currentTurn] = cur.copyWith(
        score: cur.score + lines.length * AppConstants.pointsPerSos,
      );
      for (final line in lines) {
        newCompletedSos[line] = state.currentTurn;
      }
      _sound.play(AppSound.sos);
      _haptic.fire(HapticEvent.sos);
    } else {
      _sound.play(AppSound.point);
      _haptic.fire(HapticEvent.point);
    }
    final full = newBoard.every((c) => c.isNotEmpty);
    final nextTurn = scored ? state.currentTurn : (state.currentTurn + 1) % players.length;
    int? winner;
    bool finished = false;
    int? awarded;
    if (full) {
      finished = true;
      var top = -1;
      for (var i = 0; i < players.length; i++) {
        if (players[i].score > top) {
          top = players[i].score;
          winner = i;
        } else if (players[i].score == top) {
          winner = null;
        }
      }
      final youWon = winner == 0;
      _sound.play(youWon ? AppSound.win : AppSound.lose);
      _haptic.fire(youWon ? HapticEvent.win : HapticEvent.lose);

      awarded = _profilePointsFor(
        matchScore: players[0].score,
        won: youWon,
      );
      _persistResult(youWon: youWon, pointsDelta: awarded);
    }
    state = state.copyWith(
      board: newBoard,
      players: players,
      currentTurn: nextTurn,
      finished: finished,
      winnerIndex: winner,
      lastSosLines: lines,
      completedSosLines: newCompletedSos,
      awardedProfilePoints: awarded,
      customHighlights: const [], // clear hints on placement
    );
  }

  int _profilePointsFor({required int matchScore, required bool won}) {
    return matchScore + (won ? AppConstants.pointsPerWin : 0);
  }

  Future<void> _persistResult({required bool youWon, required int pointsDelta}) async {
    if (_statsApplied) return;
    _statsApplied = true;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    try {
      await ref.read(userRepositoryProvider).applyMatchResult(
            uid: uid,
            pointsDelta: pointsDelta,
            won: youWon,
          );
    } catch (_) {
      // Never block UI on stats write.
    }
  }
}

final localGameProvider =
    NotifierProvider.family<LocalGameController, LocalGameState, LocalGameConfig>(
  LocalGameController.new,
);

/// ---------- ONLINE GAME ----------
// autoDispose so the Firestore room subscription is cancelled the moment the
// match screen leaves. Without it, a late stream emit could fire into the
// already-disposed screen element (Riverpod "defunct element" assertion).
final gameRoomProvider = StreamProvider.autoDispose.family<GameRoom?, String>(
  (ref, roomId) => ref.watch(gameRepositoryProvider).watchRoom(roomId),
);
