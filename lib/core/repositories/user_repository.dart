import 'dart:math' as dart_math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../constants/app_constants.dart';
import '../models/app_user.dart';

class UserRepository {
  UserRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.usersCollection);

  Stream<AppUser?> watchUser(String uid) => _col
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Future<AppUser?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  /// Create the Firestore user doc on first sign-in. If it already exists,
  /// only update the fields that may have changed in the Auth profile.
  /// Also ensures all users receive a unique 8-digit numeric player ID.
  Future<AppUser> ensureUserFromAuth(
    fb_auth.User u, {
    bool isGuest = false,
  }) async {
    final ref = _col.doc(u.uid);
    final snap = await ref.get();
    final isGuestAccount = isGuest || u.isAnonymous;

    if (!snap.exists) {
      final uniqueId = _generateUniqueNumericId();
      final guestSuffix = dart_math.Random().nextInt(9000) + 10;
      final email = isGuestAccount
          ? (u.email != null && u.email!.isNotEmpty
                ? u.email!
                : 'guest$guestSuffix@gmail.com')
          : (u.email ?? '');
      final name = isGuestAccount
          ? (u.displayName ?? 'Guest $guestSuffix')
          : (u.displayName ?? 'Player');

      final user = AppUser(
        uid: u.uid,
        name: name,
        email: email,
        photoUrl: u.photoURL,
        uniqueId: uniqueId,
        isGuest: isGuestAccount,
      );
      await ref.set(user.toCreateMap());
      return AppUser.fromDoc(await ref.get());
    } else {
      final data = snap.data() ?? {};
      String? uniqueId = data['uniqueId'] as String?;
      final previousIsGuest = (data['isGuest'] as bool?) ?? false;
      final stillGuest =
          isGuestAccount &&
          previousIsGuest &&
          (u.email == null || u.email!.isEmpty || u.email!.startsWith('guest'));

      final updates = <String, dynamic>{
        'name': (data['name'] as String?)?.isNotEmpty == true
            ? data['name']
            : (stillGuest ? 'Guest' : (u.displayName ?? 'Player')),
        'email': (!stillGuest && u.email != null && u.email!.isNotEmpty)
            ? u.email
            : (data['email'] ??
                  (stillGuest ? 'guest${uniqueId ?? "0"}@gmail.com' : '')),
        'photoUrl': data.containsKey('photoUrl')
            ? data['photoUrl']
            : u.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
        'isGuest': stillGuest,
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

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? photoUrl,
    bool removePhoto = false,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
    }
    if (removePhoto) {
      updates['photoUrl'] = FieldValue.delete();
    } else if (photoUrl != null) {
      updates['photoUrl'] = photoUrl;
    }

    await _col.doc(uid).set(updates, SetOptions(merge: true));

    try {
      final authUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (authUser != null && authUser.uid == uid) {
        if (name != null && name.trim().isNotEmpty) {
          await authUser.updateDisplayName(name.trim());
        }
        if (removePhoto) {
          await authUser.updatePhotoURL(null);
        } else if (photoUrl != null && !photoUrl.startsWith('data:')) {
          await authUser.updatePhotoURL(photoUrl);
        }
      }
    } catch (_) {}
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

  /// Get the precise count of online users.
  /// Considers a user online if their lastSeen is within 30 seconds of the current time
  /// (whether isOnline is true, or even if isOnline is false but lastSeen is within 30s).
  Future<int> getOnlineUsersCount() async {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 30));
    try {
      final snap = await _col
          .where('lastSeen', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      try {
        final snap = await _col.where('isOnline', isEqualTo: true).get();
        final now = DateTime.now();
        int active = 0;
        for (final doc in snap.docs) {
          final lastSeen = (doc.data()['lastSeen'] as Timestamp?)?.toDate();
          if (lastSeen != null) {
            final diff = now.difference(lastSeen).inSeconds;
            if (diff <= 30 && diff >= -60) {
              active++;
            }
          }
        }
        return active;
      } catch (_) {
        return 0;
      }
    }
  }

  /// Securely purchase a customization title or avatar frame using accumulated points.
  /// Deducts point costs inside a Firestore Transaction to avoid double-spend or desync.
  Future<void> purchaseCustomization({
    required String uid,
    required String type, // 'title' or 'border'
    required String
    value, // Custom Title (e.g. 'SOS Legend') or Border Frame Color (e.g. 'gold')
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
      final totalPoints =
          ((data['totalPoints'] as num?)?.toInt() ?? 0) + pointsDelta;
      final weeklyPoints =
          ((data['weeklyPoints'] as num?)?.toInt() ?? 0) + pointsDelta;
      final monthlyPoints =
          ((data['monthlyPoints'] as num?)?.toInt() ?? 0) + pointsDelta;
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

  Future<DailyStreakRewardResult> claimDailyReward({
    required String uid,
  }) async {
    final ref = _col.doc(uid);
    final now = DateTime.now();
    final todayStr = _localDateStr(now);
    final yesterdayStr = _localDateStr(now.subtract(const Duration(days: 1)));

    return await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('User profile not found.');
      }
      final data = snap.data() ?? {};
      final lastClaimDate = data['lastStreakClaimDate'] as String?;
      final currentStreak = (data['dailyStreak'] as num?)?.toInt() ?? 0;
      final longestStreak = (data['longestStreak'] as num?)?.toInt() ?? 0;

      // Idempotency guard: already claimed today — return safe no-op result.
      if (lastClaimDate == todayStr) {
        return DailyStreakRewardResult(
          newStreak: currentStreak,
          pointsAwarded: 0,
          alreadyClaimed: true,
          message: 'Already claimed today! Check back tomorrow.',
        );
      }

      int newStreak;
      if (lastClaimDate == yesterdayStr) {
        // Consecutive day: extend the streak.
        newStreak = currentStreak + 1;
      } else {
        // First claim ever (lastClaimDate == null) or broken streak.
        newStreak = 1;
      }

      final dayInCycle = ((newStreak - 1) % 7) + 1; // 1 to 7

      int pointsAwarded = 0;
      final itemsAwarded = <String, int>{};

      switch (dayInCycle) {
        case 1:
          pointsAwarded = 50;
          break;
        case 2:
          pointsAwarded = 100;
          break;
        case 3:
          pointsAwarded = 150;
          itemsAwarded['undo_move'] = 1;
          break;
        case 4:
          pointsAwarded = 200;
          break;
        case 5:
          pointsAwarded = 300;
          itemsAwarded['erase_cell'] = 1;
          break;
        case 6:
          pointsAwarded = 400;
          break;
        case 7:
        default:
          pointsAwarded = 600;
          itemsAwarded['hint_vision'] = 1;
          itemsAwarded['erase_cell'] = 1;
          break;
      }

      final currentPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
      final inv = Map<String, dynamic>.from(data['inventory'] ?? {});
      for (final entry in itemsAwarded.entries) {
        final curCount = (inv[entry.key] as num?)?.toInt() ?? 0;
        inv[entry.key] = curCount + entry.value;
      }

      final updatedLongest = newStreak > longestStreak
          ? newStreak
          : longestStreak;

      tx.set(ref, {
        'totalPoints': currentPoints + pointsAwarded,
        'dailyStreak': newStreak,
        'lastStreakClaimDate': todayStr,
        'longestStreak': updatedLongest,
        'inventory': inv,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return DailyStreakRewardResult(
        newStreak: newStreak,
        pointsAwarded: pointsAwarded,
        itemsAwarded: itemsAwarded,
        alreadyClaimed: false,
        message: 'Day $dayInCycle Reward Claimed! +$pointsAwarded points 🔥',
      );
    });
  }

  /// Consistent local-date string helper: YYYY-MM-DD using the device's local clock.
  static String _localDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

class DailyStreakRewardResult {
  final int newStreak;
  final int pointsAwarded;
  final Map<String, int> itemsAwarded;
  final bool alreadyClaimed;
  final String message;

  const DailyStreakRewardResult({
    required this.newStreak,
    required this.pointsAwarded,
    this.itemsAwarded = const {},
    this.alreadyClaimed = false,
    required this.message,
  });
}
