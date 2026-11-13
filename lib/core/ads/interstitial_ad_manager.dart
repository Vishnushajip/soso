import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';
import 'ad_config.dart';

/// Manages AdMob Interstitial Ads with background preloading, frequency capping,
/// and non-blocking failure fallbacks.
class InterstitialAdManager {
  InterstitialAdManager({this.prefs}) {
    _restoreLastShowTime();
  }

  final SharedPreferences? prefs;

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  DateTime? _lastShowTime;

  bool get isReady => _interstitialAd != null;
  DateTime? get lastShowTime => _lastShowTime;

  void _restoreLastShowTime() {
    final millis = prefs?.getInt(AppConstants.prefsLastInterstitialTime);
    if (millis != null && millis > 0) {
      _lastShowTime = DateTime.fromMillisecondsSinceEpoch(millis);
    }
  }

  /// Preloads an interstitial ad in the background.
  void preload() {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_interstitialAd != null || _isLoading) return;

    _isLoading = true;
    appLogger.d('[AdMob] Preloading Interstitial Ad...');

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          appLogger.i('[AdMob] Interstitial Ad loaded successfully.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _isLoading = false;
          appLogger.w('[AdMob] Interstitial Ad failed to load: $error');
        },
      ),
    );
  }

  /// Checks whether an interstitial ad is permitted to be shown right now.
  bool canShow({
    required bool isShowingFullScreen,
    DateTime? lastFullScreenShowTime,
  }) {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (isShowingFullScreen) return false;
    if (_interstitialAd == null) return false;

    final now = DateTime.now();

    // Enforce 5-minute interstitial cooldown.
    if (_lastShowTime != null &&
        now.difference(_lastShowTime!) < AdConfig.interstitialCooldown) {
      final waitSec = (AdConfig.interstitialCooldown - now.difference(_lastShowTime!)).inSeconds;
      appLogger.d('[AdMob] Interstitial skipped: Cooldown active ($waitSec s remaining).');
      return false;
    }

    // Enforce 5-minute cooldown after ANY full-screen ad (app open or interstitial).
    if (lastFullScreenShowTime != null &&
        now.difference(lastFullScreenShowTime) < AdConfig.fullScreenCooldown) {
      appLogger.d('[AdMob] Interstitial skipped: Full-screen ad cooldown active.');
      return false;
    }

    return true;
  }

  /// Displays the interstitial ad if available and eligible under frequency caps.
  /// Calls [onDismissed] immediately if ad cannot be shown, guaranteeing zero user delay.
  bool showIfAllowed({
    required bool isShowingFullScreen,
    DateTime? lastFullScreenShowTime,
    VoidCallback? onDismissed,
    required void Function(bool isShowing) setFullScreenShowing,
    required void Function(DateTime time) onFullScreenAdShown,
  }) {
    if (!canShow(
      isShowingFullScreen: isShowingFullScreen,
      lastFullScreenShowTime: lastFullScreenShowTime,
    )) {
      onDismissed?.call();
      if (_interstitialAd == null && !_isLoading) {
        preload();
      }
      return false;
    }

    final ad = _interstitialAd!;
    setFullScreenShowing(true);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        appLogger.i('[AdMob] Interstitial Ad presented on screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        appLogger.i('[AdMob] Interstitial Ad dismissed by user.');
        _handleAdClosed(
          ad: ad,
          setFullScreenShowing: setFullScreenShowing,
          onFullScreenAdShown: onFullScreenAdShown,
          onDismissed: onDismissed,
        );
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        appLogger.w('[AdMob] Interstitial Ad failed to show: $error');
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
      appLogger.e('[AdMob] Error showing Interstitial Ad: $e');
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
    required InterstitialAd ad,
    required void Function(bool isShowing) setFullScreenShowing,
    required void Function(DateTime time) onFullScreenAdShown,
    required VoidCallback? onDismissed,
  }) {
    setFullScreenShowing(false);
    final now = DateTime.now();
    _lastShowTime = now;
    prefs?.setInt(AppConstants.prefsLastInterstitialTime, now.millisecondsSinceEpoch);
    onFullScreenAdShown(now);

    ad.dispose();
    _interstitialAd = null;

    onDismissed?.call();
    preload();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoading = false;
  }
}

