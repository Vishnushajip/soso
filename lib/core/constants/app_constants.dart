class AppConstants {
  AppConstants._();

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
