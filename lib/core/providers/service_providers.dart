import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/fcm_service.dart';
import '../services/haptic_service.dart';
import '../services/local_notifications_service.dart';
import '../services/meta_pixel/meta_pixel_service.dart';
import '../services/presence_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tracking_service.dart';
import 'ad_providers.dart';
import 'firebase_providers.dart';

export 'ad_providers.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(analyticsClientProvider)),
);

final metaPixelServiceProvider = Provider<MetaPixelService>(
  (_) => MetaPixelService(),
);

final trackingServiceProvider = Provider<TrackingService>(
  (ref) => TrackingService(
    analytics: ref.watch(analyticsServiceProvider),
    pixel: ref.watch(metaPixelServiceProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  ),
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
    ref: ref,
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

final hapticServiceProvider = Provider<HapticService>(
  (ref) => HapticService(ref.watch(sharedPreferencesProvider)),
);
