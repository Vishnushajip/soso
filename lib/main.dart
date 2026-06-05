import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/sos_arena_app.dart';
import 'core/widgets/app_crash_screen.dart';
import 'providers/firebase_providers.dart';

Future<void> main() async {
  final prefs = await AppBootstrap.initialize();

  if (!kIsWeb) {
    await FirebaseAnalytics.instance
        .setAnalyticsCollectionEnabled(!kDebugMode);
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppCrashScreen(details: details);
  };

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SosArenaApp(),
    ),
  );
}