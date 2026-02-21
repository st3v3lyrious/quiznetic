/*
 DOC: Service
 Title: IAP Service
 Purpose: Handles store-backed Remove Ads purchase and restore flows.
*/
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quiznetic_flutter/config/app_config.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';
import 'package:quiznetic_flutter/services/entitlement_service.dart';

typedef StoreSupportResolver = bool Function();
typedef MonetizationLogger =
    Future<void> Function(String name, {Map<String, Object?>? parameters});

enum IapActionStatus { success, started, disabled, unavailable, failed }

class IapActionResult {
  const IapActionResult({required this.status, required this.message});

  final IapActionStatus status;
  final String message;
}

class RemoveAdsOffer {
  const RemoveAdsOffer({
    required this.featureEnabled,
    required this.storeAvailable,
    required this.productFound,
    required this.productId,
    this.title,
    this.description,
    this.price,
  });

  final bool featureEnabled;
  final bool storeAvailable;
  final bool productFound;
  final String productId;
  final String? title;
  final String? description;
  final String? price;

  bool get canPurchase => featureEnabled && storeAvailable && productFound;
}

enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

class StoreProductDetails {
  const StoreProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.rawProductDetails,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final Object? rawProductDetails;
}

class StoreProductResponse {
  const StoreProductResponse({
    required this.productDetails,
    required this.notFoundIds,
  });

  final List<StoreProductDetails> productDetails;
  final List<String> notFoundIds;
}

class StorePurchaseUpdate {
  const StorePurchaseUpdate({
    required this.productId,
    required this.status,
    required this.pendingCompletePurchase,
    this.errorCode,
    this.rawPurchaseDetails,
  });

  final String productId;
  final StorePurchaseStatus status;
  final bool pendingCompletePurchase;
  final String? errorCode;
  final Object? rawPurchaseDetails;
}

abstract class IapStoreClient {
  Stream<List<StorePurchaseUpdate>> get purchaseUpdates;

  Future<bool> isAvailable();

  Future<StoreProductResponse> queryProductDetails(Set<String> productIds);

  Future<bool> buyNonConsumable(StoreProductDetails productDetails);

  Future<bool> buyConsumable(StoreProductDetails productDetails);

  Future<void> restorePurchases();

  Future<void> completePurchase(StorePurchaseUpdate purchaseUpdate);
}

class InAppPurchaseStoreClient implements IapStoreClient {
  InAppPurchaseStoreClient({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseUpdates {
    return _inAppPurchase.purchaseStream.map(
      (purchases) => purchases.map(_mapPurchaseUpdate).toList(growable: false),
    );
  }

  @override
  Future<bool> isAvailable() {
    return _inAppPurchase.isAvailable();
  }

  @override
  Future<StoreProductResponse> queryProductDetails(
    Set<String> productIds,
  ) async {
    final response = await _inAppPurchase.queryProductDetails(productIds);
    final mappedProducts = response.productDetails
        .map(
          (detail) => StoreProductDetails(
            id: detail.id,
            title: detail.title,
            description: detail.description,
            price: detail.price,
            rawProductDetails: detail,
          ),
        )
        .toList(growable: false);

    return StoreProductResponse(
      productDetails: mappedProducts,
      notFoundIds: response.notFoundIDs,
    );
  }

  @override
  Future<bool> buyNonConsumable(StoreProductDetails productDetails) async {
    final rawDetails = productDetails.rawProductDetails;
    if (rawDetails is! ProductDetails) {
      throw StateError('Missing raw ProductDetails for ${productDetails.id}');
    }

    return _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: rawDetails),
    );
  }

