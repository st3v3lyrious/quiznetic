/*
 DOC: Service
 Title: Hint Monetization Service
 Purpose: Manages rewarded and paid hint unlocks for one quiz session.
*/
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quiznetic_flutter/config/app_config.dart';
import 'package:quiznetic_flutter/services/ads_service.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';
import 'package:quiznetic_flutter/services/iap_service.dart';

typedef RewardedHintPresenter = Future<bool> Function(String adUnitId);
typedef HintAnalyticsLogger =
    Future<void> Function(String name, {Map<String, Object?>? parameters});

enum HintGrantSource { rewardedAd, paidHint }

enum HintRequestStatus { granted, disabled, unavailable, exhausted, failed }

class HintRequestResult {
  const HintRequestResult({
    required this.status,
    required this.message,
    this.source,
    this.rewardedHintsRemaining,
  });

  final HintRequestStatus status;
  final String message;
  final HintGrantSource? source;
  final int? rewardedHintsRemaining;
}

abstract class HintMonetizationGateway {
  bool get isEnabled;
  bool get hasRewardedHintsRemaining;
  bool get canOfferPaidHint;
  int get rewardedHintsRemaining;
  int get paidHintPriceUsdCents;

  void resetSession();
  Future<HintRequestResult> requestHint();
}

class HintMonetizationService implements HintMonetizationGateway {
  HintMonetizationService({
    bool? rewardedHintsEnabled,
    bool? paidHintsEnabled,
    int? rewardedHintsPerSession,
    int? paidHintPriceUsdCents,
    AdsService? adsService,
    IapService? iapService,
    RewardedHintPresenter? presentRewardedHintAd,
    HintAnalyticsLogger? logEvent,
  }) : _rewardedHintsEnabled =
           rewardedHintsEnabled ?? AppConfig.enableRewardedHints,
       _paidHintsEnabled = paidHintsEnabled ?? AppConfig.enablePaidHints,
       _rewardedHintsPerSession = math.max(
         0,
         rewardedHintsPerSession ?? AppConfig.rewardedHintsPerSession,
       ),
       _paidHintPriceUsdCents =
           paidHintPriceUsdCents ?? AppConfig.paidHintPriceUsdCents,
       _adsService = adsService ?? AdsService.instance,
       _iapService = iapService ?? IapService.instance,
       _presentRewardedHintAd =
           presentRewardedHintAd ?? _defaultPresentRewardedHintAd,
       _logEvent = logEvent ?? AnalyticsService.instance.logEvent;

  static final HintMonetizationService instance = HintMonetizationService();

  final bool _rewardedHintsEnabled;
  final bool _paidHintsEnabled;
  final int _rewardedHintsPerSession;
  final int _paidHintPriceUsdCents;
  final AdsService _adsService;
  final IapService _iapService;
  final RewardedHintPresenter _presentRewardedHintAd;
  final HintAnalyticsLogger _logEvent;

  int _rewardedHintsUsed = 0;

  @override
  bool get isEnabled => _rewardedHintsEnabled || _paidHintsEnabled;

  @override
  bool get hasRewardedHintsRemaining {
    return _rewardedHintsEnabled &&
        _rewardedHintsUsed < _rewardedHintsPerSession;
  }

  @override
  bool get canOfferPaidHint => _paidHintsEnabled;

  @override
  int get rewardedHintsRemaining {
    if (!_rewardedHintsEnabled) return 0;
    return math.max(0, _rewardedHintsPerSession - _rewardedHintsUsed);
  }

  @override
  int get paidHintPriceUsdCents => _paidHintPriceUsdCents;

  @override
  void resetSession() {
    _rewardedHintsUsed = 0;
  }

  @override
  Future<HintRequestResult> requestHint() async {
    if (!isEnabled) {
      return const HintRequestResult(
        status: HintRequestStatus.disabled,
        message: 'Hints are disabled in this build.',
      );
    }

    if (hasRewardedHintsRemaining) {
      final adUnitId = _adsService.rewardedHintAdUnitId;
      final rewardedConfigured =
          _adsService.isRewardedHintsEnabled &&
          adUnitId != null &&
          adUnitId.isNotEmpty;
      if (!rewardedConfigured) {
        if (_paidHintsEnabled) {
          await _safeLogEvent('hint_rewarded_unavailable_fallback_paid');
        } else {
          return const HintRequestResult(
            status: HintRequestStatus.unavailable,
            message: 'Rewarded hints are not configured right now.',
          );
        }
      } else {
        await _safeLogEvent(
          'hint_rewarded_requested',
          parameters: {'remaining_before': rewardedHintsRemaining},
        );

        final unlocked = await _presentRewardedHintAd(adUnitId);
        if (!unlocked) {
          await _safeLogEvent('hint_rewarded_not_granted');
          return const HintRequestResult(
            status: HintRequestStatus.failed,
            message: 'Hint was not unlocked. Please try again.',
          );
        }

        _rewardedHintsUsed++;
        await _safeLogEvent(
          'hint_rewarded_granted',
          parameters: {'remaining_after': rewardedHintsRemaining},
        );
        return HintRequestResult(
          status: HintRequestStatus.granted,
          source: HintGrantSource.rewardedAd,
          message: 'Hint unlocked by rewarded ad.',
          rewardedHintsRemaining: rewardedHintsRemaining,
        );
      }

      if (!_paidHintsEnabled) {
        return const HintRequestResult(
          status: HintRequestStatus.unavailable,
          message: 'Rewarded hints are not configured right now.',
        );
      }
    }

    if (_paidHintsEnabled) {
      await _safeLogEvent(
        'hint_paid_requested',
        parameters: {'price_usd_cents': _paidHintPriceUsdCents},
      );
      final purchaseResult = await _iapService.buySingleHint();
      if (purchaseResult.status == IapActionStatus.success) {
        await _safeLogEvent(
          'hint_paid_granted',
          parameters: {'price_usd_cents': _paidHintPriceUsdCents},
        );
        return HintRequestResult(
          status: HintRequestStatus.granted,
          source: HintGrantSource.paidHint,
          message: purchaseResult.message,
          rewardedHintsRemaining: rewardedHintsRemaining,
        );
      }

      return HintRequestResult(
        status: HintRequestStatus.failed,
        message: purchaseResult.message,
        rewardedHintsRemaining: rewardedHintsRemaining,
      );
    }

    return const HintRequestResult(
      status: HintRequestStatus.exhausted,
      message: 'No free hints left this session.',
    );
  }

  static Future<bool> _defaultPresentRewardedHintAd(String adUnitId) async {
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var rewardEarned = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(rewardEarned);
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
          );
          ad.show(
            onUserEarnedReward: (adWithoutView, rewardItem) {
              rewardEarned = true;
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () => false,
    );
  }

  Future<void> _safeLogEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    try {
      await _logEvent(name, parameters: parameters);
    } catch (e, stackTrace) {
      debugPrint('HintMonetizationService logEvent failed for "$name": $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
