/*
 DOC: Service
 Title: Ads Service
 Purpose: Controls ad SDK enablement and placement eligibility.
*/
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quiznetic_flutter/config/app_config.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';

typedef AdsSupportResolver = bool Function();
typedef AdsSdkInitializer = Future<InitializationStatus?> Function();
typedef AdsSdkVersionResolver = Future<String> Function();
typedef AdsInspectorOpener = Future<String?> Function();
typedef AdsRequestConfigurationUpdater =
    Future<void> Function(RequestConfiguration configuration);
typedef AdsAnalyticsLogger =
    Future<void> Function(String name, {Map<String, Object?>? parameters});

enum _AdUnitFormat { banner, interstitial, rewarded }

class AdsService {
  static const placementHome = 'home';
  static const placementResult = 'result';

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
    Iterable<String>? debugBannerTestUnitIds,
    Iterable<String>? debugInterstitialTestUnitIds,
    Iterable<String>? debugRewardedTestUnitIds,
    Iterable<String>? androidTestDeviceIds,
    Iterable<String>? iosTestDeviceIds,
    bool Function(String adUnitId)? looksLikeAdMobUnitId,
    AdsSdkVersionResolver? getSdkVersion,
    AdsInspectorOpener? openAdInspector,
    AdsRequestConfigurationUpdater? updateRequestConfiguration,
    AdsSupportResolver? supportsAds,
    AdsSdkInitializer? initializeAdsSdk,
    AdsAnalyticsLogger? logEvent,
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
       _debugBannerTestUnitIds = _normalizedUnitIdSet(
         debugBannerTestUnitIds ??
             const [
               AppConfig.adsAndroidTestBannerUnitId,
               AppConfig.adsIosTestBannerUnitId,
             ],
       ),
       _debugInterstitialTestUnitIds = _normalizedUnitIdSet(
         debugInterstitialTestUnitIds ??
             const [
               AppConfig.adsAndroidTestInterstitialUnitId,
               AppConfig.adsIosTestInterstitialUnitId,
             ],
       ),
       _debugRewardedTestUnitIds = _normalizedUnitIdSet(
         debugRewardedTestUnitIds ??
             const [
               AppConfig.adsAndroidTestRewardedUnitId,
               AppConfig.adsIosTestRewardedUnitId,
             ],
       ),
       _androidTestDeviceIds = _normalizedStringList(
         androidTestDeviceIds ?? AppConfig.adsAndroidTestDeviceIds,
       ),
       _iosTestDeviceIds = _normalizedStringList(
         iosTestDeviceIds ?? AppConfig.adsIosTestDeviceIds,
       ),
       _looksLikeAdMobUnitId =
           looksLikeAdMobUnitId ?? _defaultLooksLikeAdMobUnitId,
       _getSdkVersion = getSdkVersion ?? _defaultGetSdkVersion,
       _openAdInspector = openAdInspector ?? _defaultOpenAdInspector,
       _updateRequestConfiguration =
           updateRequestConfiguration ?? _defaultUpdateRequestConfiguration,
       _supportsAds = supportsAds ?? _defaultSupportsAds,
       _initializeAdsSdk =
           initializeAdsSdk ?? (() => MobileAds.instance.initialize()),
       _logEvent = logEvent ?? AnalyticsService.instance.logEvent;

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
  final Set<String> _debugBannerTestUnitIds;
  final Set<String> _debugInterstitialTestUnitIds;
  final Set<String> _debugRewardedTestUnitIds;
  final List<String> _androidTestDeviceIds;
  final List<String> _iosTestDeviceIds;
  final bool Function(String adUnitId) _looksLikeAdMobUnitId;
  final AdsSdkVersionResolver _getSdkVersion;
  final AdsInspectorOpener _openAdInspector;
  final AdsRequestConfigurationUpdater _updateRequestConfiguration;
  final AdsSupportResolver _supportsAds;
  final AdsSdkInitializer _initializeAdsSdk;
  final AdsAnalyticsLogger _logEvent;

  bool _initialized = false;
  Future<void>? _initializationFuture;
  Future<InitializationStatus?>? _diagnosticsInitializationFuture;
  InitializationStatus? _initializationStatus;
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

  static bool _defaultLooksLikeAdMobUnitId(String adUnitId) {
    return adUnitId.startsWith('ca-app-pub-');
  }

