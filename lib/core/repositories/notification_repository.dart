import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.notificationsCollection);

  Stream<List<AppNotification>> watchFor(String uid, {int limit = 50}) => _col
      .where('toUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(AppNotification.fromDoc).toList());

  Stream<int> watchUnreadCount(String uid) => _col
      .where('toUid', isEqualTo: uid)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length);

  Future<void> markRead(String id) =>
      _col.doc(id).update({'read': true});

  Future<void> markAllRead(String uid) async {
    final batch = _firestore.batch();
    final unread = await _col
        .where('toUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
