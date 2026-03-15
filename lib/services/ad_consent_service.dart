/*
 DOC: Service
 Title: Ad Consent Service
 Purpose: Runs Google UMP consent flow and exposes ad-consent state.
*/
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quiznetic_flutter/config/app_config.dart';

typedef ConsentSupportResolver = bool Function();
typedef ConsentInfoUpdater =
    Future<FormError?> Function(ConsentRequestParameters parameters);
typedef ConsentFormPresenter = Future<FormError?> Function();
typedef ConsentStatusGetter = Future<ConsentStatus> Function();
typedef ConsentCanRequestAdsGetter = Future<bool> Function();
typedef ConsentFormAvailabilityGetter = Future<bool> Function();
typedef PrivacyOptionsRequirementGetter =
    Future<PrivacyOptionsRequirementStatus> Function();

class AdConsentSnapshot {
  const AdConsentSnapshot({
    required this.isEnabled,
    required this.didAttemptInfoUpdate,
    required this.consentStatus,
    required this.canRequestAds,
    required this.isConsentFormAvailable,
    required this.privacyOptionsRequirementStatus,
    required this.debugGeographyLabel,
    required this.tagForUnderAgeOfConsent,
    this.lastErrorMessage,
  });

  final bool isEnabled;
  final bool didAttemptInfoUpdate;
  final ConsentStatus consentStatus;
  final bool canRequestAds;
  final bool isConsentFormAvailable;
  final PrivacyOptionsRequirementStatus privacyOptionsRequirementStatus;
  final String debugGeographyLabel;
  final bool tagForUnderAgeOfConsent;
  final String? lastErrorMessage;

  bool get isPrivacyOptionsRequired {
    return privacyOptionsRequirementStatus ==
        PrivacyOptionsRequirementStatus.required;
  }
}

class AdConsentService {
  AdConsentService({
    bool? enabled,
    Iterable<String>? androidTestDeviceIds,
    Iterable<String>? iosTestDeviceIds,
    String? debugGeography,
    bool? tagForUnderAgeOfConsent,
    ConsentSupportResolver? supportsAds,
    TargetPlatform? targetPlatformOverride,
    ConsentInfoUpdater? requestConsentInfoUpdate,
    ConsentFormPresenter? loadAndShowConsentFormIfRequired,
    ConsentStatusGetter? getConsentStatus,
    ConsentCanRequestAdsGetter? canRequestAds,
    ConsentFormAvailabilityGetter? isConsentFormAvailable,
    PrivacyOptionsRequirementGetter? getPrivacyOptionsRequirementStatus,
    ConsentFormPresenter? showPrivacyOptionsForm,
  }) : _enabled = enabled ?? AppConfig.enableAds,
       _androidTestDeviceIds = _normalizedStringList(
         androidTestDeviceIds ?? AppConfig.adsAndroidTestDeviceIds,
       ),
       _iosTestDeviceIds = _normalizedStringList(
         iosTestDeviceIds ?? AppConfig.adsIosTestDeviceIds,
       ),
       _debugGeography = (debugGeography ?? AppConfig.adsConsentDebugGeography)
           .trim(),
       _tagForUnderAgeOfConsent =
           tagForUnderAgeOfConsent ?? AppConfig.adsTagForUnderAgeOfConsent,
       _supportsAds = supportsAds ?? _defaultSupportsAds,
       _targetPlatformOverride = targetPlatformOverride,
       _requestConsentInfoUpdate =
           requestConsentInfoUpdate ?? _defaultRequestConsentInfoUpdate,
       _loadAndShowConsentFormIfRequired =
           loadAndShowConsentFormIfRequired ??
           _defaultLoadAndShowConsentFormIfRequired,
       _getConsentStatus = getConsentStatus ?? _defaultGetConsentStatus,
       _canRequestAds = canRequestAds ?? _defaultCanRequestAds,
       _isConsentFormAvailable =
           isConsentFormAvailable ?? _defaultIsConsentFormAvailable,
       _getPrivacyOptionsRequirementStatus =
           getPrivacyOptionsRequirementStatus ??
           _defaultGetPrivacyOptionsRequirementStatus,
       _showPrivacyOptionsForm =
           showPrivacyOptionsForm ?? _defaultShowPrivacyOptionsForm;

  final bool _enabled;
  final List<String> _androidTestDeviceIds;
  final List<String> _iosTestDeviceIds;
  final String _debugGeography;
  final bool _tagForUnderAgeOfConsent;
  final ConsentSupportResolver _supportsAds;
  final TargetPlatform? _targetPlatformOverride;
  final ConsentInfoUpdater _requestConsentInfoUpdate;
  final ConsentFormPresenter _loadAndShowConsentFormIfRequired;
  final ConsentStatusGetter _getConsentStatus;
  final ConsentCanRequestAdsGetter _canRequestAds;
  final ConsentFormAvailabilityGetter _isConsentFormAvailable;
  final PrivacyOptionsRequirementGetter _getPrivacyOptionsRequirementStatus;
  final ConsentFormPresenter _showPrivacyOptionsForm;

