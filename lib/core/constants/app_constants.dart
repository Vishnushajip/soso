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
  static const admobInterstitialUnitId = 'ca-app-pub-1023025727425756/5860211547';
  static const admobAppOpenUnitId = 'ca-app-pub-1023025727425756/8120698321';

  /// Google's official test ad units — used in debug builds so developers
  /// never generate invalid traffic or test impressions on live ad units.
  static const admobTestBannerUnitId = 'ca-app-pub-3940256099942544/9214589741';
  static const admobTestInterstitialUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const admobTestAppOpenUnitId = 'ca-app-pub-3940256099942544/9257390508';

  static const adSenseClientId = 'ca-pub-1023025727425756';
  static const adSensePublisherId = 'pub-1023025727425756';

  /// AdSense "Display ad" unit slot id (the `data-ad-slot` value). Create a
  /// horizontal display ad unit in AdSense → Ads → By ad unit and paste its
  /// slot id here. While empty, no manual in-app banner is rendered on web
  /// (Auto Ads handle web monetization automatically).
  static const adSenseBannerSlot = '';

  // Local storage keys for ad frequency capping.
  static const prefsLastInterstitialTime = 'ad_last_interstitial_time';
  static const prefsLastAppOpenTime = 'ad_last_app_open_time';
  static const prefsLastFullScreenAdTime = 'ad_last_fullscreen_ad_time';

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
