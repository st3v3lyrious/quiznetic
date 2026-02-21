import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/ads_service.dart';

void main() {
  group('AdsService', () {
    test('isEnabled is false when ads feature flag is disabled', () {
      final service = AdsService(
        enabled: false,
        androidBannerUnitId: 'android-unit',
        iosBannerUnitId: 'ios-unit',
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isEnabled, isFalse);
    });

    test('isEnabled is false when no banner unit id is configured', () {
      final service = AdsService(
        enabled: true,
        androidBannerUnitId: '',
        iosBannerUnitId: '',
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isEnabled, isFalse);
      expect(service.bannerAdUnitId, isNull);
    });

    test('home/result placement ids are supported without fallback id', () {
      final service = AdsService(
        enabled: true,
        androidBannerUnitId: '',
        iosBannerUnitId: '',
        androidHomeBannerUnitId: 'android-home',
        iosHomeBannerUnitId: 'ios-home',
        androidResultBannerUnitId: 'android-result',
        iosResultBannerUnitId: 'ios-result',
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isEnabled, isTrue);
      expect(
        service.bannerAdUnitIdForPlacement(AdsService.placementHome),
        isNotNull,
      );
      expect(
        service.bannerAdUnitIdForPlacement(AdsService.placementResult),
        isNotNull,
      );
      expect(
        service.isBannerEnabledForPlacement(AdsService.placementHome),
        isTrue,
      );
      expect(
        service.isBannerEnabledForPlacement(AdsService.placementResult),
        isTrue,
      );
    });

    test('unknown placement falls back to generic banner id', () {
      final service = AdsService(
        enabled: true,
        androidBannerUnitId: 'android-fallback',
        iosBannerUnitId: 'ios-fallback',
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.bannerAdUnitIdForPlacement('unknown'), isNotNull);
    });

    test('initialize runs SDK initialization once when enabled', () async {
      var initializeCalls = 0;
      final service = AdsService(
        enabled: true,
        androidBannerUnitId: 'test-unit',
        iosBannerUnitId: '',
        supportsAds: () => true,
        initializeAdsSdk: () async {
          initializeCalls++;
          return null;
        },
      );

      await service.initialize();
      await service.initialize();

      expect(initializeCalls, 1);
    });

    test(
      'initialize runs when rewarded hints are enabled without banners',
      () async {
        var initializeCalls = 0;
        final service = AdsService(
          enabled: false,
          rewardedHintsEnabled: true,
          androidBannerUnitId: '',
          iosBannerUnitId: '',
          androidRewardedHintUnitId: 'android-rewarded',
          iosRewardedHintUnitId: 'ios-rewarded',
          supportsAds: () => true,
          initializeAdsSdk: () async {
            initializeCalls++;
            return null;
          },
        );

        await service.initialize();

        expect(service.isRewardedHintsEnabled, isTrue);
        expect(service.rewardedHintAdUnitId, isNotNull);
        expect(initializeCalls, 1);
      },
    );
  });
}
