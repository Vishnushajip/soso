import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String uniqueId;
  final String? customTitle;
  final String? avatarFrameColor;
  final String? photoUrl;
  final String? fcmToken;
  final String? platform;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastTokenUpdate;
  final bool isOnline;
  final DateTime? lastSeen;
  final int totalPoints;
  final int weeklyPoints;
  final int monthlyPoints;
  final int wins;
  final int losses;
  final int matchesPlayed;
  final double winRate;
  final int friendsCount;
  final Map<String, int> inventory;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.uniqueId = '',
    this.customTitle,
    this.avatarFrameColor,
    this.photoUrl,
    this.fcmToken,
    this.platform,
    this.createdAt,
    this.updatedAt,
    this.lastTokenUpdate,
    this.isOnline = false,
    this.lastSeen,
    this.totalPoints = 0,
    this.weeklyPoints = 0,
    this.monthlyPoints = 0,
    this.wins = 0,
    this.losses = 0,
    this.matchesPlayed = 0,
    this.winRate = 0,
    this.friendsCount = 0,
    this.inventory = const {},
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      name: (d['name'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      uniqueId: (d['uniqueId'] as String?) ?? '',
      customTitle: d['customTitle'] as String?,
      avatarFrameColor: d['avatarFrameColor'] as String?,
      photoUrl: d['photoUrl'] as String?,
      fcmToken: d['fcmToken'] as String?,
      platform: d['platform'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      lastTokenUpdate: (d['lastTokenUpdate'] as Timestamp?)?.toDate(),
      isOnline: (d['isOnline'] as bool?) ?? false,
      lastSeen: (d['lastSeen'] as Timestamp?)?.toDate(),
      totalPoints: (d['totalPoints'] as num?)?.toInt() ?? 0,
      weeklyPoints: (d['weeklyPoints'] as num?)?.toInt() ?? 0,
      monthlyPoints: (d['monthlyPoints'] as num?)?.toInt() ?? 0,
      wins: (d['wins'] as num?)?.toInt() ?? 0,
      losses: (d['losses'] as num?)?.toInt() ?? 0,
      matchesPlayed: (d['matchesPlayed'] as num?)?.toInt() ?? 0,
      winRate: (d['winRate'] as num?)?.toDouble() ?? 0,
      friendsCount: (d['friendsCount'] as num?)?.toInt() ?? 0,
      inventory: Map<String, int>.from(
        (d['inventory'] as Map<dynamic, dynamic>?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'uniqueId': uniqueId,
        'customTitle': customTitle,
        'avatarFrameColor': avatarFrameColor,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'totalPoints': 0,
        'weeklyPoints': 0,
        'monthlyPoints': 0,
        'wins': 0,
        'losses': 0,
        'matchesPlayed': 0,
        'winRate': 0,
        'friendsCount': 0,
        'inventory': {},
      };
}
