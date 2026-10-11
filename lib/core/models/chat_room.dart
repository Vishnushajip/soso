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
      unreadCount: () {
        final map = <String, int>{};
        final rawMap = d['unreadCount'];
        if (rawMap is Map) {
          rawMap.forEach((k, v) {
            if (k != null && v is num) {
              map[k.toString()] = v.toInt();
            }
          });
        }
        d.forEach((k, v) {
          if (k.startsWith('unreadCount.') && v is num) {
            final uid = k.substring('unreadCount.'.length);
            final val = v.toInt();
            if (map.containsKey(uid)) {
              if (val == 0 || map[uid] == 0) {
                map[uid] = 0;
              } else {
                map[uid] = val;
              }
            } else {
              map[uid] = val;
            }
          }
        });
        return map;
      }(),
      title: d['title'] as String?,
    );
  }

  String otherUid(String me) =>
      participants.firstWhere((u) => u != me, orElse: () => '');
}
