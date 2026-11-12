const kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.sosarena.app';
const kWebsiteUrl = 'https://playsos.web.app/';

class AppConstants {
  AppConstants._();

  /// Public Google Play listing for the Android app.
  static const playStoreUrl = kPlayStoreUrl;

  /// Public web version of the game.
  static const websiteUrl = kWebsiteUrl;

  // Ads — AdMob (Android app) + AdSense (website).
  static const admobAppId = 'ca-app-pub-1023025727425756~4133795399';
  static const admobBannerUnitId = 'ca-app-pub-1023025727425756/2385599454';

  /// Google's official test banner unit — used in debug builds so you never
  /// click your own live ads (which can get the AdMob account suspended).
  static const admobTestBannerUnitId = 'ca-app-pub-3940256099942544/9214589741';

  static const adSenseClientId = 'ca-pub-1023025727425756';

  /// AdSense "Display ad" unit slot id (the `data-ad-slot` value). Create a
  /// horizontal display ad unit in AdSense → Ads → By ad unit and paste its
  /// slot id here. While empty, no in-app banner is rendered on web.
  static const adSenseBannerSlot = '';

  // Firestore collection names — referenced from repositories only.
  static const usersCollection = 'users';
  static const friendRequestsCollection = 'friend_requests';
  static const friendsCollection = 'friends';
  static const chatRoomsCollection = 'chat_rooms';
  static const messagesSubcollection = 'messages';
  static const gameRoomsCollection = 'game_rooms';
  static const movesSubcollection = 'moves';
  static const notificationsCollection = 'notifications';
  static const leaderboardsCollection = 'leaderboards';
  static const analyticsCollection = 'analytics';

  // FCM
  static const fcmChannelId = 'sos_arena_alerts_v5';
  static const fcmChannelName = 'SOS Arena';
  static const fcmChannelDescription = 'Match, friend, and notification updates';

  // Game
  static const minPlayersLocal = 2;
  static const maxPlayersLocal = 4;
  static const minBoardSize = 5;
  static const maxBoardSize = 12;
  static const pointsPerSos = 10;
  static const pointsPerWin = 50;

  // Pagination
  static const defaultPageSize = 25;
  static const leaderboardPageSize = 50;

  // Local storage keys.
  static const prefsLastFcmToken = 'last_fcm_token';
  static const prefsSoundEnabled = 'sound_enabled';
  static const prefsSoundVolume = 'sound_volume';
  static const prefsMusicEnabled = 'music_enabled';
  static const prefsMusicVolume = 'music_volume';
  static const prefsHapticsEnabled = 'haptics_enabled';
  static const prefsNotificationsEnabled = 'notifications_enabled';

  // Global chat room id is fixed so all clients share it.
  static const globalChatRoomId = 'global';
}
