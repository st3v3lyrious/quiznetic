import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/entitlement_service.dart';
import 'package:quiznetic_flutter/services/iap_service.dart';

void main() {
  group('IapService', () {
    test('isEnabled is false when iap feature is disabled', () {
      final storeClient = _FakeStoreClient();
      final service = IapService(
        enabled: false,
        supportsStore: () => true,
        storeClient: storeClient,
        entitlementService: _memoryEntitlementService(),
        logEvent: _noopLogEvent,
      );

      expect(service.isEnabled, isFalse);
    });

    test(
      'loadRemoveAdsOffer returns unavailable when store is offline',
      () async {
        final storeClient = _FakeStoreClient(isAvailableResult: false);
        final service = IapService(
          enabled: true,
          supportsStore: () => true,
          removeAdsProductId: 'quiznetic.remove_ads_lifetime',
          storeClient: storeClient,
          entitlementService: _memoryEntitlementService(),
          logEvent: _noopLogEvent,
        );

        final offer = await service.loadRemoveAdsOffer();

        expect(offer.featureEnabled, isTrue);
        expect(offer.storeAvailable, isFalse);
        expect(offer.productFound, isFalse);
        await service.dispose();
        storeClient.dispose();
      },
    );

    test(
      'buyRemoveAds starts purchase flow when product is available',
      () async {
        final storeClient = _FakeStoreClient(
          isAvailableResult: true,
          queryResponse: const StoreProductResponse(
            productDetails: [
              StoreProductDetails(
                id: 'quiznetic.remove_ads_lifetime',
                title: 'Remove Ads',
                description: 'Lifetime unlock',
                price: '\$2.99',
              ),
            ],
            notFoundIds: [],
          ),
        );
        final analyticsEvents = <String>[];
        final service = IapService(
          enabled: true,
          supportsStore: () => true,
          removeAdsProductId: 'quiznetic.remove_ads_lifetime',
          storeClient: storeClient,
          entitlementService: _memoryEntitlementService(),
          logEvent: (name, {parameters}) async {
            analyticsEvents.add(name);
          },
        );

        final result = await service.buyRemoveAds();

        expect(result.status, IapActionStatus.started);
        expect(storeClient.buyNonConsumableCalls, 1);
        expect(analyticsEvents, contains('iap_started'));
        await service.dispose();
        storeClient.dispose();
      },
    );

    test(
      'purchase update grants remove ads entitlement and logs success',
      () async {
        final storeClient = _FakeStoreClient(
          isAvailableResult: true,
          queryResponse: const StoreProductResponse(
            productDetails: [
              StoreProductDetails(
                id: 'quiznetic.remove_ads_lifetime',
                title: 'Remove Ads',
                description: 'Lifetime unlock',
                price: '\$2.99',
              ),
            ],
            notFoundIds: [],
          ),
        );
        final entitlementService = _memoryEntitlementService();
        final analyticsEvents = <String>[];
        final service = IapService(
          enabled: true,
          supportsStore: () => true,
          removeAdsProductId: 'quiznetic.remove_ads_lifetime',
          storeClient: storeClient,
          entitlementService: entitlementService,
          logEvent: (name, {parameters}) async {
            analyticsEvents.add(name);
          },
        );
        await service.initialize();

        storeClient.emitPurchaseUpdates([
          const StorePurchaseUpdate(
            productId: 'quiznetic.remove_ads_lifetime',
            status: StorePurchaseStatus.purchased,
            pendingCompletePurchase: true,
          ),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(service.hasRemoveAds, isTrue);
        expect(analyticsEvents, contains('iap_success'));
        expect(storeClient.completePurchaseCalls, 1);
        await service.dispose();
        storeClient.dispose();
      },
    );

    test('restorePurchases starts restore flow when enabled', () async {
      final storeClient = _FakeStoreClient(
        isAvailableResult: true,
        queryResponse: const StoreProductResponse(
          productDetails: [],
          notFoundIds: [],
        ),
      );
      final analyticsEvents = <String>[];
      final service = IapService(
        enabled: true,
        supportsStore: () => true,
        storeClient: storeClient,
        entitlementService: _memoryEntitlementService(),
        logEvent: (name, {parameters}) async {
          analyticsEvents.add(name);
        },
      );

      final result = await service.restorePurchases();

      expect(result.status, IapActionStatus.started);
      expect(storeClient.restoreCalls, 1);
      expect(analyticsEvents, contains('iap_restore_started'));
      await service.dispose();
      storeClient.dispose();
    });

    test(
      'buySingleHint waits for purchase confirmation and returns success',
      () async {
        final storeClient = _FakeStoreClient(
          isAvailableResult: true,
          queryResponse: const StoreProductResponse(
            productDetails: [
              StoreProductDetails(
                id: 'quiznetic.hint_single',
                title: 'Hint',
                description: 'One hint',
                price: '\$0.50',
              ),
            ],
            notFoundIds: [],
          ),
        );
        final analyticsEvents = <String>[];
        final service = IapService(
          enabled: true,
          supportsStore: () => true,
          hintConsumableProductId: 'quiznetic.hint_single',
          storeClient: storeClient,
          entitlementService: _memoryEntitlementService(),
          logEvent: (name, {parameters}) async {
            analyticsEvents.add(name);
          },
        );

        final purchaseFuture = service.buySingleHint(
          timeout: const Duration(seconds: 1),
        );
        await Future<void>.delayed(Duration.zero);
        storeClient.emitPurchaseUpdates([
          const StorePurchaseUpdate(
            productId: 'quiznetic.hint_single',
            status: StorePurchaseStatus.purchased,
            pendingCompletePurchase: true,
          ),
        ]);

        final result = await purchaseFuture;
        expect(result.status, IapActionStatus.success);
        expect(storeClient.buyConsumableCalls, 1);
        expect(storeClient.completePurchaseCalls, 1);
        expect(analyticsEvents, contains('iap_hint_success'));
        await service.dispose();
        storeClient.dispose();
      },
    );
  });
}

Future<void> _noopLogEvent(
  String _, {
  Map<String, Object?>? parameters,
}) async {}

EntitlementService _memoryEntitlementService() {
  final memory = <String, bool>{};
  return EntitlementService(
    loadBoolValue: (key) async => memory[key],
    saveBoolValue: (key, value) async {
      memory[key] = value;
    },
  );
}

class _FakeStoreClient implements IapStoreClient {
  _FakeStoreClient({
    this.isAvailableResult = true,
    StoreProductResponse? queryResponse,
  }) : _queryResponse =
           queryResponse ??
           const StoreProductResponse(productDetails: [], notFoundIds: []);

  final bool isAvailableResult;
  final StoreProductResponse _queryResponse;
  final StreamController<List<StorePurchaseUpdate>> _purchaseController =
      StreamController<List<StorePurchaseUpdate>>.broadcast();

  int buyNonConsumableCalls = 0;
  int buyConsumableCalls = 0;
  int restoreCalls = 0;
  int completePurchaseCalls = 0;

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseUpdates =>
      _purchaseController.stream;

  @override
  Future<bool> isAvailable() async => isAvailableResult;

  @override
  Future<StoreProductResponse> queryProductDetails(
    Set<String> productIds,
  ) async {
    return _queryResponse;
  }

  @override
  Future<bool> buyNonConsumable(StoreProductDetails productDetails) async {
    buyNonConsumableCalls++;
    return true;
  }

  @override
  Future<bool> buyConsumable(StoreProductDetails productDetails) async {
    buyConsumableCalls++;
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
  }

  @override
  Future<void> completePurchase(StorePurchaseUpdate purchaseUpdate) async {
    completePurchaseCalls++;
  }

  void emitPurchaseUpdates(List<StorePurchaseUpdate> updates) {
    _purchaseController.add(updates);
  }

  void dispose() {
    _purchaseController.close();
  }
}
