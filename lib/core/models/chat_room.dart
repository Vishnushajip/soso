import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatRoomType { global, direct, match }

class ChatRoom {
  final String id;
  final ChatRoomType type;
  final List<String> participants;
  final String? lastMessage;
  final String? lastMessageBy;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;
  final String? title;

  const ChatRoom({
    required this.id,
    required this.type,
    required this.participants,
    this.lastMessage,
    this.lastMessageBy,
    this.lastMessageAt,
    this.unreadCount = const {},
    this.title,
  });

  factory ChatRoom.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return ChatRoom(
      id: doc.id,
      type: ChatRoomType.values.firstWhere(
        (t) => t.name == (d['type'] as String?),
        orElse: () => ChatRoomType.direct,
      ),
      participants: ((d['participants'] as List?) ?? const []).cast<String>(),
      lastMessage: d['lastMessage'] as String?,
      lastMessageBy: d['lastMessageBy'] as String?,
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: ((d['unreadCount'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
      title: d['title'] as String?,
    );
  }

  String otherUid(String me) =>
      participants.firstWhere((u) => u != me, orElse: () => '');
}
