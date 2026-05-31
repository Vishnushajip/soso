import 'package:firebase_analytics/firebase_analytics.dart';

import '../constants/env.dart';

/// Thin wrapper around FirebaseAnalytics so the rest of the app
/// does not depend directly on the plugin.
class AnalyticsService {
  AnalyticsService(this._analytics);
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsObserver get navigatorObserver => FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> setUser(String? uid) async {
    if (!Env.enableAnalytics) return;
    await _analytics.setUserId(id: uid);
  }

  Future<void> log(String name, [Map<String, Object?> params = const {}]) async {
    if (!Env.enableAnalytics) return;
    await _analytics.logEvent(
      name: name,
      parameters: params.map((k, v) => MapEntry(k, v ?? '')),
    );
  }

  Future<void> screen(String name) async {
    if (!Env.enableAnalytics) return;
    await _analytics.logScreenView(screenName: name);
  }
}
