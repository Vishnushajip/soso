import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Centralized configuration for Google AdMob (Android) and Google AdSense (Web).
class AdConfig {
  AdConfig._();

  // ---------------------------------------------------------------------------
  // Android AdMob Ad Unit IDs
  // ---------------------------------------------------------------------------
  static const String admobAppId = AppConstants.admobAppId;

  /// Production ad unit IDs.
  static const String prodBannerUnitId = AppConstants.admobBannerUnitId;
  static const String prodInterstitialUnitId = AppConstants.admobInterstitialUnitId;
  static const String prodAppOpenUnitId = AppConstants.admobAppOpenUnitId;

  /// Google official test ad unit IDs.
  static const String testBannerUnitId = AppConstants.admobTestBannerUnitId;
  static const String testInterstitialUnitId = AppConstants.admobTestInterstitialUnitId;
  static const String testAppOpenUnitId = AppConstants.admobTestAppOpenUnitId;

  /// Active ad unit IDs depending on build mode.
  /// Always uses official test units in debug/test to avoid policy violations.
  static String get bannerUnitId =>
      kDebugMode ? testBannerUnitId : prodBannerUnitId;

  static String get interstitialUnitId =>
      kDebugMode ? testInterstitialUnitId : prodInterstitialUnitId;

  static String get appOpenUnitId =>
      kDebugMode ? testAppOpenUnitId : prodAppOpenUnitId;

  // ---------------------------------------------------------------------------
  // Flutter Web Google AdSense
  // ---------------------------------------------------------------------------
  static const String adSensePublisherId = AppConstants.adSensePublisherId;
  static const String adSenseClientId = AppConstants.adSenseClientId;
  static const String adSenseBannerSlot = AppConstants.adSenseBannerSlot;

  // ---------------------------------------------------------------------------
  // Frequency Capping & Timing Rules
  // ---------------------------------------------------------------------------
  /// Maximum 1 interstitial every 5 minutes.
  static const Duration interstitialCooldown = Duration(minutes: 5);

  /// Maximum 1 app open ad every 4 hours.
  static const Duration appOpenCooldown = Duration(hours: 4);

  /// Minimum time the app must be in background before returning can trigger app open ad.
  static const Duration appOpenMinBackgroundDuration = Duration(seconds: 30);

  /// Minimum cooldown between ANY full-screen advertisements (interstitial or app open).
  static const Duration fullScreenCooldown = Duration(minutes: 5);

  /// Google AdMob policy: App Open ads are considered stale/expired 4 hours after loading.
  static const Duration appOpenAdMaxAge = Duration(hours: 4);
}

