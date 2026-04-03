import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quiznetic_flutter/services/ad_consent_service.dart';
import 'package:quiznetic_flutter/services/ads_service.dart';
import 'package:quiznetic_flutter/services/entitlement_service.dart';
import 'package:quiznetic_flutter/services/hint_monetization_service.dart';
import 'package:quiznetic_flutter/services/iap_service.dart';

void main() {
  group('HintMonetizationService', () {
    test(
      'grants rewarded hint and decrements remaining session quota',
      () async {
        final hintService = HintMonetizationService(
          rewardedHintsEnabled: true,
          paidHintsEnabled: false,
          rewardedHintsPerSession: 2,
          adsService: AdsService(
            enabled: true,
            rewardedHintsEnabled: true,
            androidRewardedInterstitialUnitId:
                'android.rewarded.interstitial.unit',
            iosRewardedInterstitialUnitId: 'ios.rewarded.interstitial.unit',
            supportsAds: () => true,
            initializeAdsSdk: () async => null,
            consentService: _allowingConsentService(),
          ),
          iapService: _buildIapService(),
          presentRewardedHintAd: (_) async => true,
          logEvent: _noopLogEvent,
        );

        final result = await hintService.requestHint();

        expect(result.status, HintRequestStatus.granted);
        expect(result.source, HintGrantSource.rewardedAd);
        expect(result.rewardedHintsRemaining, 1);
        expect(hintService.rewardedHintsRemaining, 1);
      },
    );

    test(
      'returns exhausted when free quota is used and paid hints are off',
      () async {
        final hintService = HintMonetizationService(
          rewardedHintsEnabled: true,
          paidHintsEnabled: false,
          rewardedHintsPerSession: 1,
          adsService: AdsService(
            enabled: true,
            rewardedHintsEnabled: true,
            androidRewardedInterstitialUnitId:
                'android.rewarded.interstitial.unit',
            iosRewardedInterstitialUnitId: 'ios.rewarded.interstitial.unit',
            supportsAds: () => true,
            initializeAdsSdk: () async => null,
            consentService: _allowingConsentService(),
          ),
          iapService: _buildIapService(),
          presentRewardedHintAd: (_) async => true,
          logEvent: _noopLogEvent,
        );

        final first = await hintService.requestHint();
        final second = await hintService.requestHint();

        expect(first.status, HintRequestStatus.granted);
        expect(second.status, HintRequestStatus.exhausted);
      },
    );

    test('falls back to paid hint after rewarded quota is exhausted', () async {
      final storeClient = _HintFakeStoreClient(autoCompleteConsumable: true);
      final hintService = HintMonetizationService(
        rewardedHintsEnabled: true,
        paidHintsEnabled: true,
        rewardedHintsPerSession: 1,
        paidHintPriceUsdCents: 50,
        adsService: AdsService(
          enabled: true,
          rewardedHintsEnabled: true,
          androidRewardedInterstitialUnitId:
              'android.rewarded.interstitial.unit',
          iosRewardedInterstitialUnitId: 'ios.rewarded.interstitial.unit',
          supportsAds: () => true,
          initializeAdsSdk: () async => null,
          consentService: _allowingConsentService(),
        ),
        iapService: _buildIapService(storeClient: storeClient),
        presentRewardedHintAd: (_) async => true,
        logEvent: _noopLogEvent,
      );

      final first = await hintService.requestHint();
      final second = await hintService.requestHint();

      expect(first.status, HintRequestStatus.granted);
      expect(first.source, HintGrantSource.rewardedAd);
      expect(second.status, HintRequestStatus.granted);
      expect(second.source, HintGrantSource.paidHint);
      expect(storeClient.buyConsumableCalls, 1);
      storeClient.dispose();
    });

    test(
      'falls back to paid hint when rewarded is enabled but not configured',
      () async {
        final storeClient = _HintFakeStoreClient(autoCompleteConsumable: true);
        final hintService = HintMonetizationService(
          rewardedHintsEnabled: true,
          paidHintsEnabled: true,
          rewardedHintsPerSession: 1,
          paidHintPriceUsdCents: 50,
          adsService: AdsService(
            enabled: true,
            rewardedHintsEnabled: true,
            androidRewardedInterstitialUnitId: '',
            iosRewardedInterstitialUnitId: '',
            supportsAds: () => true,
            initializeAdsSdk: () async => null,
            consentService: _allowingConsentService(),
          ),
          iapService: _buildIapService(storeClient: storeClient),
          presentRewardedHintAd: (_) async => true,
          logEvent: _noopLogEvent,
        );

        final result = await hintService.requestHint();

        expect(result.status, HintRequestStatus.granted);
        expect(result.source, HintGrantSource.paidHint);
        expect(storeClient.buyConsumableCalls, 1);
        storeClient.dispose();
      },
    );

    test(
      'falls back to paid hint when rewarded ads SDK is not ready',
      () async {
        final storeClient = _HintFakeStoreClient(autoCompleteConsumable: true);
        final hintService = HintMonetizationService(
          rewardedHintsEnabled: true,
          paidHintsEnabled: true,
          rewardedHintsPerSession: 1,
          paidHintPriceUsdCents: 50,
          adsService: AdsService(
            enabled: true,
            rewardedHintsEnabled: true,
            androidRewardedInterstitialUnitId:
                'android.rewarded.interstitial.unit',
            iosRewardedInterstitialUnitId: '',
            supportsAds: () => true,
            initializeAdsSdk: () async => throw Exception('ads init failed'),
            consentService: _allowingConsentService(),
          ),
          iapService: _buildIapService(storeClient: storeClient),
          presentRewardedHintAd: (_) async => true,
          logEvent: _noopLogEvent,
        );

        final result = await hintService.requestHint();

        expect(result.status, HintRequestStatus.granted);
        expect(result.source, HintGrantSource.paidHint);
        expect(storeClient.buyConsumableCalls, 1);
        storeClient.dispose();
      },
    );

    test('uses rewarded interstitial presenter for rewarded hints', () async {
      var rewardedHintCalls = 0;
      final hintService = HintMonetizationService(
        rewardedHintsEnabled: true,
        paidHintsEnabled: false,
        rewardedHintsPerSession: 1,
        adsService: AdsService(
          enabled: true,
          rewardedHintsEnabled: true,
          androidRewardedInterstitialUnitId:
              'android.rewarded.interstitial.unit',
          iosRewardedInterstitialUnitId: '',
          debugRewardedTestUnitIds: const {
            'android.rewarded.interstitial.unit',
          },
          supportsAds: () => true,
          initializeAdsSdk: () async => null,
          consentService: _allowingConsentService(),
        ),
        iapService: _buildIapService(),
        presentRewardedHintAd: (_) async {
          rewardedHintCalls++;
          return true;
        },
        logEvent: _noopLogEvent,
      );

      final result = await hintService.requestHint();

      expect(result.status, HintRequestStatus.granted);
      expect(rewardedHintCalls, 1);
    });
  });
}

