import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/env.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/logger.dart';
import '../firebase_options.dart';
import '../providers/auth_providers.dart';
import '../providers/service_providers.dart';
import '../routes/app_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage _) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class AppBootstrap {
  AppBootstrap._();

  static Future<SharedPreferences> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Env.load();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    if (Env.enableCrashlytics && !kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } else {
      PlatformDispatcher.instance.onError = (error, stack) {
        appLogger.e('Uncaught', error: error, stackTrace: stack);
        return true;
      };
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

    return SharedPreferences.getInstance();
  }
}

/// Watched once by [SosArenaApp]; kicks off service init + auth-driven
/// presence / FCM / analytics in a single place.
final bootstrapProvider = Provider<void>((ref) {
  Future.microtask(() async {
    try {
      await Future.wait<void>([
        ref.read(localNotificationsServiceProvider).init(),
        ref.read(fcmServiceProvider).init(),
        ref.read(soundServiceProvider).init(),
      ]);
    } catch (e, s) {
      appLogger.w('service init: $e\n$s');
    }
  });

  ref.listen<AsyncValue<fb_auth.User?>>(
    authStateProvider,
    (_, next) async {
      final user = next.valueOrNull;
      final presence = ref.read(presenceServiceProvider);
      final analytics = ref.read(analyticsServiceProvider);
      final crashlytics = ref.read(crashlyticsServiceProvider);

      if (user == null) {
        await presence.stop();
        await analytics.setUser(null);
        await crashlytics.setUser(null);
        return;
      }
      try {
        await ref.read(fcmServiceProvider).syncTokenForUser(user.uid);
        presence.start(user.uid);
        await analytics.setUser(user.uid);
        await crashlytics.setUser(user.uid);
      } catch (e, s) {
        appLogger.w('post-auth wire-up: $e\n$s');
      }
    },
    fireImmediately: true,
  );
});

class SosArenaApp extends ConsumerWidget {
  const SosArenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(bootstrapProvider);
    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
