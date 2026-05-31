import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/sound_service.dart';
import '../core/utils/sos_engine.dart';
import '../models/game_room.dart';
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

  const LocalGameState({
    required this.boardSize,
    required this.board,
    required this.players,
    this.currentTurn = 0,
    this.finished = false,
    this.winnerIndex,
    this.lastSosLines = const [],
  });

  LocalGameState copyWith({
    List<String>? board,
    List<LocalPlayer>? players,
    int? currentTurn,
    bool? finished,
    int? winnerIndex,
    List<SosLine>? lastSosLines,
  }) =>
      LocalGameState(
        boardSize: boardSize,
        board: board ?? this.board,
        players: players ?? this.players,
        currentTurn: currentTurn ?? this.currentTurn,
        finished: finished ?? this.finished,
        winnerIndex: winnerIndex ?? this.winnerIndex,
        lastSosLines: lastSosLines ?? this.lastSosLines,
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

  @override
  LocalGameState build(LocalGameConfig cfg) {
    _engine = SosEngine(cfg.boardSize);
    _sound = ref.read(soundServiceProvider);
    return LocalGameState(
      boardSize: cfg.boardSize,
      board: _engine.emptyBoard(),
      players: cfg.playerNames.map((n) => LocalPlayer(name: n)).toList(),
    );
  }

  void reset() {
    state = LocalGameState(
      boardSize: state.boardSize,
      board: _engine.emptyBoard(),
      players: state.players.map((p) => p.copyWith(score: 0)).toList(),
    );
  }

  void place({required int position, required SosLetter letter}) {
    if (state.finished) return;
    if (state.board[position].isNotEmpty) return;

    final lines = _engine.findSosCreated(
      board: state.board,
      pos: position,
      letter: letter,
    );
    final scored = lines.isNotEmpty;
    final newBoard = [...state.board]..[position] = letter == SosLetter.s ? 'S' : 'O';
    final players = [...state.players];
    if (scored) {
      final cur = players[state.currentTurn];
      players[state.currentTurn] = cur.copyWith(score: cur.score + lines.length * 10);
      _sound.play(AppSound.sos);
    } else {
      _sound.play(AppSound.point);
    }
    final full = newBoard.every((c) => c.isNotEmpty);
    final nextTurn = scored ? state.currentTurn : (state.currentTurn + 1) % players.length;
    int? winner;
    bool finished = false;
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
      _sound.play(winner != null ? AppSound.win : AppSound.lose);
    }
    state = state.copyWith(
      board: newBoard,
      players: players,
      currentTurn: nextTurn,
      finished: finished,
      winnerIndex: winner,
      lastSosLines: lines,
    );
  }
}

final localGameProvider =
    NotifierProvider.family<LocalGameController, LocalGameState, LocalGameConfig>(
  LocalGameController.new,
);

/// ---------- ONLINE GAME ----------
final gameRoomProvider = StreamProvider.family<GameRoom?, String>(
  (ref, roomId) => ref.watch(gameRepositoryProvider).watchRoom(roomId),
);
