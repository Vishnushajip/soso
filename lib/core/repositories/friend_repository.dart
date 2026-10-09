import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../utils/id_utils.dart';
import '../models/friend_request.dart';
import '../models/friendship.dart';

class FriendRepository {
  FriendRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reqs =>
      _firestore.collection(AppConstants.friendRequestsCollection);
  CollectionReference<Map<String, dynamic>> get _friends =>
      _firestore.collection(AppConstants.friendsCollection);
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);
  CollectionReference<Map<String, dynamic>> get _notifs =>
      _firestore.collection(AppConstants.notificationsCollection);

  Stream<List<FriendRequest>> watchIncoming(String uid) => _reqs
      .where('toUid', isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(FriendRequest.fromDoc).toList());

  Stream<List<FriendRequest>> watchOutgoing(String uid) => _reqs
      .where('fromUid', isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(FriendRequest.fromDoc).toList());

  Stream<List<Friendship>> watchFriends(String uid) => _friends
      .where('users', arrayContains: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Friendship.fromDoc).toList());

  Future<bool> isAlreadyFriend(String a, String b) async {
    final id = IdUtils.friendshipId(a, b);
    return (await _friends.doc(id).get()).exists;
  }

  Future<void> sendRequest({
    required String fromUid,
    required String fromName,
    String? fromPhoto,
    required String toUid,
    String? toName,
    String? toPhoto,
  }) async {
    if (fromUid == toUid) {
      throw ArgumentError("Can't friend yourself");
    }
    if (await isAlreadyFriend(fromUid, toUid)) {
      throw StateError('Already friends');
    }
    // Prevent duplicate pending requests in either direction.
    final existing = await _reqs
        .where('status', isEqualTo: 'pending')
        .where('fromUid', whereIn: [fromUid, toUid])
        .where('toUid', whereIn: [fromUid, toUid])
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) throw StateError('A pending request already exists');

    final ref = _reqs.doc();
    await ref.set({
      'fromUid': fromUid,
      'toUid': toUid,
      'fromName': fromName,
      'fromPhoto': fromPhoto,
      'toName': toName,
      'toPhoto': toPhoto,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _notifs.add({
      'toUid': toUid,
      'type': 'friendRequest',
      'title': 'New friend request',
      'body': '$fromName wants to be friends',
      'data': {'fromUid': fromUid, 'requestId': ref.id},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptRequest(FriendRequest req, String myName) async {
    final id = IdUtils.friendshipId(req.fromUid, req.toUid);
    final batch = _firestore.batch();
    batch.update(_reqs.doc(req.id), {
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_friends.doc(id), {
      'users': [req.fromUid, req.toUid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_users.doc(req.fromUid), {
      'friendsCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    batch.set(_users.doc(req.toUid), {
      'friendsCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    batch.set(_notifs.doc(), {
      'toUid': req.fromUid,
      'type': 'friendAccepted',
      'title': 'Friend request accepted',
      'body': '$myName accepted your friend request',
      'data': {'fromUid': req.toUid},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> rejectRequest(FriendRequest req) =>
      _reqs.doc(req.id).update({'status': 'rejected', 'respondedAt': FieldValue.serverTimestamp()});

  Future<void> removeFriend({required String me, required String other}) async {
    final id = IdUtils.friendshipId(me, other);
    final batch = _firestore.batch();
    batch.delete(_friends.doc(id));
    batch.set(_users.doc(me), {'friendsCount': FieldValue.increment(-1)}, SetOptions(merge: true));
    batch.set(_users.doc(other), {'friendsCount': FieldValue.increment(-1)}, SetOptions(merge: true));
    await batch.commit();
  }
}