  @override
  Future<bool> buyConsumable(StoreProductDetails productDetails) async {
    final rawDetails = productDetails.rawProductDetails;
    if (rawDetails is! ProductDetails) {
      throw StateError('Missing raw ProductDetails for ${productDetails.id}');
    }

    return _inAppPurchase.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: rawDetails),
    );
  }

  @override
  Future<void> restorePurchases() {
    return _inAppPurchase.restorePurchases();
  }

  @override
  Future<void> completePurchase(StorePurchaseUpdate purchaseUpdate) {
    final rawPurchase = purchaseUpdate.rawPurchaseDetails;
    if (rawPurchase is! PurchaseDetails) {
      return Future<void>.value();
    }
    return _inAppPurchase.completePurchase(rawPurchase);
  }

  static StorePurchaseUpdate _mapPurchaseUpdate(PurchaseDetails purchase) {
    return StorePurchaseUpdate(
      productId: purchase.productID,
      status: _mapStatus(purchase.status),
      pendingCompletePurchase: purchase.pendingCompletePurchase,
      errorCode: purchase.error?.code,
      rawPurchaseDetails: purchase,
    );
  }

  static StorePurchaseStatus _mapStatus(PurchaseStatus status) {
    return switch (status) {
      PurchaseStatus.pending => StorePurchaseStatus.pending,
      PurchaseStatus.purchased => StorePurchaseStatus.purchased,
      PurchaseStatus.restored => StorePurchaseStatus.restored,
      PurchaseStatus.canceled => StorePurchaseStatus.canceled,
      PurchaseStatus.error => StorePurchaseStatus.error,
    };
  }
}

class IapService {
  IapService({
    bool? enabled,
    String? removeAdsProductId,
    String? hintConsumableProductId,
    StoreSupportResolver? supportsStore,
    IapStoreClient? storeClient,
    EntitlementService? entitlementService,
    MonetizationLogger? logEvent,
  }) : _enabled = enabled ?? AppConfig.enableIap,
       _removeAdsProductId =
           (removeAdsProductId ?? AppConfig.iapRemoveAdsProductId).trim(),
       _hintConsumableProductId =
           (hintConsumableProductId ?? AppConfig.iapHintConsumableProductId)
               .trim(),
       _supportsStore = supportsStore ?? _defaultSupportsStore,
       _storeClient = storeClient ?? InAppPurchaseStoreClient(),
       _entitlementService = entitlementService ?? EntitlementService.instance,
       _logEvent = logEvent ?? AnalyticsService.instance.logEvent;

  static final IapService instance = IapService();

  final bool _enabled;
  final String _removeAdsProductId;
  final String _hintConsumableProductId;
  final StoreSupportResolver _supportsStore;
  final IapStoreClient _storeClient;
  final EntitlementService _entitlementService;
  final MonetizationLogger _logEvent;

  StoreProductDetails? _cachedRemoveAdsProduct;
  Completer<IapActionResult>? _pendingHintPurchaseCompleter;
  StreamSubscription<List<StorePurchaseUpdate>>? _purchaseSubscription;

  bool get isEnabled {
    return _enabled && _removeAdsProductId.isNotEmpty && _supportsStore();
  }

  bool get hasRemoveAds => _entitlementService.hasRemoveAds;

  ValueListenable<bool> get hasRemoveAdsListenable {
    return _entitlementService.hasRemoveAdsListenable;
  }