  Future<AdConsentSnapshot>? _consentFlowFuture;
  bool _didCompleteInitialConsentFlow = false;
  AdConsentSnapshot? _lastSnapshot;

  bool get isEnabled => _enabled && _supportsAds();

  Future<AdConsentSnapshot> ensureConsentFlowCompleted() async {
    if (!isEnabled) {
      return _storeSnapshot(_buildDisabledSnapshot());
    }
    if (_didCompleteInitialConsentFlow && _lastSnapshot != null) {
      return _lastSnapshot!;
    }

    final existingFlow = _consentFlowFuture;
    if (existingFlow != null) {
      return existingFlow;
    }

    final flow = _runConsentFlow();
    _consentFlowFuture = flow;
    return flow;
  }

  Future<AdConsentSnapshot> currentSnapshot() async {
    if (!isEnabled) {
      return _storeSnapshot(_buildDisabledSnapshot());
    }

    return _captureSnapshot(
      didAttemptInfoUpdate: _lastSnapshot?.didAttemptInfoUpdate ?? false,
      lastErrorMessage: _lastSnapshot?.lastErrorMessage,
    );
  }

  Future<String?> showPrivacyOptionsForm() async {
    if (!isEnabled) {
      return 'Ad privacy choices are unavailable on this build.';
    }

    final snapshot = await currentSnapshot();
    if (!snapshot.isPrivacyOptionsRequired) {
      return 'Privacy options are not required right now.';
    }

    final error = await _showPrivacyOptionsForm();
    await _captureSnapshot(
      didAttemptInfoUpdate: snapshot.didAttemptInfoUpdate,
      lastErrorMessage: error == null
          ? null
          : _formatFormError('privacy_options', error),
    );
    return error == null ? null : _formatFormError('privacy_options', error);
  }

  Future<AdConsentSnapshot> _runConsentFlow() async {
    String? lastErrorMessage;
    try {
      final updateError = await _requestConsentInfoUpdate(
        _buildConsentRequestParameters(),
      );
      if (updateError != null) {
        lastErrorMessage = _formatFormError('consent_info_update', updateError);
      } else {
        final formError = await _loadAndShowConsentFormIfRequired();
        if (formError != null) {
          lastErrorMessage = _formatFormError(
            'consent_form_dismissed',
            formError,
          );
        }
      }

      return _captureSnapshot(
        didAttemptInfoUpdate: true,
        lastErrorMessage: lastErrorMessage,
      );
    } catch (e, stackTrace) {
      debugPrint('AdConsentService consent flow failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return _captureSnapshot(
        didAttemptInfoUpdate: true,
        lastErrorMessage: e.toString(),
      );
    } finally {
      _didCompleteInitialConsentFlow = true;
      _consentFlowFuture = null;
    }
  }

  ConsentRequestParameters _buildConsentRequestParameters() {
    final debugSettings = _buildConsentDebugSettings();
    return ConsentRequestParameters(
      tagForUnderAgeOfConsent: _tagForUnderAgeOfConsent,
      consentDebugSettings: debugSettings,
    );
  }

  ConsentDebugSettings? _buildConsentDebugSettings() {
    if (kReleaseMode) return null;
    final testIdentifiers = _currentPlatformTestDeviceIds;
    final debugGeography = _resolveDebugGeography(_debugGeography);
    if (testIdentifiers.isEmpty && debugGeography == null) {
      return null;
    }
    return ConsentDebugSettings(
      debugGeography: debugGeography,
      testIdentifiers: testIdentifiers.isEmpty ? null : testIdentifiers,
    );
  }

  List<String> get _currentPlatformTestDeviceIds {
    if (!isEnabled || kReleaseMode) return const <String>[];
    return switch (_targetPlatformOverride ?? defaultTargetPlatform) {
      TargetPlatform.android => _androidTestDeviceIds,
      TargetPlatform.iOS => _iosTestDeviceIds,
      _ => const <String>[],
    };
  }

