import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Strongly-typed accessor over [dotenv.env].
/// Call [Env.load] once at app start before reading any field.
class Env {
  Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String _s(String key, [String fallback = '']) =>
      dotenv.env[key]?.trim().isNotEmpty == true ? dotenv.env[key]!.trim() : fallback;

  static int _i(String key, int fallback) =>
      int.tryParse(dotenv.env[key]?.trim() ?? '') ?? fallback;

  static bool _b(String key, bool fallback) {
    final v = dotenv.env[key]?.trim().toLowerCase();
    if (v == null || v.isEmpty) return fallback;
    return v == '1' || v == 'true' || v == 'yes';
  }

  static String get appName => _s('APP_NAME', 'SOS Arena');
  static String get supportEmail => _s('SUPPORT_EMAIL', 'support@example.com');
  static String get googleClientIdWeb => _s('GOOGLE_CLIENT_ID_WEB');
  static String get googleServerClientId => _s('GOOGLE_SERVER_CLIENT_ID');
  static int get presenceHeartbeatSeconds => _i('PRESENCE_HEARTBEAT_SECONDS', 45);
  static int get boardSize => _i('BOARD_SIZE', 8);
  static bool get enableCrashlytics => _b('ENABLE_CRASHLYTICS', true);
  static bool get enableAnalytics => _b('ENABLE_ANALYTICS', true);
  static String get fcmServiceAccountJson => _s('FCM_SERVICE_ACCOUNT_JSON');
}
