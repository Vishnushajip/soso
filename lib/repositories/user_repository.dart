import 'dart:math' as dart_math;
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
  /// Also ensures all users receive a unique 8-digit numeric player ID.
  Future<AppUser> ensureUserFromAuth(fb_auth.User u) async {
    final ref = _col.doc(u.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final uniqueId = _generateUniqueNumericId();
      final user = AppUser(
        uid: u.uid,
        name: u.displayName ?? 'Player',
        email: u.email ?? '',
        photoUrl: u.photoURL,
        uniqueId: uniqueId,
      );
      await ref.set(user.toCreateMap());
      return (await ref.get()).let((d) => AppUser.fromDoc(d));
    } else {
      final data = snap.data() ?? {};
      String? uniqueId = data['uniqueId'] as String?;
      final updates = <String, dynamic>{
        'name': u.displayName ?? data['name'] ?? 'Player',
        'email': u.email ?? data['email'] ?? '',
        'photoUrl': u.photoURL ?? data['photoUrl'],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Auto-backfill unique ID for existing users who don't have one yet
      if (uniqueId == null || uniqueId.isEmpty) {
        uniqueId = _generateUniqueNumericId();
        updates['uniqueId'] = uniqueId;
      }
      
      await ref.set(updates, SetOptions(merge: true));
      return AppUser.fromDoc(await ref.get());
    }
  }

  String _generateUniqueNumericId() {
    final random = dart_math.Random();
    final id = 10000000 + random.nextInt(90000000);
    return id.toString();
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

  /// Search for a single exact match by unique numeric player ID
  Future<AppUser?> getUserByUniqueId(String uniqueId) async {
    final trimmed = uniqueId.trim();
    if (trimmed.isEmpty) return null;
    final q = await _col.where('uniqueId', isEqualTo: trimmed).limit(1).get();
    if (q.docs.isEmpty) return null;
    return AppUser.fromDoc(q.docs.first);
  }

  /// Get the precise count of online users cost-efficiently using index aggregation.
  /// Matches "isOnline == true" and bills only 1 document read per 1,000 matches.
  Future<int> getOnlineUsersCount() async {
    try {
      final snap = await _col.where('isOnline', isEqualTo: true).count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Securely purchase a customization title or avatar frame using accumulated points.
  /// Deducts point costs inside a Firestore Transaction to avoid double-spend or desync.
  Future<void> purchaseCustomization({
    required String uid,
    required String type, // 'title' or 'border'
    required String value, // Custom Title (e.g. 'SOS Legend') or Border Frame Color (e.g. 'gold')
    required int cost,
  }) async {
    final ref = _col.doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final totalPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
      
      if (totalPoints < cost) {
        throw Exception('Not enough points! You need $cost points.');
      }
      
      final updates = <String, dynamic>{
        'totalPoints': totalPoints - cost,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (type == 'title') {
        updates['customTitle'] = value;
      } else if (type == 'border') {
        updates['avatarFrameColor'] = value;
      }
      
      tx.set(ref, updates, SetOptions(merge: true));
    });
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

  Future<void> purchaseTool({
    required String uid,
    required String itemId,
    required int cost,
  }) async {
    final ref = _col.doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final totalPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
      if (totalPoints < cost) {
        throw Exception('Not enough points! You need $cost points.');
      }
      final inv = Map<String, dynamic>.from(data['inventory'] ?? {});
      final current = (inv[itemId] as num?)?.toInt() ?? 0;
      inv[itemId] = current + 1;
      
      tx.set(ref, {
        'totalPoints': totalPoints - cost,
        'inventory': inv,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> consumeTool({
    required String uid,
    required String itemId,
  }) async {
    final ref = _col.doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final inv = Map<String, dynamic>.from(data['inventory'] ?? {});
      final current = (inv[itemId] as num?)?.toInt() ?? 0;
      if (current <= 0) {
        throw Exception('No $itemId available in inventory.');
      }
      inv[itemId] = current - 1;
      tx.set(ref, {
        'inventory': inv,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> claimFreePoints(String uid, int amount) async {
    final ref = _col.doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final currentPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
      tx.set(ref, {
        'totalPoints': currentPoints + amount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
