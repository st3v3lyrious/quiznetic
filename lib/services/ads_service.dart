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

enum _AdUnitFormat { banner, interstitial, rewarded }

class AdsService {
  static const placementHome = 'home';
  static const placementResult = 'result';
  static const _googleTestBannerUnitIds = {
    'ca-app-pub-3940256099942544/6300978111', // Android banner
    'ca-app-pub-3940256099942544/2934735716', // iOS banner
  };
  static const _googleTestInterstitialUnitIds = {
    'ca-app-pub-3940256099942544/1033173712', // Android interstitial
    'ca-app-pub-3940256099942544/4411468910', // iOS interstitial
  };
  static const _googleTestRewardedUnitIds = {
    'ca-app-pub-3940256099942544/5224354917', // Android rewarded
    'ca-app-pub-3940256099942544/1712485313', // iOS rewarded
  };

  AdsService({
    bool? enabled,
    bool? resultInterstitialEnabled,
    bool? allowLiveAdUnitsInDebug,
    bool? rewardedHintsEnabled,
    String? androidBannerUnitId,
    String? iosBannerUnitId,
    String? androidHomeBannerUnitId,
    String? iosHomeBannerUnitId,
    String? androidResultBannerUnitId,
    String? iosResultBannerUnitId,
    String? androidResultInterstitialUnitId,
    String? iosResultInterstitialUnitId,
    String? androidRewardedHintUnitId,
    String? iosRewardedHintUnitId,
    AdsSupportResolver? supportsAds,
    AdsSdkInitializer? initializeAdsSdk,
  }) : _enabled = enabled ?? AppConfig.enableAds,
       _resultInterstitialEnabled =
           resultInterstitialEnabled ?? AppConfig.enableResultInterstitialAds,
       _allowLiveAdUnitsInDebug =
           allowLiveAdUnitsInDebug ?? AppConfig.allowLiveAdUnitsInDebug,
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
       _androidResultInterstitialUnitId =
           (androidResultInterstitialUnitId ??
                   AppConfig.adsAndroidResultInterstitialUnitId)
               .trim(),
       _iosResultInterstitialUnitId =
           (iosResultInterstitialUnitId ??
                   AppConfig.adsIosResultInterstitialUnitId)
               .trim(),
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
  final bool _resultInterstitialEnabled;
  final bool _allowLiveAdUnitsInDebug;
  final bool _rewardedHintsEnabled;
  final String _androidBannerUnitId;
  final String _iosBannerUnitId;
  final String _androidHomeBannerUnitId;
  final String _iosHomeBannerUnitId;
  final String _androidResultBannerUnitId;
  final String _iosResultBannerUnitId;
  final String _androidResultInterstitialUnitId;
  final String _iosResultInterstitialUnitId;
  final String _androidRewardedHintUnitId;
  final String _iosRewardedHintUnitId;
  final AdsSupportResolver _supportsAds;
  final AdsSdkInitializer _initializeAdsSdk;

  bool _initialized = false;
  final Set<String> _policyWarningsLogged = <String>{};

  bool get isEnabled {
    if (!_enabled || !_supportsAds()) return false;
    return bannerAdUnitIdForPlacement(placementHome) != null ||
        bannerAdUnitIdForPlacement(placementResult) != null;
  }

  bool get isRewardedHintsEnabled {
    return _rewardedHintsEnabled &&
        _supportsAds() &&
        rewardedHintAdUnitId != null;
  }

  bool get isResultInterstitialEnabled {
    return _enabled &&
        _resultInterstitialEnabled &&
        _supportsAds() &&
        resultInterstitialAdUnitId != null;
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
    final fallback = _rawBannerFallbackUnitId;
    if (fallback.isNotEmpty) return fallback;
    return bannerAdUnitIdForPlacement(placementHome) ??
        bannerAdUnitIdForPlacement(placementResult);
  }

