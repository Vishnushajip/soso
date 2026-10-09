import 'package:cloud_firestore/cloud_firestore.dart';

class GameMove {
  final String id;
  final String roomId;
  final String playerId;
  final int position;
  final String letter; // 'S' | 'O'
  final int sosCount;
  final DateTime? createdAt;

  const GameMove({
    required this.id,
    required this.roomId,
    required this.playerId,
    required this.position,
    required this.letter,
    required this.sosCount,
    this.createdAt,
  });

  factory GameMove.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return GameMove(
      id: doc.id,
      roomId: (d['roomId'] as String?) ?? '',
      playerId: (d['playerId'] as String?) ?? '',
      position: (d['position'] as num?)?.toInt() ?? 0,
      letter: (d['letter'] as String?) ?? '',
      sosCount: (d['sosCount'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
