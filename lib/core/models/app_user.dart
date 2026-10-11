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
  final bool isOnlineRaw;
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
  final bool isGuest;
  final int dailyStreak;
  final String? lastStreakClaimDate;
  final int longestStreak;

  /// Returns true if user can claim today's daily streak reward
  bool get canClaimDailyReward {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return lastStreakClaimDate != todayStr;
  }

  /// Returns true if the user is signed in as a guest.
  bool get isGuestUser =>
      isGuest || (email.startsWith('guest') && email.contains('@'));

  /// Returns true if lastSeen is within 30 seconds of current time.
  /// Considered online if lastSeen is within 30 seconds (not greater than 30s
  /// from current time), whether isOnline is true or false.
  bool get isOnline {
    if (lastSeen == null) return false;
    final diff = DateTime.now().difference(lastSeen!).inSeconds;
    return diff <= 30 && diff >= -60;
  }

  bool get isOnlineNow => isOnline;

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
    bool isOnline = false,
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
    this.isGuest = false,
    this.dailyStreak = 0,
    this.lastStreakClaimDate,
    this.longestStreak = 0,
  }) : isOnlineRaw = isOnline;

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
      isGuest: (d['isGuest'] as bool?) ??
          ((d['email'] as String?)?.startsWith('guest') == true),
      dailyStreak: (d['dailyStreak'] as num?)?.toInt() ?? 0,
      lastStreakClaimDate: d['lastStreakClaimDate'] as String?,
      longestStreak: (d['longestStreak'] as num?)?.toInt() ?? 0,
    );
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? uniqueId,
    String? customTitle,
    String? avatarFrameColor,
    String? photoUrl,
    String? fcmToken,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastTokenUpdate,
    bool? isOnline,
    DateTime? lastSeen,
    int? totalPoints,
    int? weeklyPoints,
    int? monthlyPoints,
    int? wins,
    int? losses,
    int? matchesPlayed,
    double? winRate,
    int? friendsCount,
    Map<String, int>? inventory,
    bool? isGuest,
    int? dailyStreak,
    String? lastStreakClaimDate,
    int? longestStreak,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      uniqueId: uniqueId ?? this.uniqueId,
      customTitle: customTitle ?? this.customTitle,
      avatarFrameColor: avatarFrameColor ?? this.avatarFrameColor,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastTokenUpdate: lastTokenUpdate ?? this.lastTokenUpdate,
      isOnline: isOnline ?? isOnlineRaw,
      lastSeen: lastSeen ?? this.lastSeen,
      totalPoints: totalPoints ?? this.totalPoints,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      monthlyPoints: monthlyPoints ?? this.monthlyPoints,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      winRate: winRate ?? this.winRate,
      friendsCount: friendsCount ?? this.friendsCount,
      inventory: inventory ?? this.inventory,
      isGuest: isGuest ?? this.isGuest,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastStreakClaimDate: lastStreakClaimDate ?? this.lastStreakClaimDate,
      longestStreak: longestStreak ?? this.longestStreak,
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
        'isGuest': isGuest,
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
        'dailyStreak': 0,
        'lastStreakClaimDate': null,
        'longestStreak': 0,
      };
}
