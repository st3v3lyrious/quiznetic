import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('backend submit score feature flag defaults to false', () {
      expect(AppConfig.enableBackendSubmitScore, isFalse);
    });

    test('crash reporting feature flag defaults to true', () {
      expect(AppConfig.enableCrashReporting, isTrue);
    });

    test('analytics feature flag defaults to true', () {
      expect(AppConfig.enableAnalytics, isTrue);
    });

    test('apple sign-in feature flag defaults to false', () {
      expect(AppConfig.enableAppleSignIn, isFalse);
    });

    test('ads feature flag defaults to false', () {
      expect(AppConfig.enableAds, isFalse);
    });

    test('live ad debug override defaults to false', () {
      expect(AppConfig.allowLiveAdUnitsInDebug, isFalse);
    });

    test('iap feature flag defaults to false', () {
      expect(AppConfig.enableIap, isFalse);
    });

    test('remove ads product id has a stable default', () {
      expect(AppConfig.iapRemoveAdsProductId, 'quiznetic.remove_ads_lifetime');
    });

    test('rewarded hints feature flag defaults to false', () {
      expect(AppConfig.enableRewardedHints, isFalse);
    });

    test('rewarded hints per session has a stable default', () {
      expect(AppConfig.rewardedHintsPerSession, 3);
    });

    test('paid hints feature flag defaults to false', () {
      expect(AppConfig.enablePaidHints, isFalse);
    });

    test('paid hint SKU and default price are stable', () {
      expect(AppConfig.iapHintConsumableProductId, 'quiznetic.hint_single');
      expect(AppConfig.paidHintPriceUsdCents, 50);
    });

    test('banner ad unit ids default to safe values for no-op startup', () {
      expect(AppConfig.adsAndroidBannerUnitId, isEmpty);
      expect(AppConfig.adsIosBannerUnitId, isEmpty);
      expect(
        AppConfig.adsAndroidHomeBannerUnitId,
        'ca-app-pub-9485263915698875/3297690403',
      );
      expect(
        AppConfig.adsIosHomeBannerUnitId,
        'ca-app-pub-9485263915698875/8503108567',
      );
      expect(AppConfig.adsAndroidResultBannerUnitId, isEmpty);
      expect(AppConfig.adsIosResultBannerUnitId, isEmpty);
      expect(
        AppConfig.adsAndroidResultInterstitialUnitId,
        'ca-app-pub-9485263915698875/2360517831',
      );
      expect(
        AppConfig.adsIosResultInterstitialUnitId,
        'ca-app-pub-9485263915698875/6662220346',
      );
      expect(
        AppConfig.adsAndroidRewardedHintUnitId,
        'ca-app-pub-9485263915698875/3186009767',
      );
      expect(
        AppConfig.adsIosRewardedHintUnitId,
        'ca-app-pub-9485263915698875/8542782807',
      );
    });
  });
}
