import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soso/core/ads/ad_config.dart';
import 'package:soso/core/ads/ad_service.dart';
import 'package:soso/core/constants/app_constants.dart';
import 'package:soso/core/providers/ad_providers.dart';
import 'package:soso/core/routes/route_names.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdConfig Tests', () {
    test('Production and test ad unit IDs are configured', () {
      expect(AdConfig.admobAppId, 'ca-app-pub-1023025727425756~4133795399');
      expect(AdConfig.prodBannerUnitId, 'ca-app-pub-1023025727425756/2385599454');
      expect(AdConfig.prodInterstitialUnitId, 'ca-app-pub-1023025727425756/5860211547');
      expect(AdConfig.prodAppOpenUnitId, 'ca-app-pub-1023025727425756/8120698321');

      expect(AdConfig.testBannerUnitId, 'ca-app-pub-3940256099942544/9214589741');
      expect(AdConfig.testInterstitialUnitId, 'ca-app-pub-3940256099942544/1033173712');
      expect(AdConfig.testAppOpenUnitId, 'ca-app-pub-3940256099942544/9257390508');
    });

    test('AdSense Publisher and Client IDs are configured', () {
      expect(AdConfig.adSensePublisherId, 'pub-1023025727425756');
      expect(AdConfig.adSenseClientId, 'ca-pub-1023025727425756');
    });

    test('Frequency capping constants meet project requirements', () {
      expect(AdConfig.interstitialCooldown, const Duration(minutes: 5));
      expect(AdConfig.appOpenCooldown, const Duration(hours: 4));
      expect(AdConfig.appOpenMinBackgroundDuration, const Duration(seconds: 30));
      expect(AdConfig.fullScreenCooldown, const Duration(minutes: 5));
      expect(AdConfig.appOpenAdMaxAge, const Duration(hours: 4));
    });
  });

  group('Critical Route Suppression Tests', () {
    test('Gameplay, auth, and splash routes are marked critical', () {
      expect(isCriticalRoute(RouteNames.splash), isTrue);
      expect(isCriticalRoute(RouteNames.signIn), isTrue);
      expect(isCriticalRoute(RouteNames.gameBoard), isTrue);
      expect(isCriticalRoute('${RouteNames.gameBoard}?roomId=123'), isTrue);
      expect(isCriticalRoute(RouteNames.aiBoard), isTrue);
      expect(isCriticalRoute('${RouteNames.aiBoard}?difficulty=hard'), isTrue);
      expect(isCriticalRoute(RouteNames.localBoard), isTrue);
      expect(isCriticalRoute(RouteNames.flappyGame), isTrue);
    });

    test('Public and menu routes are not critical', () {
      expect(isCriticalRoute(RouteNames.home), isFalse);
      expect(isCriticalRoute(RouteNames.friends), isFalse);
      expect(isCriticalRoute(RouteNames.shop), isFalse);
      expect(isCriticalRoute(RouteNames.leaderboard), isFalse);
      expect(isCriticalRoute(RouteNames.profile), isFalse);
      expect(isCriticalRoute(RouteNames.privacy), isFalse);
      expect(isCriticalRoute(RouteNames.terms), isFalse);
      expect(isCriticalRoute(RouteNames.matchSummary), isFalse);
    });

    test('Null or empty routes are conservatively treated as critical', () {
      expect(isCriticalRoute(null), isTrue);
      expect(isCriticalRoute(''), isTrue);
    });
  });

  group('AdService Safety Tests', () {
    test('Non-blocking execution of showInterstitialIfAllowed when not supported', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AdService(prefs: prefs);

      bool dismissed = false;
      service.showInterstitialIfAllowed(onDismissed: () {
        dismissed = true;
      });

      expect(dismissed, isTrue);
      service.dispose();
    });

    test('Frequency timestamps are restored from SharedPreferences', () async {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 10));
      SharedPreferences.setMockInitialValues({
        AppConstants.prefsLastFullScreenAdTime: pastTime.millisecondsSinceEpoch,
        AppConstants.prefsLastInterstitialTime: pastTime.millisecondsSinceEpoch,
        AppConstants.prefsLastAppOpenTime: pastTime.millisecondsSinceEpoch,
      });

      final prefs = await SharedPreferences.getInstance();
      final service = AdService(prefs: prefs);

      expect(service.lastFullScreenShowTime, isNotNull);
      expect(
        service.lastFullScreenShowTime!.millisecondsSinceEpoch,
        pastTime.millisecondsSinceEpoch,
      );

      service.dispose();
    });
  });
}

