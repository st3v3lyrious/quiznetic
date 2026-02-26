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
    RewardedAd? loadedAd;
    Timer? showWatchdog;
    Timer? postRewardWatchdog;
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          loadedAd = ad;
          var rewardEarned = false;
          var finalized = false;
          var dismissed = false;
          void completeIfPending(bool value) {
            if (finalized) return;
            finalized = true;
            showWatchdog?.cancel();
            postRewardWatchdog?.cancel();
            if (!completer.isCompleted) {
              completer.complete(value);
            }
          }

          // Defensive watchdog for rare callback stalls that can leave the ad
          // overlay stuck on screen.
          showWatchdog = Timer(const Duration(seconds: 60), () {
            if (dismissed) return;
            debugPrint('Rewarded ad watchdog timeout; forcing cleanup.');
            unawaited(_safeStaticLogEvent('ad_rewarded_watchdog_timeout'));
            ad.dispose();
            completeIfPending(rewardEarned);
          });

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              dismissed = true;
              ad.dispose();
              completeIfPending(rewardEarned);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              dismissed = true;
              debugPrint('Rewarded ad failed to show: $error');
              unawaited(
                _safeStaticLogEvent(
                  'ad_rewarded_show_failed',
                  parameters: {
                    'error_code': error.code,
                    'error_domain': error.domain,
                  },
                ),
              );
              ad.dispose();
              completeIfPending(false);
            },
          );
          ad.show(
            onUserEarnedReward: (adWithoutView, rewardItem) {
              rewardEarned = true;
              // Reward should be granted as soon as SDK confirms earn event,
              // even if full-screen dismissal callback is delayed or missed.
              completeIfPending(true);
              // If close controls become unresponsive on some devices, force
              // cleanup shortly after reward is earned so gameplay can resume.
              postRewardWatchdog = Timer(const Duration(seconds: 8), () {
                if (dismissed) return;
                debugPrint(
                  'Rewarded ad did not dismiss after reward; forcing cleanup.',
                );
                unawaited(
                  _safeStaticLogEvent('ad_rewarded_postreward_forced_close'),
                );
                ad.dispose();
              });
            },
          );
        },
        onAdFailedToLoad: (error) {
          showWatchdog?.cancel();
          postRewardWatchdog?.cancel();
          debugPrint('Rewarded ad failed to load: $error');
          unawaited(
            _safeStaticLogEvent(
              'ad_rewarded_load_failed',
              parameters: {
                'error_code': error.code,
                'error_domain': error.domain,
              },
            ),
          );
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    final unlocked = await completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        debugPrint('Rewarded ad timed out.');
        unawaited(_safeStaticLogEvent('ad_rewarded_timeout'));
        loadedAd?.dispose();
        return false;
      },
    );
    showWatchdog?.cancel();
    postRewardWatchdog?.cancel();
    return unlocked;
  }

  static Future<void> _safeStaticLogEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    try {
      await AnalyticsService.instance.logEvent(name, parameters: parameters);
    } catch (e, stackTrace) {
      debugPrint('HintMonetizationService analytics event failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
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