  String? bannerAdUnitIdForPlacement(String placement) {
    if (!_supportsAds()) return null;
    final normalizedPlacement = placement.trim().toLowerCase();
    final rawUnitId = switch (defaultTargetPlatform) {
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
    return _enforceAdUnitPolicy(
      adUnitId: rawUnitId,
      format: _AdUnitFormat.banner,
      placementLabel: normalizedPlacement,
    );
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

  String? get resultInterstitialAdUnitId {
    if (!_supportsAds()) return null;
    final rawUnitId = switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidResultInterstitialUnitId,
      TargetPlatform.iOS => _iosResultInterstitialUnitId,
      _ => null,
    };
    return _enforceAdUnitPolicy(
      adUnitId: rawUnitId,
      format: _AdUnitFormat.interstitial,
      placementLabel: placementResult,
    );
  }

  String? get rewardedHintAdUnitId {
    if (!_supportsAds()) return null;
    final rawUnitId = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _androidRewardedHintUnitId.isEmpty ? null : _androidRewardedHintUnitId,
      TargetPlatform.iOS =>
        _iosRewardedHintUnitId.isEmpty ? null : _iosRewardedHintUnitId,
      _ => null,
    };
    return _enforceAdUnitPolicy(
      adUnitId: rawUnitId,
      format: _AdUnitFormat.rewarded,
      placementLabel: 'hint',
    );
  }

  String get _rawBannerFallbackUnitId {
    final rawUnitId = switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidBannerUnitId,
      TargetPlatform.iOS => _iosBannerUnitId,
      _ => '',
    };
    final policyUnitId = _enforceAdUnitPolicy(
      adUnitId: rawUnitId,
      format: _AdUnitFormat.banner,
      placementLabel: 'fallback',
    );
    return policyUnitId ?? '';
  }

  String? _enforceAdUnitPolicy({
    required String? adUnitId,
    required _AdUnitFormat format,
    required String placementLabel,
  }) {
    if (adUnitId == null || adUnitId.isEmpty) return null;
    if (_allowLiveAdUnitsInDebug || kReleaseMode) return adUnitId;
    if (!_looksLikeAdMobUnitId(adUnitId)) return adUnitId;
    if (_isOfficialGoogleTestAdUnit(adUnitId, format)) return adUnitId;

    _logPolicyWarning(
      format: format,
      placementLabel: placementLabel,
      adUnitId: adUnitId,
    );
    return null;
  }

  static bool _looksLikeAdMobUnitId(String adUnitId) {
    return adUnitId.startsWith('ca-app-pub-');
  }

  static bool _isOfficialGoogleTestAdUnit(
    String adUnitId,
    _AdUnitFormat format,
  ) {
    return switch (format) {
      _AdUnitFormat.banner => _googleTestBannerUnitIds.contains(adUnitId),
      _AdUnitFormat.interstitial => _googleTestInterstitialUnitIds.contains(
        adUnitId,
      ),
      _AdUnitFormat.rewarded => _googleTestRewardedUnitIds.contains(adUnitId),
    };
  }

  void _logPolicyWarning({
    required _AdUnitFormat format,
    required String placementLabel,
    required String adUnitId,
  }) {
    final warningKey = '$format::$placementLabel::$adUnitId';
    if (_policyWarningsLogged.contains(warningKey)) return;
    _policyWarningsLogged.add(warningKey);

    debugPrint(
      'AdsService blocked live AdMob unit for non-release build '
      '(format: $format, placement: $placementLabel). '
      'Use Google test ids or set ALLOW_LIVE_AD_UNITS_IN_DEBUG=true for '
      'explicit internal validation.',
    );
  }

  /// Initializes Google Mobile Ads SDK once for current runtime.
  Future<void> initialize() async {
    if (_initialized ||
        (!isEnabled &&
            !isRewardedHintsEnabled &&
            !isResultInterstitialEnabled)) {
      return;
    }
    _initialized = true;
    try {
      await _initializeAdsSdk();
    } catch (e, stackTrace) {
      debugPrint('AdsService initialize failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
