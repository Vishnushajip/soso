import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/sos_arena_app.dart';
import 'core/widgets/app_crash_screen.dart';
import 'providers/firebase_providers.dart';

Future<void> main() async {
  final prefs = await AppBootstrap.initialize();

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