  static Future<String?> _defaultOpenAdInspector() {
    final completer = Completer<String?>();
    MobileAds.instance.openAdInspector((error) {
      if (!completer.isCompleted) {
        if (error == null) {
          completer.complete(null);
          return;
        }
        final summary = [
          if ((error.code ?? '').isNotEmpty) 'code=${error.code}',
          if ((error.domain ?? '').isNotEmpty) 'domain=${error.domain}',
          if ((error.message ?? '').isNotEmpty) 'message=${error.message}',
        ].join(' ');
        completer.complete(
          summary.isEmpty ? 'Unknown Ad Inspector error.' : summary,
        );
      }
    });
    return completer.future;
  }

  static Future<String> _defaultGetSdkVersion() {
    return MobileAds.instance.getVersionString();
  }

  static Future<void> _defaultUpdateRequestConfiguration(
    RequestConfiguration configuration,
  ) {
    return MobileAds.instance.updateRequestConfiguration(configuration);
  }

  static Set<String> _normalizedUnitIdSet(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  static List<String> _normalizedStringList(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  bool get canOpenAdInspector => !kReleaseMode && _supportsAds();

  static String maskAdUnitId(String? adUnitId) {
    if (adUnitId == null || adUnitId.isEmpty) return 'unset';
    if (adUnitId.length <= 8) return '***';
    final tailLength = adUnitId.contains('~') ? 4 : 6;
    final tail = adUnitId.substring(adUnitId.length - tailLength);
    return '***$tail';
  }

  static String maskTestDeviceId(String testDeviceId) {
    if (testDeviceId.isEmpty) return 'unset';
    if (testDeviceId.length <= 6) return '***';
    return '***${testDeviceId.substring(testDeviceId.length - 4)}';
  }

  static String summarizeResponseInfo(ResponseInfo? responseInfo) {
    if (responseInfo == null) return 'response=none';
    final responseId = responseInfo.responseId ?? 'none';
    final adapter = responseInfo.mediationAdapterClassName ?? 'none';
    final adapterCount = responseInfo.adapterResponses?.length ?? 0;
    return 'responseId=$responseId adapter=$adapter adapterResponses=$adapterCount';
  }

  static String summarizeLoadAdError({
    required String format,
    required String placement,
    required String? adUnitId,
    required LoadAdError error,
  }) {
    return 'Ad $format load failed [$placement] '
        'unit=${maskAdUnitId(adUnitId)} '
        'code=${error.code} '
        'domain=${error.domain} '
        'message=${error.message} '
        '${summarizeResponseInfo(error.responseInfo)}';
  }

  static String summarizeAdError({
    required String format,
    required String placement,
    required String? adUnitId,
    required AdError error,
  }) {
    return 'Ad $format show failed [$placement] '
        'unit=${maskAdUnitId(adUnitId)} '
        'code=${error.code} '
        'domain=${error.domain} '
        'message=${error.message}';
  }

  static Map<String, Object?> loadAdErrorAnalyticsParameters({
    required String placement,
    required String format,
    required String? adUnitId,
    required LoadAdError error,
  }) {
    return {
      'placement': placement,
      'format': format,
      'error_code': error.code,
      'error_domain': error.domain,
      'ad_unit_mask': maskAdUnitId(adUnitId),
      'response_id': error.responseInfo?.responseId,
      'adapter_class': error.responseInfo?.mediationAdapterClassName,
    };
  }

  static Map<String, Object?> adErrorAnalyticsParameters({
    required String placement,
    required String format,
    required String? adUnitId,
    required AdError error,
  }) {
    return {
      'placement': placement,
      'format': format,
      'error_code': error.code,
      'error_domain': error.domain,
      'ad_unit_mask': maskAdUnitId(adUnitId),
    };
  }

  bool isBannerEnabledForPlacement(String placement) {
    return _enabled &&
        _supportsAds() &&
        bannerAdUnitIdForPlacement(placement) != null;
  }

  String? get bannerAdUnitId {
    if (!_enabled || !_supportsAds()) return null;
    final fallback = _rawBannerFallbackUnitId;
    if (fallback.isNotEmpty) return fallback;
    return bannerAdUnitIdForPlacement(placementHome) ??
        bannerAdUnitIdForPlacement(placementResult);
  }

  String? bannerAdUnitIdForPlacement(String placement) {
    if (!_enabled || !_supportsAds()) return null;
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
    if (!_enabled || !_resultInterstitialEnabled || !_supportsAds()) {
      return null;
    }
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
    if (!_enabled || !_rewardedHintsEnabled || !_supportsAds()) return null;
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
    if (_isConfiguredDebugTestAdUnit(adUnitId, format)) return adUnitId;

    _logPolicyWarning(
      format: format,
      placementLabel: placementLabel,
      adUnitId: adUnitId,
    );
    return null;
  }

  bool _isConfiguredDebugTestAdUnit(String adUnitId, _AdUnitFormat format) {
    return switch (format) {
      _AdUnitFormat.banner => _debugBannerTestUnitIds.contains(adUnitId),
      _AdUnitFormat.interstitial => _debugInterstitialTestUnitIds.contains(
        adUnitId,
      ),
      _AdUnitFormat.rewarded => _debugRewardedTestUnitIds.contains(adUnitId),
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
    unawaited(
      _safeLogEvent(
        'ad_policy_blocked_debug',
        parameters: {'format': format.name, 'placement': placementLabel},
      ),
    );
  }

  /// Initializes Google Mobile Ads SDK once for current runtime.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (!isEnabled && !isRewardedHintsEnabled && !isResultInterstitialEnabled) {
      return;
    }
    final existingInitialization = _initializationFuture;
    if (existingInitialization != null) {
      return existingInitialization;
    }

    final initialization = _runInitialize();
    _initializationFuture = initialization;
    return initialization;
  }

  /// Ensures the ad SDK is initialized before an ad request/show path runs.
  ///
  /// Returns `true` when initialization completed successfully for this
  /// runtime. Returns `false` when ads are disabled/unsupported or when the SDK
  /// initialization attempt failed.
  Future<bool> ensureInitializedForAdRequests() async {
    await initialize();
    return _initialized;
  }

  Future<void> _runInitialize() async {
    try {
      await _configureTestDevices();
      _initializationStatus = await _initializeAdsSdk();
      _initialized = true;
      if (!kReleaseMode && _initializationStatus != null) {
        debugPrint(_buildInitializationSummary(_initializationStatus!));
      }
    } catch (e, stackTrace) {
      _initialized = false;
      debugPrint('AdsService initialize failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      unawaited(
        _safeLogEvent(
          'ad_sdk_initialize_failed',
          parameters: {'error_type': e.runtimeType.toString()},
        ),
      );
    } finally {
      _initializationFuture = null;
    }
  }

  Future<String> buildDiagnosticsReport() async {
    final sdkVersion = await _resolveSdkVersion();
    final initializationStatus =
        await _ensureInitializationStatusForDiagnostics();
    final configuredTestDeviceIds = _currentPlatformTestDeviceIds;
    final buffer = StringBuffer()
      ..writeln('Ad diagnostics')
      ..writeln('platform=${defaultTargetPlatform.name}')
      ..writeln('release_mode=$kReleaseMode')
      ..writeln('ads_enabled=$_enabled')
      ..writeln('supports_ads=${_supportsAds()}')
      ..writeln('allow_live_in_debug=$_allowLiveAdUnitsInDebug')
      ..writeln('result_interstitial_enabled=$_resultInterstitialEnabled')
      ..writeln('rewarded_hints_enabled=$_rewardedHintsEnabled')
      ..writeln('sdk_version=${sdkVersion.isEmpty ? 'unknown' : sdkVersion}')
      ..writeln('test_device_count=${configuredTestDeviceIds.length}')
      ..writeln(
        'test_devices=${configuredTestDeviceIds.isEmpty ? 'none' : configuredTestDeviceIds.map(maskTestDeviceId).join(',')}',
      )
      ..writeln(
        'home_banner_raw=${maskAdUnitId(_rawBannerUnitIdForPlacement(placementHome))}',
      )
      ..writeln(
        'home_banner_resolved=${maskAdUnitId(bannerAdUnitIdForPlacement(placementHome))}',
      )
      ..writeln(
        'result_banner_raw=${maskAdUnitId(_rawBannerUnitIdForPlacement(placementResult))}',
      )
      ..writeln(
        'result_banner_resolved=${maskAdUnitId(bannerAdUnitIdForPlacement(placementResult))}',
      )
      ..writeln(
        'result_interstitial_raw=${maskAdUnitId(_rawResultInterstitialAdUnitId)}',
      )
      ..writeln(
        'result_interstitial_resolved=${maskAdUnitId(resultInterstitialAdUnitId)}',
      )
      ..writeln('rewarded_raw=${maskAdUnitId(_rawRewardedHintAdUnitId)}')
      ..writeln('rewarded_resolved=${maskAdUnitId(rewardedHintAdUnitId)}');

    if (initializationStatus == null) {
      buffer.writeln('initialization_status=unavailable');
    } else {
      final adapterEntries =
          initializationStatus.adapterStatuses.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
      if (adapterEntries.isEmpty) {
        buffer.writeln('initialization_status=no_adapters');
      } else {
        for (final entry in adapterEntries) {
          buffer.writeln(
            'adapter:${entry.key}=${entry.value.state.name}'
            ' latency=${entry.value.latency}'
            ' description=${entry.value.description}',
          );
        }
      }
    }

    await _safeLogEvent(
      'ad_debug_report_requested',
      parameters: {
        'ads_enabled': _enabled,
        'supports_ads': _supportsAds(),
        'allow_live_in_debug': _allowLiveAdUnitsInDebug,
      },
    );
    return buffer.toString().trim();
  }

  Future<String?> openInspector() async {
    if (!canOpenAdInspector) {
      return 'Ad Inspector is unavailable on this build.';
    }

    await _ensureInitializationStatusForDiagnostics();
    try {
      final error = await _openAdInspector();
      if (error == null) {
        await _safeLogEvent('ad_inspector_closed');
        return null;
      }
      debugPrint('Ad Inspector error: $error');
      await _safeLogEvent(
        'ad_inspector_failed',
        parameters: {'error_message': error},
      );
      return error;
    } catch (e, stackTrace) {
      debugPrint('Ad Inspector open failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      await _safeLogEvent(
        'ad_inspector_failed',
        parameters: {'error_type': e.runtimeType.toString()},
      );
      return e.toString();
    }
  }

  Future<InitializationStatus?>
  _ensureInitializationStatusForDiagnostics() async {
    if (!_supportsAds()) return null;
    if (_initializationStatus != null) return _initializationStatus;
    if (_initialized) return _initializationStatus;

    final existingInitialization = _initializationFuture;
    if (existingInitialization != null) {
      await existingInitialization;
      return _initializationStatus;
    }

    final existingDiagnosticsInitialization = _diagnosticsInitializationFuture;
    if (existingDiagnosticsInitialization != null) {
      return existingDiagnosticsInitialization;
    }

    final diagnosticsInitialization = _runDiagnosticsInitialize();
    _diagnosticsInitializationFuture = diagnosticsInitialization;
    return diagnosticsInitialization;
  }

  Future<InitializationStatus?> _runDiagnosticsInitialize() async {
    try {
      await _configureTestDevices();
      _initializationStatus = await _initializeAdsSdk();
      return _initializationStatus;
    } catch (e, stackTrace) {
      debugPrint('AdsService diagnostics initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } finally {
      _diagnosticsInitializationFuture = null;
    }
  }

  Future<String> _resolveSdkVersion() async {
    try {
      return await _getSdkVersion();
    } catch (e, stackTrace) {
      debugPrint('AdsService getVersionString failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return '';
    }
  }

  List<String> get _currentPlatformTestDeviceIds {
    if (kReleaseMode || !_supportsAds()) return const <String>[];
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidTestDeviceIds,
      TargetPlatform.iOS => _iosTestDeviceIds,
      _ => const <String>[],
    };
  }

  Future<void> _configureTestDevices() async {
    final testDeviceIds = _currentPlatformTestDeviceIds;
    if (testDeviceIds.isEmpty) return;

    try {
      await _updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
      debugPrint(
        'AdsService configured test devices: '
        '${testDeviceIds.map(maskTestDeviceId).join(', ')}',
      );
      await _safeLogEvent(
        'ad_test_devices_configured',
        parameters: {'count': testDeviceIds.length},
      );
    } catch (e, stackTrace) {
      debugPrint('AdsService test device configuration failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      await _safeLogEvent(
        'ad_test_device_configuration_failed',
        parameters: {'error_type': e.runtimeType.toString()},
      );
    }
  }

  String _buildInitializationSummary(InitializationStatus status) {
    final adapterEntries = status.adapterStatuses.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (adapterEntries.isEmpty) {
      return 'AdsService initialization completed with no adapter statuses.';
    }
    final summaries = adapterEntries
        .map(
          (entry) =>
              '${entry.key}:${entry.value.state.name}:${entry.value.latency}',
        )
        .join(', ');
    return 'AdsService initialization adapters: $summaries';
  }

  String? _rawBannerUnitIdForPlacement(String placement) {
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

  String? get _rawResultInterstitialAdUnitId {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _androidResultInterstitialUnitId.isEmpty
            ? null
            : _androidResultInterstitialUnitId,
      TargetPlatform.iOS =>
        _iosResultInterstitialUnitId.isEmpty
            ? null
            : _iosResultInterstitialUnitId,
      _ => null,
    };
  }

  String? get _rawRewardedHintAdUnitId {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _androidRewardedHintUnitId.isEmpty ? null : _androidRewardedHintUnitId,
      TargetPlatform.iOS =>
        _iosRewardedHintUnitId.isEmpty ? null : _iosRewardedHintUnitId,
      _ => null,
    };
  }

  Future<void> _safeLogEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    try {
      await _logEvent(name, parameters: parameters);
    } catch (e, stackTrace) {
      debugPrint('AdsService analytics event failed for "$name": $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
