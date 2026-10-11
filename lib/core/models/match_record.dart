import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/sos_engine.dart';

class MatchMoveRecord {
  final int position;
  final String letter; // 'S' | 'O'
  final int playerIndex; // 0 or 1
  final int sosCount;
  final List<SosLine> linesCreated;

  const MatchMoveRecord({
    required this.position,
    required this.letter,
    required this.playerIndex,
    this.sosCount = 0,
    this.linesCreated = const [],
  });

  Map<String, dynamic> toMap() => {
        'pos': position,
        'let': letter,
        'pIdx': playerIndex,
        'sos': sosCount,
        'lines': linesCreated.map((l) => [l.a, l.b, l.c]).toList(),
      };

  factory MatchMoveRecord.fromMap(Map<String, dynamic> map) {
    final rawLines = (map['lines'] as List?) ?? const [];
    final lines = <SosLine>[];
    for (final r in rawLines) {
      if (r is List && r.length >= 3) {
        lines.add(SosLine(
          (r[0] as num).toInt(),
          (r[1] as num).toInt(),
          (r[2] as num).toInt(),
        ));
      }
    }
    return MatchMoveRecord(
      position: (map['pos'] as num?)?.toInt() ?? 0,
      letter: (map['let'] as String?) ?? 'S',
      playerIndex: (map['pIdx'] as num?)?.toInt() ?? 0,
      sosCount: (map['sos'] as num?)?.toInt() ?? 0,
      linesCreated: lines,
    );
  }
}

class MatchRecord {
  final String id;
  final String gameType; // 'ranked' | 'friend' | 'bot' | 'local'
  final int boardSize;
  final String p1Name;
  final int p1Score;
  final String? p1PhotoUrl;
  final String p2Name;
  final int p2Score;
  final String? p2PhotoUrl;
  final String? winnerName;
  final int? winnerIndex; // 0, 1, or null (tie)
  final DateTime playedAt;
  final List<MatchMoveRecord> moves;

  const MatchRecord({
    required this.id,
    required this.gameType,
    required this.boardSize,
    required this.p1Name,
    required this.p1Score,
    this.p1PhotoUrl,
    required this.p2Name,
    required this.p2Score,
    this.p2PhotoUrl,
    this.winnerName,
    this.winnerIndex,
    required this.playedAt,
    required this.moves,
  });

  bool get isTie => winnerIndex == null;
  bool get isDraw => winnerIndex == null;
  bool get isAi => gameType == 'bot' || gameType == 'ai';
  bool get isLocal => gameType == 'local';
  bool get isOnline => gameType == 'online' || gameType == 'ranked' || gameType == 'friend';
  int get totalMoves => moves.length;
  bool get player1Won => winnerIndex == 0;
  bool get player2Won => winnerIndex == 1;

  Map<String, dynamic> toMap() => {
        'id': id,
        'gameType': gameType,
        'boardSize': boardSize,
        'p1Name': p1Name,
        'p1Score': p1Score,
        'p1PhotoUrl': p1PhotoUrl,
        'p2Name': p2Name,
        'p2Score': p2Score,
        'p2PhotoUrl': p2PhotoUrl,
        'winnerName': winnerName,
        'winnerIndex': winnerIndex,
        'playedAt': Timestamp.fromDate(playedAt),
        'moves': moves.map((m) => m.toMap()).toList(),
      };

  factory MatchRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final rawMoves = (d['moves'] as List?) ?? const [];
    return MatchRecord(
      id: doc.id,
      gameType: (d['gameType'] as String?) ?? 'local',
      boardSize: (d['boardSize'] as num?)?.toInt() ?? 8,
      p1Name: (d['p1Name'] as String?) ?? 'Player 1',
      p1Score: (d['p1Score'] as num?)?.toInt() ?? 0,
      p1PhotoUrl: d['p1PhotoUrl'] as String?,
      p2Name: (d['p2Name'] as String?) ?? 'Player 2',
      p2Score: (d['p2Score'] as num?)?.toInt() ?? 0,
      p2PhotoUrl: d['p2PhotoUrl'] as String?,
      winnerName: d['winnerName'] as String?,
      winnerIndex: (d['winnerIndex'] as num?)?.toInt(),
      playedAt: (d['playedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      moves: rawMoves
          .map((m) => MatchMoveRecord.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
    );
  }

  factory MatchRecord.fromMap(Map<String, dynamic> d) {
    final rawMoves = (d['moves'] as List?) ?? const [];
    return MatchRecord(
      id: (d['id'] as String?) ?? '',
      gameType: (d['gameType'] as String?) ?? 'local',
      boardSize: (d['boardSize'] as num?)?.toInt() ?? 8,
      p1Name: (d['p1Name'] as String?) ?? 'Player 1',
      p1Score: (d['p1Score'] as num?)?.toInt() ?? 0,
      p1PhotoUrl: d['p1PhotoUrl'] as String?,
      p2Name: (d['p2Name'] as String?) ?? 'Player 2',
      p2Score: (d['p2Score'] as num?)?.toInt() ?? 0,
      p2PhotoUrl: d['p2PhotoUrl'] as String?,
      winnerName: d['winnerName'] as String?,
      winnerIndex: (d['winnerIndex'] as num?)?.toInt(),
      playedAt: d['playedAt'] is Timestamp
          ? (d['playedAt'] as Timestamp).toDate()
          : DateTime.tryParse((d['playedAt'] as String?) ?? '') ?? DateTime.now(),
      moves: rawMoves
          .map((m) => MatchMoveRecord.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
    );
  }
}
