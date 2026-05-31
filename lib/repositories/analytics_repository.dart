import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

/// Firestore-backed admin analytics counters. Kept thin — heavy aggregation
/// (DAU, MAU, peak concurrent) should be done with scheduled Cloud Functions
/// rolling up to `analytics/daily/{yyyy-MM-dd}` documents.
class AnalyticsRepository {
  AnalyticsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.analyticsCollection);

  Stream<int> watchOnlineUsers() => _firestore
      .collection(AppConstants.usersCollection)
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.length);

  Future<Map<String, dynamic>> getOverview() async {
    final doc = await _col.doc('overview').get();
    return doc.data() ?? const {};
  }

  Future<void> bumpCounter(String field, [int by = 1]) async {
    await _col.doc('overview').set({field: FieldValue.increment(by)}, SetOptions(merge: true));
  }
}
