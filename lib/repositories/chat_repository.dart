import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/id_utils.dart';
import '../models/chat_room.dart';
import '../models/message.dart';

class ChatRepository {
  ChatRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection(AppConstants.chatRoomsCollection);
  CollectionReference<Map<String, dynamic>> get _friends =>
      _firestore.collection(AppConstants.friendsCollection);
  CollectionReference<Map<String, dynamic>> get _notifs =>
      _firestore.collection(AppConstants.notificationsCollection);

  CollectionReference<Map<String, dynamic>> _msgs(String roomId) =>
      _rooms.doc(roomId).collection(AppConstants.messagesSubcollection);

  Stream<List<ChatRoom>> watchMyRooms(String uid) => _rooms
      .where('participants', arrayContains: uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ChatRoom.fromDoc).toList());

  Stream<List<Message>> watchMessages(String roomId, {int limit = 50}) => _msgs(roomId)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Message.fromDoc).toList().reversed.toList());

  /// Creates (or reuses) a 1-to-1 direct chat. Throws if the two users
  /// are not friends — strangers cannot DM.
  Future<ChatRoom> openDirectChat({required String me, required String other}) async {
    final friendshipId = IdUtils.friendshipId(me, other);
    final friendDoc = await _friends.doc(friendshipId).get();
    if (!friendDoc.exists) {
      throw StateError('You can only chat with accepted friends.');
    }

    final roomId = IdUtils.directChatRoomId(me, other);
    final ref = _rooms.doc(roomId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'type': 'direct',
        'participants': [me, other],
        'lastMessage': null,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {me: 0, other: 0},
      });
    }
    return ChatRoom.fromDoc(await ref.get());
  }

  Future<ChatRoom> ensureGlobalRoom() async {
    final ref = _rooms.doc(AppConstants.globalChatRoomId);
    if (!(await ref.get()).exists) {
      await ref.set({
        'type': 'global',
        'participants': <String>[],
        'title': 'Global Chat',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
    return ChatRoom.fromDoc(await ref.get());
  }

  Future<ChatRoom> ensureMatchRoom({required String roomId, required List<String> participants}) async {
    final ref = _rooms.doc('match_$roomId');
    if (!(await ref.get()).exists) {
      await ref.set({
        'type': 'match',
        'participants': participants,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'title': 'Match Chat',
      });
    }
    return ChatRoom.fromDoc(await ref.get());
  }

  Future<void> sendMessage({
    required ChatRoom room,
    required String senderId,
    required String senderName,
    String? senderPhoto,
    required String text,
  }) async {
    final ref = _msgs(room.id).doc();
    final batch = _firestore.batch();
    batch.set(ref, {
      'roomId': room.id,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final unreadUpdate = <String, dynamic>{};
    for (final p in room.participants) {
      if (p != senderId) unreadUpdate['unreadCount.$p'] = FieldValue.increment(1);
    }
    batch.update(_rooms.doc(room.id), {
      'lastMessage': text,
      'lastMessageBy': senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      ...unreadUpdate,
    });

    if (room.type == ChatRoomType.direct) {
      for (final p in room.participants) {
        if (p == senderId) continue;
        batch.set(_notifs.doc(), {
          'toUid': p,
          'type': 'message',
          'title': senderName,
          'body': text.length > 80 ? '${text.substring(0, 80)}…' : text,
          'data': {'roomId': room.id, 'senderId': senderId},
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<void> markRead({required String roomId, required String uid}) =>
      _rooms.doc(roomId).set({'unreadCount.$uid': 0}, SetOptions(merge: true));
}
