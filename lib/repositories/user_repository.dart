import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';

class UserRepository {
  UserRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.usersCollection);

  Stream<AppUser?> watchUser(String uid) =>
      _col.doc(uid).snapshots().map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Future<AppUser?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  /// Create the Firestore user doc on first sign-in. If it already exists,
  /// only update the fields that may have changed in the Auth profile.
  Future<AppUser> ensureUserFromAuth(fb_auth.User u) async {
    final ref = _col.doc(u.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final user = AppUser(uid: u.uid, name: u.displayName ?? 'Player', email: u.email ?? '', photoUrl: u.photoURL);
      await ref.set(user.toCreateMap());
      return (await ref.get()).let((d) => AppUser.fromDoc(d));
    } else {
      await ref.set({
        'name': u.displayName ?? snap.data()?['name'] ?? 'Player',
        'email': u.email ?? snap.data()?['email'] ?? '',
        'photoUrl': u.photoURL ?? snap.data()?['photoUrl'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return AppUser.fromDoc(await ref.get());
    }
  }

  Future<void> updateProfile({required String uid, required String name}) async {
    await _col.doc(uid).set({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<AppUser>> searchByName(String query, {int limit = 20}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final q = await _col
        .orderBy('name')
        .startAt([trimmed])
        .endAt(['$trimmed'])
        .limit(limit)
        .get();
    return q.docs.map(AppUser.fromDoc).toList();
  }

  Future<void> applyMatchResult({
    required String uid,
    required int pointsDelta,
    required bool won,
  }) async {
    final ref = _col.doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final wins = ((data['wins'] as num?)?.toInt() ?? 0) + (won ? 1 : 0);
      final losses = ((data['losses'] as num?)?.toInt() ?? 0) + (won ? 0 : 1);
      final matchesPlayed = ((data['matchesPlayed'] as num?)?.toInt() ?? 0) + 1;
      final totalPoints = ((data['totalPoints'] as num?)?.toInt() ?? 0) + pointsDelta;
      final weeklyPoints = ((data['weeklyPoints'] as num?)?.toInt() ?? 0) + pointsDelta;
      final monthlyPoints = ((data['monthlyPoints'] as num?)?.toInt() ?? 0) + pointsDelta;
      final winRate = matchesPlayed == 0 ? 0.0 : wins / matchesPlayed;

      tx.set(ref, {
        'wins': wins,
        'losses': losses,
        'matchesPlayed': matchesPlayed,
        'totalPoints': totalPoints,
        'weeklyPoints': weeklyPoints,
        'monthlyPoints': monthlyPoints,
        'winRate': winRate,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
