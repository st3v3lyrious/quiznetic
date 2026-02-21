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
        androidHomeBannerUnitId: '',
        iosHomeBannerUnitId: '',
        androidResultBannerUnitId: '',
        iosResultBannerUnitId: '',
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

    test('blocks live AdMob banner ids in non-release builds by default', () {
      final service = AdsService(
        enabled: true,
        androidBannerUnitId: '',
        iosBannerUnitId: '',
        androidHomeBannerUnitId: 'ca-app-pub-1111111111111111/2222222222',
        iosHomeBannerUnitId: '',
        androidResultBannerUnitId: '',
        iosResultBannerUnitId: '',
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isEnabled, isFalse);
      expect(
        service.bannerAdUnitIdForPlacement(AdsService.placementHome),
        isNull,
      );
    });

    test('allows official Google test banner ids in non-release builds', () {
      final service = AdsService(
        enabled: true,
        androidBannerUnitId: '',
        iosBannerUnitId: '',
        androidHomeBannerUnitId: 'ca-app-pub-3940256099942544/6300978111',
        iosHomeBannerUnitId: '',
        androidResultBannerUnitId: '',
        iosResultBannerUnitId: '',
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isEnabled, isTrue);
      expect(
        service.bannerAdUnitIdForPlacement(AdsService.placementHome),
        'ca-app-pub-3940256099942544/6300978111',
      );
    });

    test('allows live AdMob ids when debug override is enabled', () {
      final service = AdsService(
        enabled: true,
        allowLiveAdUnitsInDebug: true,
        androidBannerUnitId: '',
        iosBannerUnitId: '',
        androidHomeBannerUnitId: 'ca-app-pub-1111111111111111/2222222222',
        iosHomeBannerUnitId: '',
        androidResultBannerUnitId: '',
        iosResultBannerUnitId: '',
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isEnabled, isTrue);
      expect(
        service.bannerAdUnitIdForPlacement(AdsService.placementHome),
        'ca-app-pub-1111111111111111/2222222222',
      );
    });

    test('blocks live rewarded ids in non-release builds by default', () {
      final service = AdsService(
        enabled: false,
        rewardedHintsEnabled: true,
        androidRewardedHintUnitId: 'ca-app-pub-1111111111111111/3333333333',
        iosRewardedHintUnitId: '',
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isRewardedHintsEnabled, isFalse);
      expect(service.rewardedHintAdUnitId, isNull);
    });

    test('allows official Google test rewarded ids in non-release builds', () {
      final service = AdsService(
        enabled: false,
        rewardedHintsEnabled: true,
        androidRewardedHintUnitId: 'ca-app-pub-3940256099942544/5224354917',
        iosRewardedHintUnitId: '',
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isRewardedHintsEnabled, isTrue);
      expect(
        service.rewardedHintAdUnitId,
        'ca-app-pub-3940256099942544/5224354917',
      );
    });

    test(
      'blocks live result interstitial ids in non-release builds by default',
      () {
        final service = AdsService(
          enabled: true,
          androidResultInterstitialUnitId:
              'ca-app-pub-1111111111111111/4444444444',
          iosResultInterstitialUnitId: '',
          supportsAds: () => true,
          initializeAdsSdk: () async => throw UnimplementedError(),
        );

        expect(service.resultInterstitialAdUnitId, isNull);
      },
    );

    test(
      'allows official Google test interstitial ids in non-release builds',
      () {
        final service = AdsService(
          enabled: true,
          androidResultInterstitialUnitId:
              'ca-app-pub-3940256099942544/1033173712',
          iosResultInterstitialUnitId: '',
          supportsAds: () => true,
          initializeAdsSdk: () async => throw UnimplementedError(),
        );

        expect(
          service.resultInterstitialAdUnitId,
          'ca-app-pub-3940256099942544/1033173712',
        );
      },
    );

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