Future<void> _noopLogEvent(
  String name, {
  Map<String, Object?>? parameters,
}) async {}

AdConsentService _allowingConsentService() {
  return AdConsentService(
    enabled: true,
    supportsAds: () => true,
    requestConsentInfoUpdate: (_) async => null,
    loadAndShowConsentFormIfRequired: () async => null,
    getConsentStatus: () async => ConsentStatus.obtained,
    canRequestAds: () async => true,
    isConsentFormAvailable: () async => false,
    getPrivacyOptionsRequirementStatus: () async =>
        PrivacyOptionsRequirementStatus.notRequired,
    showPrivacyOptionsForm: () async => null,
  );
}

IapService _buildIapService({_HintFakeStoreClient? storeClient}) {
  final client = storeClient ?? _HintFakeStoreClient();
  final memory = <String, bool>{};
  return IapService(
    enabled: true,
    supportsStore: () => true,
    hintConsumableProductId: 'quiznetic.hint_single',
    storeClient: client,
    entitlementService: EntitlementService(
      loadBoolValue: (key) async => memory[key],
      saveBoolValue: (key, value) async {
        memory[key] = value;
      },
    ),
    logEvent: _noopLogEvent,
  );
}

class _HintFakeStoreClient implements IapStoreClient {
  _HintFakeStoreClient({this.autoCompleteConsumable = false});

  final bool autoCompleteConsumable;
  final StreamController<List<StorePurchaseUpdate>> _purchaseController =
      StreamController<List<StorePurchaseUpdate>>.broadcast();

  int buyConsumableCalls = 0;

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseUpdates =>
      _purchaseController.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<StoreProductResponse> queryProductDetails(
    Set<String> productIds,
  ) async {
    return const StoreProductResponse(
      productDetails: [
        StoreProductDetails(
          id: 'quiznetic.hint_single',
          title: 'Hint',
          description: 'One hint',
          price: '\$0.50',
        ),
      ],
      notFoundIds: [],
    );
  }

  @override
  Future<bool> buyNonConsumable(StoreProductDetails productDetails) async {
    return true;
  }

  @override
  Future<bool> buyConsumable(StoreProductDetails productDetails) async {
    buyConsumableCalls++;
    if (autoCompleteConsumable) {
      scheduleMicrotask(() {
        _purchaseController.add([
          StorePurchaseUpdate(
            productId: productDetails.id,
            status: StorePurchaseStatus.purchased,
            pendingCompletePurchase: true,
          ),
        ]);
      });
    }
    return true;
  }

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> completePurchase(StorePurchaseUpdate purchaseUpdate) async {}

  void dispose() {
    _purchaseController.close();
  }
}
