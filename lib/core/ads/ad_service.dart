import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';
import 'app_open_ad_manager.dart';
import 'interstitial_ad_manager.dart';

/// Centralized ad management service for the SOS Arena application.
/// Coordinates AdMob (Android) and AdSense (Web) strategies.
class AdService {
  AdService({this.prefs}) {
    _restoreLastFullScreenShowTime();
    if (!kIsWeb && Platform.isAndroid) {
      _interstitialManager = InterstitialAdManager(prefs: prefs);
      _appOpenManager = AppOpenAdManager(prefs: prefs);
    }
  }

  final SharedPreferences? prefs;

  InterstitialAdManager? _interstitialManager;
  AppOpenAdManager? _appOpenManager;

  bool _isInitialized = false;
  bool _isShowingFullScreen = false;
  DateTime? _lastFullScreenShowTime;

  bool get isShowingFullScreen => _isShowingFullScreen;
  DateTime? get lastFullScreenShowTime => _lastFullScreenShowTime;

  bool get isAdMobSupported => !kIsWeb && Platform.isAndroid;

  void _restoreLastFullScreenShowTime() {
    final millis = prefs?.getInt(AppConstants.prefsLastFullScreenAdTime);
    if (millis != null && millis > 0) {
      _lastFullScreenShowTime = DateTime.fromMillisecondsSinceEpoch(millis);
    }
  }

  /// Initializes mobile ads in the background. Never blocks startup.
  Future<void> initialize() async {
    if (!isAdMobSupported) {
      appLogger.d('[AdService] Mobile ads not supported on this platform (Web/Other).');
      return;
    }
    if (_isInitialized) return;

    try {
      appLogger.i('[AdService] Initializing MobileAds SDK...');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      appLogger.i('[AdService] MobileAds SDK initialized.');

      // Preload full-screen ads asynchronously in the background.
      _interstitialManager?.preload();
      _appOpenManager?.preload();
    } catch (e, s) {
      appLogger.w('[AdService] Failed to initialize MobileAds SDK: $e\n$s');
    }
  }

  /// Attempts to display an interstitial ad at a natural break (e.g. match completion).
  /// Guarantees that [onDismissed] is called so user flow is NEVER blocked.
  void showInterstitialIfAllowed({VoidCallback? onDismissed}) {
    if (!isAdMobSupported || _interstitialManager == null) {
      onDismissed?.call();
      return;
    }

    final shown = _interstitialManager!.showIfAllowed(
      isShowingFullScreen: _isShowingFullScreen,
      lastFullScreenShowTime: _lastFullScreenShowTime,
      onDismissed: onDismissed,
      setFullScreenShowing: (showing) {
        _isShowingFullScreen = showing;
      },
      onFullScreenAdShown: (time) {
        _lastFullScreenShowTime = time;
        prefs?.setInt(
          AppConstants.prefsLastFullScreenAdTime,
          time.millisecondsSinceEpoch,
        );
      },
    );

    if (!shown) {
      appLogger.d('[AdService] Interstitial not shown (capped or unavailable). Flow continued.');
    }
  }

  /// Lifecycle callback to handle app pause and resume for App Open ads.
  void onAppLifecycleStateChanged(
    AppLifecycleState state, {
    bool isCriticalOperation = false,
  }) {
    if (!isAdMobSupported || _appOpenManager == null) return;

    switch (state) {
      case AppLifecycleState.paused:
        _appOpenManager!.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        _appOpenManager!.showOnResumeIfAllowed(
          isShowingFullScreen: _isShowingFullScreen,
          isCriticalOperationActive: isCriticalOperation,
          lastFullScreenShowTime: _lastFullScreenShowTime,
          setFullScreenShowing: (showing) {
            _isShowingFullScreen = showing;
          },
          onFullScreenAdShown: (time) {
            _lastFullScreenShowTime = time;
            prefs?.setInt(
              AppConstants.prefsLastFullScreenAdTime,
              time.millisecondsSinceEpoch,
            );
          },
        );
        break;
      default:
        break;
    }
  }

  void dispose() {
    _interstitialManager?.dispose();
    _appOpenManager?.dispose();
  }
}

