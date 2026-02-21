/*
 DOC: Service
 Title: Ads Service
 Purpose: Controls ad SDK enablement and placement eligibility.
*/
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quiznetic_flutter/config/app_config.dart';

typedef AdsSupportResolver = bool Function();
typedef AdsSdkInitializer = Future<Object?> Function();

class AdsService {
  static const placementHome = 'home';
  static const placementResult = 'result';

  AdsService({
    bool? enabled,
    bool? rewardedHintsEnabled,
    String? androidBannerUnitId,
    String? iosBannerUnitId,
    String? androidHomeBannerUnitId,
    String? iosHomeBannerUnitId,
    String? androidResultBannerUnitId,
    String? iosResultBannerUnitId,
    String? androidRewardedHintUnitId,
    String? iosRewardedHintUnitId,
    AdsSupportResolver? supportsAds,
    AdsSdkInitializer? initializeAdsSdk,
  }) : _enabled = enabled ?? AppConfig.enableAds,
       _rewardedHintsEnabled =
           rewardedHintsEnabled ?? AppConfig.enableRewardedHints,
       _androidBannerUnitId =
           (androidBannerUnitId ?? AppConfig.adsAndroidBannerUnitId).trim(),
       _iosBannerUnitId = (iosBannerUnitId ?? AppConfig.adsIosBannerUnitId)
           .trim(),
       _androidHomeBannerUnitId =
           (androidHomeBannerUnitId ?? AppConfig.adsAndroidHomeBannerUnitId)
               .trim(),
       _iosHomeBannerUnitId =
           (iosHomeBannerUnitId ?? AppConfig.adsIosHomeBannerUnitId).trim(),
       _androidResultBannerUnitId =
           (androidResultBannerUnitId ?? AppConfig.adsAndroidResultBannerUnitId)
               .trim(),
       _iosResultBannerUnitId =
           (iosResultBannerUnitId ?? AppConfig.adsIosResultBannerUnitId).trim(),
       _androidRewardedHintUnitId =
           (androidRewardedHintUnitId ?? AppConfig.adsAndroidRewardedHintUnitId)
               .trim(),
       _iosRewardedHintUnitId =
           (iosRewardedHintUnitId ?? AppConfig.adsIosRewardedHintUnitId).trim(),
       _supportsAds = supportsAds ?? _defaultSupportsAds,
       _initializeAdsSdk =
           initializeAdsSdk ?? (() => MobileAds.instance.initialize());

  static final AdsService instance = AdsService();

  final bool _enabled;
  final bool _rewardedHintsEnabled;
  final String _androidBannerUnitId;
  final String _iosBannerUnitId;
  final String _androidHomeBannerUnitId;
  final String _iosHomeBannerUnitId;
  final String _androidResultBannerUnitId;
  final String _iosResultBannerUnitId;
  final String _androidRewardedHintUnitId;
  final String _iosRewardedHintUnitId;
  final AdsSupportResolver _supportsAds;
  final AdsSdkInitializer _initializeAdsSdk;

  bool _initialized = false;

  bool get isEnabled {
    if (!_enabled || !_supportsAds()) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _hasAnyBannerUnit(
        fallback: _androidBannerUnitId,
        home: _androidHomeBannerUnitId,
        result: _androidResultBannerUnitId,
      ),
      TargetPlatform.iOS => _hasAnyBannerUnit(
        fallback: _iosBannerUnitId,
        home: _iosHomeBannerUnitId,
        result: _iosResultBannerUnitId,
      ),
      _ => false,
    };
  }

  bool get isRewardedHintsEnabled {
    return _rewardedHintsEnabled &&
        _supportsAds() &&
        rewardedHintAdUnitId != null;
  }

  static bool _defaultSupportsAds() {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  bool isBannerEnabledForPlacement(String placement) {
    return _enabled &&
        _supportsAds() &&
        bannerAdUnitIdForPlacement(placement) != null;
  }

  String? get bannerAdUnitId {
    if (!_supportsAds()) return null;
    final fallback = switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidBannerUnitId,
      TargetPlatform.iOS => _iosBannerUnitId,
      _ => '',
    };
    if (fallback.isNotEmpty) return fallback;
    return bannerAdUnitIdForPlacement(placementHome) ??
        bannerAdUnitIdForPlacement(placementResult);
  }

  String? bannerAdUnitIdForPlacement(String placement) {
    if (!_supportsAds()) return null;
    final normalizedPlacement = placement.trim().toLowerCase();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _resolveBannerUnitId(
        placement: normalizedPlacement,
        fallback: _androidBannerUnitId,
        home: _androidHomeBannerUnitId,
        result: _androidResultBannerUnitId,
      ),
      TargetPlatform.iOS => _resolveBannerUnitId(
        placement: normalizedPlacement,
        fallback: _iosBannerUnitId,
        home: _iosHomeBannerUnitId,
        result: _iosResultBannerUnitId,
      ),
      _ => null,
    };
  }

  static bool _hasAnyBannerUnit({
    required String fallback,
    required String home,
    required String result,
  }) {
    return fallback.isNotEmpty || home.isNotEmpty || result.isNotEmpty;
  }

  static String? _resolveBannerUnitId({
    required String placement,
    required String fallback,
    required String home,
    required String result,
  }) {
    if (placement == placementHome && home.isNotEmpty) {
      return home;
    }
    if (placement == placementResult && result.isNotEmpty) {
      return result;
    }
    return fallback.isEmpty ? null : fallback;
  }

  String? get rewardedHintAdUnitId {
    if (!_supportsAds()) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _androidRewardedHintUnitId.isEmpty ? null : _androidRewardedHintUnitId,
      TargetPlatform.iOS =>
        _iosRewardedHintUnitId.isEmpty ? null : _iosRewardedHintUnitId,
      _ => null,
    };
  }

  /// Initializes Google Mobile Ads SDK once for current runtime.
  Future<void> initialize() async {
    if (_initialized || (!isEnabled && !isRewardedHintsEnabled)) return;
    _initialized = true;
    try {
      await _initializeAdsSdk();
    } catch (e, stackTrace) {
      debugPrint('AdsService initialize failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
