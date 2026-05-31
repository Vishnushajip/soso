import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/sos_arena_app.dart';
import 'providers/firebase_providers.dart';

Future<void> main() async {
  final prefs = await AppBootstrap.initialize();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SosArenaApp(),
    ),
  );
}
