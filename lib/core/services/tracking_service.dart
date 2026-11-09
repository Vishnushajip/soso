import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';
import 'meta_pixel/meta_pixel_service.dart';

/// Unified tracking service dispatching to both Firebase Analytics and Meta Pixel.
class TrackingService {
  TrackingService({
    required AnalyticsService analytics,
    required MetaPixelService pixel,
    required SharedPreferences prefs,
  })  : _analytics = analytics,
        _pixel = pixel,
        _prefs = prefs;

  final AnalyticsService _analytics;
  final MetaPixelService _pixel;
  final SharedPreferences _prefs;

  final Set<String> _startedMatches = {};
  final Set<String> _completedMatches = {};

  static const String _firstMatchSentKey = 'meta_first_match_sent';

  /// Google Sign-In tracking.
  Future<void> googleSignIn({required bool isNewUser}) async {
    if (isNewUser) {
      await _pixel.track('CompleteRegistration', const {'method': 'google'});
    } else {
      await _pixel.trackCustom('Login', const {'method': 'google'});
    }
  }

  /// Guest start tracking.
  Future<void> guestStart() async {
    await _pixel.trackCustom('GuestStart');
    await _analytics.log('guest_start');
  }

  /// Tracks when a match actually starts in any mode.
  /// Deduplicated per [matchKey] if provided.
  Future<void> matchStarted({
    required String mode,
    required int boardSize,
    String? difficulty,
    String? matchKey,
  }) async {
    if (matchKey != null && !_startedMatches.add(matchKey)) {
      return;
    }

    // First match ever on this device check
    final firstMatchSent = _prefs.getBool(_firstMatchSentKey) ?? false;
    if (!firstMatchSent) {
      await _prefs.setBool(_firstMatchSentKey, true);
      await _pixel.track('StartTrial', const {'value': 0, 'currency': 'INR'});
      await _analytics.log('first_match');
    }

    final params = <String, Object?>{
      'mode': mode,
      'board_size': boardSize,
      if (difficulty != null && difficulty.isNotEmpty) 'difficulty': difficulty,
    };

    await _pixel.trackCustom('PlayGame', params);
    await _analytics.log('play_game', params);
  }

  /// Tracks when a match finishes.
  /// Deduplicated per [matchKey] if provided.
  Future<void> matchCompleted({
    required String mode,
    required String result,
    String? matchKey,
  }) async {
    if (matchKey != null && !_completedMatches.add(matchKey)) {
      return;
    }

    final params = <String, Object?>{
      'mode': mode,
      'result': result,
    };

    await _pixel.trackCustom('MatchComplete', params);
    await _analytics.log('match_complete', params);
  }

  /// Tracks when the app download banner is tapped.
  Future<void> downloadAppClicked({String source = 'web_banner'}) async {
    final params = <String, Object?>{'source': source};
    await _pixel.trackCustom('DownloadApp', params);
    await _analytics.log('download_app_click', params);
  }
}