  static bool _defaultSupportsStore() {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  /// Initializes entitlement state and purchase stream listeners.
  Future<void> initialize() async {
    await _entitlementService.initialize();
    if (_purchaseSubscription != null || !isEnabled) return;

    _purchaseSubscription = _storeClient.purchaseUpdates.listen(
      (updates) => unawaited(_handlePurchaseUpdates(updates)),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('IapService purchase stream error: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  /// Queries the configured "Remove Ads" product from the store catalog.
  Future<RemoveAdsOffer> loadRemoveAdsOffer() async {
    await initialize();

    if (!isEnabled) {
      return RemoveAdsOffer(
        featureEnabled: false,
        storeAvailable: false,
        productFound: false,
        productId: _removeAdsProductId,
      );
    }

    try {
      final storeAvailable = await _storeClient.isAvailable();
      if (!storeAvailable) {
        return RemoveAdsOffer(
          featureEnabled: true,
          storeAvailable: false,
          productFound: false,
          productId: _removeAdsProductId,
        );
      }

      final response = await _storeClient.queryProductDetails({
        _removeAdsProductId,
      });
      final matched = response.productDetails
          .where((item) => item.id == _removeAdsProductId)
          .toList(growable: false);
      if (matched.isEmpty) {
        _cachedRemoveAdsProduct = null;
        return RemoveAdsOffer(
          featureEnabled: true,
          storeAvailable: true,
          productFound: false,
          productId: _removeAdsProductId,
        );
      }

      final product = matched.first;
      _cachedRemoveAdsProduct = product;
      return RemoveAdsOffer(
        featureEnabled: true,
        storeAvailable: true,
        productFound: true,
        productId: product.id,
        title: product.title,
        description: product.description,
        price: product.price,
      );
    } catch (e, stackTrace) {
      debugPrint('IapService loadRemoveAdsOffer failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return RemoveAdsOffer(
        featureEnabled: true,
        storeAvailable: false,
        productFound: false,
        productId: _removeAdsProductId,
      );
    }
  }

  /// Starts non-consumable purchase flow for lifetime ad removal.
  Future<IapActionResult> buyRemoveAds() async {
    await initialize();

    if (_entitlementService.hasRemoveAds) {
      return const IapActionResult(
        status: IapActionStatus.success,
        message: 'Remove Ads is already active on this account.',
      );
    }

    final offer = await loadRemoveAdsOffer();
    if (!offer.canPurchase || _cachedRemoveAdsProduct == null) {
      return const IapActionResult(
        status: IapActionStatus.unavailable,
        message: 'Remove Ads is not available right now. Please try again.',
      );
    }

    await _safeLogEvent(
      'iap_started',
      parameters: {'product_id': _cachedRemoveAdsProduct!.id},
    );

    try {
      final started = await _storeClient.buyNonConsumable(
        _cachedRemoveAdsProduct!,
      );
      if (!started) {
        return const IapActionResult(
          status: IapActionStatus.failed,
          message: 'Could not start purchase flow. Please try again.',
        );
      }
      return const IapActionResult(
        status: IapActionStatus.started,
        message:
            'Purchase flow opened. Complete the store prompt to remove ads.',
      );
    } catch (e, stackTrace) {
      debugPrint('IapService buyRemoveAds failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return const IapActionResult(
        status: IapActionStatus.failed,
        message: 'Purchase failed to start. Please try again.',
      );
    }
  }

  /// Starts consumable purchase flow for one additional hint unlock.
  ///
  /// Returns success only after the purchase stream confirms completion.
  Future<IapActionResult> buySingleHint({
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await initialize();

    if (!isEnabled || _hintConsumableProductId.isEmpty) {
      return const IapActionResult(
        status: IapActionStatus.disabled,
        message: 'Paid hints are disabled in this build.',
      );
    }

    if (_pendingHintPurchaseCompleter != null &&
        !_pendingHintPurchaseCompleter!.isCompleted) {
      return const IapActionResult(
        status: IapActionStatus.started,
        message: 'A hint purchase is already in progress.',
      );
    }

    try {
      final storeAvailable = await _storeClient.isAvailable();
      if (!storeAvailable) {
        return const IapActionResult(
          status: IapActionStatus.unavailable,
          message: 'Store is unavailable right now. Please try again.',
        );
      }

      final response = await _storeClient.queryProductDetails({
        _hintConsumableProductId,
      });
      final matched = response.productDetails
          .where((item) => item.id == _hintConsumableProductId)
          .toList(growable: false);
      if (matched.isEmpty) {
        return const IapActionResult(
          status: IapActionStatus.unavailable,
          message: 'Hint purchase is not available right now.',
        );
      }

      final product = matched.first;
      await _safeLogEvent(
        'iap_hint_started',
        parameters: {'product_id': product.id},
      );

      final completer = Completer<IapActionResult>();
      _pendingHintPurchaseCompleter = completer;
      final started = await _storeClient.buyConsumable(product);
      if (!started) {
        _completePendingHintPurchase(
          const IapActionResult(
            status: IapActionStatus.failed,
            message: 'Could not start hint purchase. Please try again.',
          ),
        );
      }

      return completer.future.timeout(
        timeout,
        onTimeout: () {
          if (identical(_pendingHintPurchaseCompleter, completer)) {
            _pendingHintPurchaseCompleter = null;
          }
          return const IapActionResult(
            status: IapActionStatus.failed,
            message: 'Hint purchase timed out. Please try again.',
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('IapService buySingleHint failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _completePendingHintPurchase(
        const IapActionResult(
          status: IapActionStatus.failed,
          message: 'Hint purchase failed. Please try again.',
        ),
      );
      return const IapActionResult(
        status: IapActionStatus.failed,
        message: 'Hint purchase failed. Please try again.',
      );
    }
  }

  /// Starts restore flow to recover past purchases.
  Future<IapActionResult> restorePurchases() async {
    await initialize();

    if (!isEnabled) {
      return const IapActionResult(
        status: IapActionStatus.disabled,
        message: 'Purchases are disabled in this build.',
      );
    }

    await _safeLogEvent(
      'iap_restore_started',
      parameters: {'product_id': _removeAdsProductId},
    );

    try {
      await _storeClient.restorePurchases();
      return const IapActionResult(
        status: IapActionStatus.started,
        message: 'Restore started. Any eligible purchase will be applied.',
      );
    } catch (e, stackTrace) {
      debugPrint('IapService restorePurchases failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return const IapActionResult(
        status: IapActionStatus.failed,
        message: 'Restore failed. Please try again.',
      );
    }
  }

  /// Cancels stream subscription. Primarily used by tests.
  Future<void> dispose() async {
    _completePendingHintPurchase(
      const IapActionResult(
        status: IapActionStatus.failed,
        message: 'Hint purchase was interrupted.',
      ),
    );
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }

  Future<void> _handlePurchaseUpdates(List<StorePurchaseUpdate> updates) async {
    for (final purchase in updates) {
      if (purchase.productId == _removeAdsProductId) {
        switch (purchase.status) {
          case StorePurchaseStatus.purchased:
            await _entitlementService.setRemoveAds(true);
            await _safeLogEvent(
              'iap_success',
              parameters: {'product_id': purchase.productId},
            );
            break;
          case StorePurchaseStatus.restored:
            await _entitlementService.setRemoveAds(true);
            await _safeLogEvent(
              'iap_restore',
              parameters: {'product_id': purchase.productId},
            );
            break;
          case StorePurchaseStatus.error:
            await _safeLogEvent(
              'iap_failed',
              parameters: {
                'product_id': purchase.productId,
                'error_code': purchase.errorCode ?? 'unknown',
              },
            );
            break;
          case StorePurchaseStatus.canceled:
            await _safeLogEvent(
              'iap_canceled',
              parameters: {'product_id': purchase.productId},
            );
            break;
          case StorePurchaseStatus.pending:
            break;
        }
      }

      if (purchase.productId == _hintConsumableProductId) {
        switch (purchase.status) {
          case StorePurchaseStatus.purchased:
            await _safeLogEvent(
              'iap_hint_success',
              parameters: {'product_id': purchase.productId},
            );
            _completePendingHintPurchase(
              const IapActionResult(
                status: IapActionStatus.success,
                message: 'Hint unlocked successfully.',
              ),
            );
            break;
          case StorePurchaseStatus.restored:
            await _safeLogEvent(
              'iap_hint_restore',
              parameters: {'product_id': purchase.productId},
            );
            _completePendingHintPurchase(
              const IapActionResult(
                status: IapActionStatus.success,
                message: 'Hint unlocked successfully.',
              ),
            );
            break;
          case StorePurchaseStatus.canceled:
            await _safeLogEvent(
              'iap_hint_canceled',
              parameters: {'product_id': purchase.productId},
            );
            _completePendingHintPurchase(
              const IapActionResult(
                status: IapActionStatus.failed,
                message: 'Hint purchase was canceled.',
              ),
            );
            break;
          case StorePurchaseStatus.error:
            await _safeLogEvent(
              'iap_hint_failed',
              parameters: {
                'product_id': purchase.productId,
                'error_code': purchase.errorCode ?? 'unknown',
              },
            );
            _completePendingHintPurchase(
              const IapActionResult(
                status: IapActionStatus.failed,
                message: 'Hint purchase failed. Please try again.',
              ),
            );
            break;
          case StorePurchaseStatus.pending:
            break;
        }
      }

      if (purchase.pendingCompletePurchase) {
        try {
          await _storeClient.completePurchase(purchase);
        } catch (e, stackTrace) {
          debugPrint('IapService completePurchase failed: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }
  }

  Future<void> _safeLogEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    try {
      await _logEvent(name, parameters: parameters);
    } catch (e, stackTrace) {
      debugPrint('IapService logEvent failed for "$name": $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _completePendingHintPurchase(IapActionResult result) {
    final completer = _pendingHintPurchaseCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete(result);
    _pendingHintPurchaseCompleter = null;
  }
}
