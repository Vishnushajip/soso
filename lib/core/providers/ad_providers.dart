import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ads/ad_service.dart';
import '../routes/app_router.dart';
import '../routes/route_names.dart';
import 'firebase_providers.dart';

/// Provides the singleton [AdService] instance configured with SharedPreferences.
final adServiceProvider = Provider<AdService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = AdService(prefs: prefs);
  ref.onDispose(service.dispose);
  return service;
});

/// Set of route paths that are considered critical operations where full-screen
/// or interruptive ads must NEVER be shown (e.g. active gameplays, auth, loading).
const Set<String> _criticalRoutes = {
  RouteNames.splash,
  RouteNames.signIn,
  RouteNames.gameBoard,
  RouteNames.aiBoard,
  RouteNames.localBoard,
  RouteNames.flappyGame,
};

/// Helper to determine if a route location represents a critical/active operation.
bool isCriticalRoute(String? location) {
  if (location == null || location.isEmpty) return true;
  for (final r in _criticalRoutes) {
    if (location == r || location.startsWith('$r?') || location.startsWith('$r/')) {
      return true;
    }
  }
  return false;
}

/// Observes app lifecycle transitions to trigger App Open ads safely when
/// returning from background, while honoring frequency capping, minimum
/// background duration, and critical operation suppressions.
final adLifecycleObserverProvider = Provider<void>((ref) {
  final adService = ref.watch(adServiceProvider);
  final router = ref.watch(appRouterProvider);

  final listener = AppLifecycleListener(
    onStateChange: (state) {
      String? loc;
      try {
        loc = router.routeInformationProvider.value.uri.toString();
      } catch (_) {
        try {
          loc = router.routerDelegate.currentConfiguration.uri.toString();
        } catch (_) {}
      }
      final isCrit = isCriticalRoute(loc);
      adService.onAppLifecycleStateChanged(state, isCriticalOperation: isCrit);
    },
  );
  ref.onDispose(listener.dispose);
});
