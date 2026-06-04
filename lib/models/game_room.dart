import 'package:cloud_firestore/cloud_firestore.dart';

enum GameRoomType { quick, ranked, private, friend }

enum GameRoomStatus { waiting, active, finished, abandoned }

class GamePlayer {
  final String uid;
  final String name;
  final String? photoUrl;
  final int score;
  final bool ready;

  const GamePlayer({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.score = 0,
    this.ready = false,
  });

  factory GamePlayer.fromMap(Map<String, dynamic> d) => GamePlayer(
        uid: (d['uid'] as String?) ?? '',
        name: (d['name'] as String?) ?? '',
        photoUrl: d['photoUrl'] as String?,
        score: (d['score'] as num?)?.toInt() ?? 0,
        ready: (d['ready'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'photoUrl': photoUrl,
        'score': score,
        'ready': ready,
      };

  GamePlayer copyWith({int? score, bool? ready}) =>
      GamePlayer(uid: uid, name: name, photoUrl: photoUrl, score: score ?? this.score, ready: ready ?? this.ready);
}

class GameRoom {
  final String id;
  final String? code;
  final GameRoomType type;
  final GameRoomStatus status;
  final String hostId;
  final List<GamePlayer> players;
  final List<String> playerIds;
  final int maxPlayers;
  final int boardSize;
  final List<String> board;
  final int currentTurn;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? winnerId;
  final int? lastPlacedPosition;
  final String? lastPlacedLetter;
  final String? lastPlacedPlayerId;
  final bool magicEnabled;

  const GameRoom({
    required this.id,
    this.code,
    required this.type,
    required this.status,
    required this.hostId,
    required this.players,
    required this.playerIds,
    required this.maxPlayers,
    required this.boardSize,
    required this.board,
    required this.currentTurn,
    this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.winnerId,
    this.lastPlacedPosition,
    this.lastPlacedLetter,
    this.lastPlacedPlayerId,
    this.magicEnabled = true,
  });

  factory GameRoom.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return GameRoom(
      id: doc.id,
      code: d['code'] as String?,
      type: GameRoomType.values.firstWhere(
        (t) => t.name == (d['type'] as String?),
        orElse: () => GameRoomType.quick,
      ),
      status: GameRoomStatus.values.firstWhere(
        (s) => s.name == (d['status'] as String?),
        orElse: () => GameRoomStatus.waiting,
      ),
      hostId: (d['hostId'] as String?) ?? '',
      players: ((d['players'] as List?) ?? const [])
          .map((p) => GamePlayer.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
      playerIds: ((d['playerIds'] as List?) ?? const []).cast<String>(),
      maxPlayers: (d['maxPlayers'] as num?)?.toInt() ?? 2,
      boardSize: (d['boardSize'] as num?)?.toInt() ?? 8,
      board: ((d['board'] as List?) ?? const []).cast<String>(),
      currentTurn: (d['currentTurn'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
      finishedAt: (d['finishedAt'] as Timestamp?)?.toDate(),
      winnerId: d['winnerId'] as String?,
      lastPlacedPosition: (d['lastPlacedPosition'] as num?)?.toInt(),
      lastPlacedLetter: d['lastPlacedLetter'] as String?,
      lastPlacedPlayerId: d['lastPlacedPlayerId'] as String?,
      magicEnabled: (d['magicEnabled'] as bool?) ?? true,
    );
  }
}
