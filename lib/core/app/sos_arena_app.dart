import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soso/core/services/local_notifications_service.dart';
import 'package:soso/core/services/sound_service.dart';
import 'package:soso/core/routes/route_names.dart';
import '../widgets/no_internet_banner.dart';

import '../constants/env.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';
import '../../firebase_options.dart';
import '../models/notification_model.dart';
import '../providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import '../providers/notification_providers.dart';
import '../providers/service_providers.dart';
import '../routes/app_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final n = message.notification;
  final data = message.data;

  final title = n?.title ?? data['title'];
  final body = n?.body ?? data['body'];
  final roomId = data['roomId'] as String?;
  final type = data['type'] as String?;

  if (title != null && body != null) {
    final localNotif = LocalNotificationsService();
    await localNotif.init();

    String payload = roomId ?? '';
    if (type == 'challenge') {
      payload = 'challenge_$payload';
    }

    await localNotif.show(title: title, body: body, payload: payload);
  }
}

final Set<String> _shownNotifIds = {};

// A known, harmless Riverpod 2.x teardown race: a watched stream provider
// fires an async transition into a widget element that is being disposed,
// so Flutter calls markNeedsBuild() on a defunct element. It does not affect
// the user, so we suppress it instead of reporting it as a crash.
bool _isBenignElementTeardownRaw(Object error, StackTrace? stack) {
  if (!error.toString().contains('_ElementLifecycle.defunct')) return false;
  return stack?.toString().contains('markNeedsBuild') ?? false;
}

bool _isBenignElementTeardown(FlutterErrorDetails details) =>
    _isBenignElementTeardownRaw(details.exception, details.stack);

class AppBootstrap {
  AppBootstrap._();

  static Future<SharedPreferences> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
      } catch (e) {}
    }
    if (kIsWeb) {
      usePathUrlStrategy();
    }
    final futures = await Future.wait([
      Env.load(),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      SharedPreferences.getInstance(),
    ]);

    if (Env.enableCrashlytics && !kIsWeb) {
      FlutterError.onError = (details) {
        if (_isBenignElementTeardown(details)) {
          FirebaseCrashlytics.instance.recordError(
            details.exception,
            details.stack,
            reason: 'benign-riverpod-element-teardown',
            fatal: false,
          );
          return;
        }
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        if (_isBenignElementTeardownRaw(error, stack)) return true;
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } else {
      FlutterError.onError = (details) {
        if (_isBenignElementTeardown(details)) return;
        FlutterError.presentError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        if (_isBenignElementTeardownRaw(error, stack)) return true;
        appLogger.e('Uncaught', error: error, stackTrace: stack);
        return true;
      };
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

    return futures[2] as SharedPreferences;
  }
}

final bootstrapProvider = Provider<void>((ref) {
  Future.microtask(() async {
    try {
      await Future.wait<void>([
        ref.read(localNotificationsServiceProvider).init(),
        ref.read(fcmServiceProvider).init(),
        ref.read(soundServiceProvider).init(),
        ref.read(hapticServiceProvider).init(),
      ]);

      ref.read(localNotificationsServiceProvider).onClickResponse.listen((
        payload,
      ) {
        if (payload != null && payload.isNotEmpty) {
          final router = ref.read(appRouterProvider);
          if (payload.startsWith('match_')) {
            router.push('${RouteNames.gameBoard}?roomId=$payload');
          } else if (payload.startsWith('challenge_')) {
            final roomId = payload.substring('challenge_'.length);
            router.push(
              '${RouteNames.chatRoom}?roomId=$roomId&autoSend=I%20am%20ready%20for%20challenge',
            );
          } else {
            router.push('${RouteNames.chatRoom}?roomId=$payload');
          }
        }
      });
    } catch (e, s) {
      appLogger.w('service init: $e\n$s');
    }
  });

  ref.listen<AsyncValue<List<AppNotification>>>(notificationsProvider, (
    prev,
    next,
  ) {
    final list = next.valueOrNull;
    if (list == null) return;

    final localNotif = ref.read(localNotificationsServiceProvider);
    final activeChatRoomId = ref.read(activeChatRoomIdProvider);

    for (final n in list) {
      if (n.read == false && !_shownNotifIds.contains(n.id)) {
        _shownNotifIds.add(n.id);

        if (n.createdAt != null &&
            DateTime.now().difference(n.createdAt!).inMinutes > 5) {
          continue;
        }

        final roomId = n.data['roomId'] as String?;
        if (activeChatRoomId != null && roomId == activeChatRoomId) {
          continue;
        }

        localNotif.show(title: n.title, body: n.body, payload: roomId ?? '');
        ref.read(soundServiceProvider).play(AppSound.notify);
      }
    }
  });

  ref.listen<AsyncValue<fb_auth.User?>>(authStateProvider, (_, next) async {
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
  }, fireImmediately: true);
});

class SosArenaApp extends ConsumerWidget {
  const SosArenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(bootstrapProvider);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        ref.read(soundServiceProvider).onFirstUserInteraction();
      },
      child: NetworkConnectivityWrapper(
        child: MaterialApp.router(
          title: Env.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          routerConfig: ref.watch(appRouterProvider),
        ),
      ),
    );
  }
}
