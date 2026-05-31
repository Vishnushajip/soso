import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/analytics_service.dart';
import '../core/services/crashlytics_service.dart';
import '../core/services/fcm_service.dart';
import '../core/services/local_notifications_service.dart';
import '../core/services/presence_service.dart';
import '../core/services/sound_service.dart';
import '../core/services/storage_service.dart';
import 'firebase_providers.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(analyticsClientProvider)),
);

final crashlyticsServiceProvider = Provider<CrashlyticsService>(
  (ref) => CrashlyticsService(ref.watch(crashlyticsClientProvider)),
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(storageClientProvider)),
);

final localNotificationsServiceProvider = Provider<LocalNotificationsService>(
  (_) => LocalNotificationsService(),
);

final fcmServiceProvider = Provider<FcmService>((ref) {
  final svc = FcmService(
    messaging: ref.watch(messagingProvider),
    firestore: ref.watch(firestoreProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    localNotifications: ref.watch(localNotificationsServiceProvider),
  );
  ref.onDispose(svc.dispose);
  return svc;
});

final presenceServiceProvider = Provider<PresenceService>(
  (ref) => PresenceService(ref.watch(firestoreProvider)),
);

final soundServiceProvider = Provider<SoundService>((ref) {
  final svc = SoundService(ref.watch(sharedPreferencesProvider));
  ref.onDispose(svc.dispose);
  return svc;
});
