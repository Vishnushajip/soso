import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';
import 'ad_config.dart';

/// Manages AdMob App Open Ads with background preloading, 4-hour frequency capping,
/// background residency threshold, and non-blocking failure fallbacks.
class AppOpenAdManager {
  AppOpenAdManager({this.prefs}) {
    _restoreLastShowTime();
  }

  final SharedPreferences? prefs;

  AppOpenAd? _appOpenAd;
  bool _isLoading = false;
  DateTime? _loadTime;
  DateTime? _lastShowTime;
  DateTime? _pausedTime;

  bool get isReady => _appOpenAd != null && !_isAdExpired;
  DateTime? get lastShowTime => _lastShowTime;

  bool get _isAdExpired {
    if (_loadTime == null) return true;
    return DateTime.now().difference(_loadTime!) >= AdConfig.appOpenAdMaxAge;
  }

  void _restoreLastShowTime() {
    final millis = prefs?.getInt(AppConstants.prefsLastAppOpenTime);
    if (millis != null && millis > 0) {
      _lastShowTime = DateTime.fromMillisecondsSinceEpoch(millis);
    }
  }

  /// Preloads an App Open ad in the background.
  void preload() {
    if (kIsWeb || !Platform.isAndroid) return;
    if ((_appOpenAd != null && !_isAdExpired) || _isLoading) return;

    if (_appOpenAd != null && _isAdExpired) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
    }

    _isLoading = true;
    appLogger.d('[AdMob] Preloading App Open Ad...');

    AppOpenAd.load(
      adUnitId: AdConfig.appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _loadTime = DateTime.now();
          _isLoading = false;
          appLogger.i('[AdMob] App Open Ad loaded successfully.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _appOpenAd = null;
          _loadTime = null;
          _isLoading = false;
          appLogger.w('[AdMob] App Open Ad failed to load: $error');
        },
      ),
    );
  }

  /// Records when the application transitions to background.
  void onAppPaused() {
    _pausedTime = DateTime.now();
  }

  /// Checks whether an App Open ad is permitted to be shown right now upon app resume.
  bool canShowOnResume({
    required bool isShowingFullScreen,
    required bool isCriticalOperationActive,
    DateTime? lastFullScreenShowTime,
  }) {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (isShowingFullScreen) return false;
    if (isCriticalOperationActive) {
      appLogger.d('[AdMob] App Open skipped: Critical operation or active gameplay.');
      return false;
    }

    // Must have a valid preloaded ad that hasn't expired.
    if (_appOpenAd == null || _isAdExpired) {
      return false;
    }

    // Never show on fresh cold start: user must have placed the app in background first.
    if (_pausedTime == null) {
      return false;
    }

    final now = DateTime.now();

    // Must have spent at least the minimum threshold in background (e.g. 30 seconds).
    final backgroundDuration = now.difference(_pausedTime!);
    if (backgroundDuration < AdConfig.appOpenMinBackgroundDuration) {
      appLogger.d('[AdMob] App Open skipped: Background duration too short (${backgroundDuration.inSeconds}s).');
      return false;
    }

    // Enforce 4-hour frequency capping for App Open ads.
    if (_lastShowTime != null &&
        now.difference(_lastShowTime!) < AdConfig.appOpenCooldown) {
      final hoursRemaining = (AdConfig.appOpenCooldown - now.difference(_lastShowTime!)).inMinutes / 60.0;
      appLogger.d('[AdMob] App Open skipped: Frequency capped (~${hoursRemaining.toStringAsFixed(1)}h remaining).');
      return false;
    }

    // Enforce 5-minute cooldown after ANY full-screen ad.
    if (lastFullScreenShowTime != null &&
        now.difference(lastFullScreenShowTime) < AdConfig.fullScreenCooldown) {
      appLogger.d('[AdMob] App Open skipped: Full-screen ad cooldown active.');
      return false;
    }

    return true;
  }

  /// Called when the application resumes from background.
  /// Shows the App Open ad if all safety and frequency checks pass.
  bool showOnResumeIfAllowed({
    required bool isShowingFullScreen,
    required bool isCriticalOperationActive,
    DateTime? lastFullScreenShowTime,
    required void Function(bool isShowing) setFullScreenShowing,
    required void Function(DateTime time) onFullScreenAdShown,
    VoidCallback? onDismissed,
  }) {
    if (!canShowOnResume(
      isShowingFullScreen: isShowingFullScreen,
      isCriticalOperationActive: isCriticalOperationActive,
      lastFullScreenShowTime: lastFullScreenShowTime,
    )) {
      // Clear paused time so subsequent resume without re-pause doesn't trigger
      _pausedTime = null;
      if (_appOpenAd == null || _isAdExpired) {
        preload();
      }
      return false;
    }

    _pausedTime = null;
    final ad = _appOpenAd!;
    setFullScreenShowing(true);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        appLogger.i('[AdMob] App Open Ad presented on screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        appLogger.i('[AdMob] App Open Ad dismissed by user.');
        _handleAdClosed(
          ad: ad,
          setFullScreenShowing: setFullScreenShowing,
          onFullScreenAdShown: onFullScreenAdShown,
          onDismissed: onDismissed,
        );
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        appLogger.w('[AdMob] App Open Ad failed to show: $error');
        _handleAdClosed(
          ad: ad,
          setFullScreenShowing: setFullScreenShowing,
          onFullScreenAdShown: onFullScreenAdShown,
          onDismissed: onDismissed,
        );
      },
    );

    try {
      ad.show();
      return true;
    } catch (e) {
      appLogger.e('[AdMob] Error showing App Open Ad: $e');
      _handleAdClosed(
        ad: ad,
        setFullScreenShowing: setFullScreenShowing,
        onFullScreenAdShown: onFullScreenAdShown,
        onDismissed: onDismissed,
      );
      return false;
    }
  }

  void _handleAdClosed({
    required AppOpenAd ad,
    required void Function(bool isShowing) setFullScreenShowing,
    required void Function(DateTime time) onFullScreenAdShown,
    VoidCallback? onDismissed,
  }) {
    setFullScreenShowing(false);
    final now = DateTime.now();
    _lastShowTime = now;
    prefs?.setInt(AppConstants.prefsLastAppOpenTime, now.millisecondsSinceEpoch);
    onFullScreenAdShown(now);

    ad.dispose();
    _appOpenAd = null;
    _loadTime = null;

    onDismissed?.call();
    preload();
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _loadTime = null;
    _isLoading = false;
  }
}

