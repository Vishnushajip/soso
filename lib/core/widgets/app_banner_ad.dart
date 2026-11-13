import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_config.dart';
import '../theme/app_colors.dart';
import 'app_banner_ad_web_stub.dart'
    if (dart.library.html) 'app_banner_ad_web.dart'
    as web;

typedef _BannerKey = ({String placement, int width});

/// Loads one anchored adaptive AdMob banner per placement + width.
/// Resolves to `null` if no ad could be filled, so the slot simply collapses.
final _admobBannerProvider = FutureProvider.autoDispose
    .family<BannerAd?, _BannerKey>((ref, key) async {
      final size =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
            key.width,
          );
      if (size == null) return null;

      final completer = Completer<BannerAd?>();
      final ad = BannerAd(
        adUnitId: AdConfig.bannerUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!completer.isCompleted) completer.complete(ad as BannerAd);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed (${key.placement}): $error');
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
      ref.onDispose(ad.dispose);
      await ad.load();
      return completer.future;
    });

/// Non-intrusive banner ad.
///
/// * Android → AdMob anchored adaptive banner.
/// * Web → AdSense display unit (needs [AppConstants.adSenseBannerSlot]).
/// * Anything else → nothing.
///
/// Takes zero space until an ad has actually loaded, and is only placed on
/// menu/result screens — never over a live game board.
class AppBannerAd extends ConsumerWidget {
  const AppBannerAd({super.key, required this.placement});

  /// Unique per on-screen location (one AdWidget may only be mounted once).
  final String placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return web.buildWebBanner(placement);
    if (!Platform.isAndroid) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width.truncate();
    final ad = ref
        .watch(_admobBannerProvider((placement: placement, width: width)))
        .valueOrNull;
    if (ad == null) return const SizedBox.shrink();

    return ColoredBox(
      color: AppColors.surfaceContainerLow,
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
