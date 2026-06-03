import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/env.dart';
import '../core/utils/id_utils.dart';
import '../core/utils/logger.dart';
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

  Stream<List<Message>> watchMessages(String roomId, {int limit = 50}) =>
      _msgs(roomId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(Message.fromDoc).toList().reversed.toList());

  Future<ChatRoom> openDirectChat({
    required String me,
    required String other,
  }) async {
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

  Future<ChatRoom> ensureMatchRoom({
    required String roomId,
    required List<String> participants,
  }) async {
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
    String status = 'sent';
    bool otherOnline = false;
    String? otherUid;

    if (room.type == ChatRoomType.direct) {
      for (final p in room.participants) {
        if (p != senderId) {
          otherUid = p;
          break;
        }
      }
      if (otherUid != null) {
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(otherUid)
            .get();
        otherOnline = userDoc.data()?['isOnline'] as bool? ?? false;
        if (otherOnline) {
          status = 'delivered';
        }
      }
    }

    final ref = _msgs(room.id).doc();
    final batch = _firestore.batch();
    batch.set(ref, {
      'roomId': room.id,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
    });
    final unreadUpdate = <String, dynamic>{};
    for (final p in room.participants) {
      if (p != senderId) {
        unreadUpdate['unreadCount.$p'] = FieldValue.increment(1);
      }
    }
    batch.update(_rooms.doc(room.id), {
      'lastMessage': text,
      'lastMessageBy': senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      ...unreadUpdate,
    });

    if (room.type == ChatRoomType.direct && otherUid != null) {
      batch.set(_notifs.doc(), {
        'toUid': otherUid,
        'type': 'message',
        'title': senderName,
        'body': text.length > 80 ? '${text.substring(0, 80)}…' : text,
        'data': {'roomId': room.id, 'senderId': senderId},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(otherUid)
          .get();
      final recipientFcmToken = userDoc.data()?['fcmToken'] as String?;
      if (recipientFcmToken != null && recipientFcmToken.isNotEmpty) {
        _sendFcmPush(
          recipientFcmToken: recipientFcmToken,
          senderName: senderName,
          text: text,
          roomId: room.id,
          senderId: senderId,
        );
      }
    } else if (room.type == ChatRoomType.match) {
      final otherParticipants = room.participants
          .where((p) => p != senderId)
          .toList();
      for (final recipientId in otherParticipants) {
        batch.set(_notifs.doc(), {
          'toUid': recipientId,
          'type': 'message',
          'title': senderName,
          'body': text.length > 80 ? '${text.substring(0, 80)}…' : text,
          'data': {'roomId': room.id, 'senderId': senderId},
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(recipientId)
            .get();
        final recipientFcmToken = userDoc.data()?['fcmToken'] as String?;
        if (recipientFcmToken != null && recipientFcmToken.isNotEmpty) {
          _sendFcmPush(
            recipientFcmToken: recipientFcmToken,
            senderName: senderName,
            text: text,
            roomId: room.id,
            senderId: senderId,
          );
        }
      }
    }
    await batch.commit();
  }

  Future<void> _sendFcmPush({
    required String recipientFcmToken,
    required String senderName,
    required String text,
    required String roomId,
    required String senderId,
  }) async {
    appLogger.d(
      'Sending direct V1 FCM push:\n'
      ' - Sender Name: $senderName\n'
      ' - Text: $text\n'
      ' - Room ID: $roomId\n'
      ' - Sender ID: $senderId\n'
      ' - Recipient FCM Token: $recipientFcmToken',
    );

    final serviceAccountJsonString = Env.fcmServiceAccountJson;
    if (serviceAccountJsonString.isEmpty) {
      appLogger.w(
        'FCM_SERVICE_ACCOUNT_JSON is not configured in .env. Skipping direct V1 FCM push.',
      );
      return;
    }

    try {
      final accountMap =
          jsonDecode(serviceAccountJsonString) as Map<String, dynamic>;

      if (accountMap.containsKey('private_key')) {
        accountMap['private_key'] = (accountMap['private_key'] as String)
            .replaceAll(r'\n', '\n')
            .replaceAll('\\n', '\n');
      }

      final accountCredentials = ServiceAccountCredentials.fromJson(accountMap);

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );
      final accessToken = authClient.credentials.accessToken.data;
      final projectId = accountMap['project_id'] as String;

      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
        ),
      );

      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $accessToken');

      final payload = {
        'message': {
          'token': recipientFcmToken,
          'notification': {
            'title': senderName,
            'body': text.length > 80 ? '${text.substring(0, 80)}…' : text,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'notify',
              'channel_id': AppConstants.fcmChannelId,
            },
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'notify.mp3'},
            },
          },
          'data': {
            'roomId': roomId,
            'senderId': senderId,
            'type': 'message',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      request.write(jsonEncode(payload));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        appLogger.d('Direct V1 FCM push sent successfully: $responseBody');
      } else {
        appLogger.w(
          'Direct V1 FCM push failed with status code: ${response.statusCode}, body: $responseBody',
        );
      }

      authClient.close();
    } catch (e) {
      appLogger.e('Error sending direct V1 FCM push: $e');
    }
  }

  Future<void> markMessagesAsRead({
    required String roomId,
    required String myUid,
  }) async {
    final querySnap = await _msgs(
      roomId,
    ).where('senderId', isNotEqualTo: myUid).get();

    final batch = _firestore.batch();
    bool hasUpdates = false;
    for (final doc in querySnap.docs) {
      final status = doc.data()['status'] as String?;
      if (status != 'read') {
        batch.update(doc.reference, {'status': 'read'});
        hasUpdates = true;
      }
    }
    if (hasUpdates) {
      await batch.commit();
    }
  }

  Future<void> markRead({required String roomId, required String uid}) =>
      _rooms.doc(roomId).set({'unreadCount.$uid': 0}, SetOptions(merge: true));
}