  Future<AdConsentSnapshot> _captureSnapshot({
    required bool didAttemptInfoUpdate,
    String? lastErrorMessage,
  }) async {
    final consentStatus =
        await _safeRead(
          _getConsentStatus,
          fallback: _lastSnapshot?.consentStatus ?? ConsentStatus.unknown,
          label: 'getConsentStatus',
        ) ??
        ConsentStatus.unknown;
    final canRequestAds =
        await _safeRead(
          _canRequestAds,
          fallback: _lastSnapshot?.canRequestAds ?? false,
          label: 'canRequestAds',
        ) ??
        false;
    final isConsentFormAvailable =
        await _safeRead(
          _isConsentFormAvailable,
          fallback: _lastSnapshot?.isConsentFormAvailable ?? false,
          label: 'isConsentFormAvailable',
        ) ??
        false;
    final privacyOptionsRequirementStatus =
        await _safeRead(
          _getPrivacyOptionsRequirementStatus,
          fallback:
              _lastSnapshot?.privacyOptionsRequirementStatus ??
              PrivacyOptionsRequirementStatus.unknown,
          label: 'getPrivacyOptionsRequirementStatus',
        ) ??
        PrivacyOptionsRequirementStatus.unknown;

    return _storeSnapshot(
      AdConsentSnapshot(
        isEnabled: isEnabled,
        didAttemptInfoUpdate:
            didAttemptInfoUpdate ||
            (_lastSnapshot?.didAttemptInfoUpdate ?? false),
        consentStatus: consentStatus,
        canRequestAds: canRequestAds,
        isConsentFormAvailable: isConsentFormAvailable,
        privacyOptionsRequirementStatus: privacyOptionsRequirementStatus,
        debugGeographyLabel: _debugGeographyLabel(_debugGeography),
        tagForUnderAgeOfConsent: _tagForUnderAgeOfConsent,
        lastErrorMessage: lastErrorMessage ?? (_lastSnapshot?.lastErrorMessage),
      ),
    );
  }

  Future<T?> _safeRead<T>(
    Future<T> Function() action, {
    required T fallback,
    required String label,
  }) async {
    try {
      return await action();
    } catch (e, stackTrace) {
      debugPrint('AdConsentService $label failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return fallback;
    }
  }

  AdConsentSnapshot _buildDisabledSnapshot() {
    return AdConsentSnapshot(
      isEnabled: false,
      didAttemptInfoUpdate: false,
      consentStatus: ConsentStatus.unknown,
      canRequestAds: false,
      isConsentFormAvailable: false,
      privacyOptionsRequirementStatus: PrivacyOptionsRequirementStatus.unknown,
      debugGeographyLabel: _debugGeographyLabel(_debugGeography),
      tagForUnderAgeOfConsent: _tagForUnderAgeOfConsent,
    );
  }

  AdConsentSnapshot _storeSnapshot(AdConsentSnapshot snapshot) {
    _lastSnapshot = snapshot;
    return snapshot;
  }

  static List<String> _normalizedStringList(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static bool _defaultSupportsAds() {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  static Future<FormError?> _defaultRequestConsentInfoUpdate(
    ConsentRequestParameters parameters,
  ) {
    final completer = Completer<FormError?>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      parameters,
      () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      (error) {
        if (!completer.isCompleted) {
          completer.complete(error);
        }
      },
    );
    return completer.future;
  }

  static Future<FormError?> _defaultLoadAndShowConsentFormIfRequired() {
    final completer = Completer<FormError?>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (!completer.isCompleted) {
        completer.complete(error);
      }
    });
    return completer.future;
  }

  static Future<FormError?> _defaultShowPrivacyOptionsForm() {
    final completer = Completer<FormError?>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (!completer.isCompleted) {
        completer.complete(error);
      }
    });
    return completer.future;
  }

  static Future<ConsentStatus> _defaultGetConsentStatus() {
    return ConsentInformation.instance.getConsentStatus();
  }

  static Future<bool> _defaultCanRequestAds() {
    return ConsentInformation.instance.canRequestAds();
  }

  static Future<bool> _defaultIsConsentFormAvailable() {
    return ConsentInformation.instance.isConsentFormAvailable();
  }

  static Future<PrivacyOptionsRequirementStatus>
  _defaultGetPrivacyOptionsRequirementStatus() {
    return ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
  }

  static DebugGeography? _resolveDebugGeography(String raw) {
    switch (raw.trim().toLowerCase()) {
      case '':
      case 'disabled':
        return null;
      case 'eea':
      case 'uk':
        return DebugGeography.debugGeographyEea;
      case 'regulated_us_state':
      case 'us':
        return DebugGeography.debugGeographyRegulatedUsState;
      case 'other':
      case 'not_eea':
        return DebugGeography.debugGeographyOther;
      default:
        debugPrint(
          'AdConsentService ignoring unknown ADS_CONSENT_DEBUG_GEOGRAPHY='
          '"$raw". Supported values: eea, uk, regulated_us_state, us, '
          'other, not_eea, disabled, or empty.',
        );
        return null;
    }
  }

  static String _debugGeographyLabel(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return 'disabled';
    return normalized;
  }

  static String _formatFormError(String stage, FormError error) {
    return '$stage(code=${error.errorCode}, message=${error.message})';
  }
}
