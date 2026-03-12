import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/ads_service.dart';

const _fakeLiveBannerUnitId = 'admob-live-banner';
const _fakeTestBannerUnitId = 'admob-test-banner';
const _fakeLiveRewardedUnitId = 'admob-live-rewarded';
const _fakeTestRewardedUnitId = 'admob-test-rewarded';
const _fakeLiveInterstitialUnitId = 'admob-live-interstitial';
const _fakeTestInterstitialUnitId = 'admob-test-interstitial';

bool _looksLikeAdMobUnitId(String adUnitId) => adUnitId.startsWith('admob-');

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

    test(
      'banner unit resolution is blocked when ads feature flag is disabled',
      () {
        final service = AdsService(
          enabled: false,
          androidHomeBannerUnitId: 'android-home',
          iosHomeBannerUnitId: 'ios-home',
          supportsAds: () => true,
          initializeAdsSdk: () async => throw UnimplementedError(),
        );

        expect(
          service.bannerAdUnitIdForPlacement(AdsService.placementHome),
          isNull,
        );
        expect(service.bannerAdUnitId, isNull);
      },
    );

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
        androidHomeBannerUnitId: _fakeLiveBannerUnitId,
        iosHomeBannerUnitId: '',
        androidResultBannerUnitId: '',
        iosResultBannerUnitId: '',
        looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
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
        androidHomeBannerUnitId: _fakeTestBannerUnitId,
        iosHomeBannerUnitId: '',
        androidResultBannerUnitId: '',
        iosResultBannerUnitId: '',
        debugBannerTestUnitIds: const {_fakeTestBannerUnitId},
        looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isEnabled, isTrue);
      expect(
        service.bannerAdUnitIdForPlacement(AdsService.placementHome),
        _fakeTestBannerUnitId,
      );
    });

    test('allows live AdMob ids when debug override is enabled', () {
      final service = AdsService(
        enabled: true,
        allowLiveAdUnitsInDebug: true,
        androidBannerUnitId: '',
        iosBannerUnitId: '',
        androidHomeBannerUnitId: _fakeLiveBannerUnitId,
        iosHomeBannerUnitId: '',
        androidResultBannerUnitId: '',
        iosResultBannerUnitId: '',
        looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isEnabled, isTrue);
      expect(
        service.bannerAdUnitIdForPlacement(AdsService.placementHome),
        _fakeLiveBannerUnitId,
      );
    });

    test('blocks live rewarded ids in non-release builds by default', () {
      final service = AdsService(
        enabled: false,
        rewardedHintsEnabled: true,
        androidRewardedHintUnitId: _fakeLiveRewardedUnitId,
        iosRewardedHintUnitId: '',
        looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isRewardedHintsEnabled, isFalse);
      expect(service.rewardedHintAdUnitId, isNull);
    });

    test('allows official Google test rewarded ids in non-release builds', () {
      final service = AdsService(
        enabled: true,
        rewardedHintsEnabled: true,
        androidRewardedHintUnitId: _fakeTestRewardedUnitId,
        iosRewardedHintUnitId: '',
        debugRewardedTestUnitIds: const {_fakeTestRewardedUnitId},
        looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isRewardedHintsEnabled, isTrue);
      expect(service.rewardedHintAdUnitId, _fakeTestRewardedUnitId);
    });

    test('rewarded hint unit resolution is blocked when ads are disabled', () {
      final service = AdsService(
        enabled: false,
        rewardedHintsEnabled: true,
        androidRewardedHintUnitId: _fakeTestRewardedUnitId,
        iosRewardedHintUnitId: '',
        debugRewardedTestUnitIds: const {_fakeTestRewardedUnitId},
        looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
        supportsAds: () => true,
        initializeAdsSdk: () async => throw UnimplementedError(),
      );

      expect(service.isRewardedHintsEnabled, isFalse);
      expect(service.rewardedHintAdUnitId, isNull);
    });

    test(
      'blocks live result interstitial ids in non-release builds by default',
      () {
        final service = AdsService(
          enabled: true,
          androidResultInterstitialUnitId: _fakeLiveInterstitialUnitId,
          iosResultInterstitialUnitId: '',
          looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
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
          resultInterstitialEnabled: true,
          androidResultInterstitialUnitId: _fakeTestInterstitialUnitId,
          iosResultInterstitialUnitId: '',
          debugInterstitialTestUnitIds: const {_fakeTestInterstitialUnitId},
          looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
          supportsAds: () => true,
          initializeAdsSdk: () async => throw UnimplementedError(),
        );

        expect(service.resultInterstitialAdUnitId, _fakeTestInterstitialUnitId);
      },
    );

    test(
      'isResultInterstitialEnabled requires global ads + feature flag + unit id',
      () {
        final service = AdsService(
          enabled: true,
          resultInterstitialEnabled: true,
          androidResultInterstitialUnitId: _fakeTestInterstitialUnitId,
          iosResultInterstitialUnitId: '',
          debugInterstitialTestUnitIds: const {_fakeTestInterstitialUnitId},
          looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
          supportsAds: () => true,
          initializeAdsSdk: () async => throw UnimplementedError(),
        );

        expect(service.isResultInterstitialEnabled, isTrue);
      },
    );

    test(
      'result interstitial unit resolution is blocked when feature flag is off',
      () {
        final service = AdsService(
          enabled: true,
          resultInterstitialEnabled: false,
          androidResultInterstitialUnitId: _fakeTestInterstitialUnitId,
          iosResultInterstitialUnitId: '',
          debugInterstitialTestUnitIds: const {_fakeTestInterstitialUnitId},
          looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
          supportsAds: () => true,
          initializeAdsSdk: () async => throw UnimplementedError(),
        );

        expect(service.resultInterstitialAdUnitId, isNull);
      },
    );

    test(
      'rewarded hint unit resolution is blocked when rewarded flag is off',
      () {
        final service = AdsService(
          enabled: true,
          rewardedHintsEnabled: false,
          androidRewardedHintUnitId: _fakeTestRewardedUnitId,
          iosRewardedHintUnitId: '',
          debugRewardedTestUnitIds: const {_fakeTestRewardedUnitId},
          looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
          supportsAds: () => true,
          initializeAdsSdk: () async => throw UnimplementedError(),
        );

        expect(service.rewardedHintAdUnitId, isNull);
      },
    );

    test('initialize runs SDK initialization once when enabled', () async {
      var initializeCalls = 0;
      final configuredTestDeviceIds = <String>[];
      final service = AdsService(
        enabled: true,
        androidBannerUnitId: 'test-unit',
        iosBannerUnitId: '',
        androidTestDeviceIds: const ['android-test-device-1234'],
        supportsAds: () => true,
        updateRequestConfiguration: (configuration) async {
          configuredTestDeviceIds.addAll(
            configuration.testDeviceIds ?? const <String>[],
          );
        },
        initializeAdsSdk: () async {
          initializeCalls++;
          return null;
        },
      );

      await service.initialize();
      await service.initialize();

      expect(initializeCalls, 1);
      expect(configuredTestDeviceIds, ['android-test-device-1234']);
    });

    test(
      'initialize retries after a transient SDK initialization failure',
      () async {
        var initializeCalls = 0;
        final service = AdsService(
          enabled: true,
          androidBannerUnitId: 'test-unit',
          iosBannerUnitId: '',
          supportsAds: () => true,
          initializeAdsSdk: () async {
            initializeCalls++;
            if (initializeCalls == 1) {
              throw Exception('temporary ads init failure');
            }
            return null;
          },
        );

        await service.initialize();
        await service.initialize();

        expect(initializeCalls, 2);
      },
    );

    test(
      'initialize runs when rewarded hints are enabled without banners',
      () async {
        var initializeCalls = 0;
        final service = AdsService(
          enabled: true,
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

    test('initialize runs when result interstitials are enabled', () async {
      var initializeCalls = 0;
      final service = AdsService(
        enabled: true,
        resultInterstitialEnabled: true,
        androidBannerUnitId: '',
        iosBannerUnitId: '',
        androidHomeBannerUnitId: '',
        iosHomeBannerUnitId: '',
        androidResultBannerUnitId: '',
        iosResultBannerUnitId: '',
        androidResultInterstitialUnitId: _fakeTestInterstitialUnitId,
        iosResultInterstitialUnitId: '',
        debugInterstitialTestUnitIds: const {_fakeTestInterstitialUnitId},
        looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
        supportsAds: () => true,
        initializeAdsSdk: () async {
          initializeCalls++;
          return null;
        },
      );

      await service.initialize();

      expect(service.isResultInterstitialEnabled, isTrue);
      expect(initializeCalls, 1);
    });

    test('diagnostics report includes configured test device ids', () async {
      final service = AdsService(
        enabled: true,
        androidHomeBannerUnitId: _fakeTestBannerUnitId,
        iosHomeBannerUnitId: '',
        debugBannerTestUnitIds: const {_fakeTestBannerUnitId},
        androidTestDeviceIds: const ['android-test-device-1234'],
        looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
        supportsAds: () => true,
        getSdkVersion: () async => 'sdk-version',
        updateRequestConfiguration: (_) async {},
        initializeAdsSdk: () async => null,
      );

      final report = await service.buildDiagnosticsReport();

      expect(report, contains('test_device_count=1'));
      expect(report, contains('test_devices=***1234'));
    });

    test(
      'diagnostics initialization retries when SDK returns null status',
      () async {
        var initializeCalls = 0;
        final service = AdsService(
          enabled: true,
          androidHomeBannerUnitId: _fakeTestBannerUnitId,
          iosHomeBannerUnitId: '',
          debugBannerTestUnitIds: const {_fakeTestBannerUnitId},
          looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
          supportsAds: () => true,
          getSdkVersion: () async => 'sdk-version',
          updateRequestConfiguration: (_) async {},
          initializeAdsSdk: () async {
            initializeCalls++;
            return null;
          },
        );

        await service.buildDiagnosticsReport();
        await service.buildDiagnosticsReport();

        expect(initializeCalls, 2);
      },
    );

    test(
      'diagnostics initialization retries when SDK initialization throws',
      () async {
        var initializeCalls = 0;
        final service = AdsService(
          enabled: true,
          androidHomeBannerUnitId: _fakeTestBannerUnitId,
          iosHomeBannerUnitId: '',
          debugBannerTestUnitIds: const {_fakeTestBannerUnitId},
          looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
          supportsAds: () => true,
          getSdkVersion: () async => 'sdk-version',
          openAdInspector: () async => null,
          updateRequestConfiguration: (_) async {},
          initializeAdsSdk: () async {
            initializeCalls++;
            throw Exception('diagnostics init failed');
          },
        );

        await service.buildDiagnosticsReport();
        await service.openInspector();

        expect(initializeCalls, 2);
      },
    );

    test(
      'concurrent diagnostics requests share the same in-flight initialization',
      () async {
        var initializeCalls = 0;
        final completer = Completer<void>();
        final service = AdsService(
          enabled: true,
          androidHomeBannerUnitId: _fakeTestBannerUnitId,
          iosHomeBannerUnitId: '',
          debugBannerTestUnitIds: const {_fakeTestBannerUnitId},
          looksLikeAdMobUnitId: _looksLikeAdMobUnitId,
          supportsAds: () => true,
          getSdkVersion: () async => 'sdk-version',
          updateRequestConfiguration: (_) async {},
          initializeAdsSdk: () async {
            initializeCalls++;
            await completer.future;
            return null;
          },
        );

        final firstCall = service.buildDiagnosticsReport();
        final secondCall = service.buildDiagnosticsReport();
        completer.complete();
        await Future.wait([firstCall, secondCall]);

        expect(initializeCalls, 1);
      },
    );
  });
}
