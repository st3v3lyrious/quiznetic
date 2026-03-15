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
import 'package:quiznetic_flutter/services/ad_overlay_recovery_service.dart';
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
       _logEvent = logEvent ?? AnalyticsService.instance.logEvent {
    _presentRewardedHintAd = presentRewardedHintAd ?? _presentRewardedHint;
  }

  static final HintMonetizationService instance = HintMonetizationService();

  final bool _rewardedHintsEnabled;
  final bool _paidHintsEnabled;
  final int _rewardedHintsPerSession;
  final int _paidHintPriceUsdCents;
  final AdsService _adsService;
  final IapService _iapService;
  late final RewardedHintPresenter _presentRewardedHintAd;
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
        final ready = await _adsService.ensureInitializedForAdRequests();
        if (!ready) {
          await _safeLogEvent('hint_rewarded_not_ready');
          if (_paidHintsEnabled) {
            await _safeLogEvent('hint_rewarded_unavailable_fallback_paid');
          } else {
            return const HintRequestResult(
              status: HintRequestStatus.unavailable,
              message: 'Rewarded hints are not available right now.',
            );
          }
        } else {
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

  Future<bool> _presentRewardedHint(String adUnitId) async {
    final completer = Completer<bool>();
    RewardedAd? loadedAd;
    Timer? loadWatchdog;
    Timer? showWatchdog;
    Timer? postRewardWatchdog;
    const loadTimeout = Duration(seconds: 20);
    final fullscreenTimeout = kDebugMode
        ? const Duration(seconds: 30)
        : const Duration(seconds: 45);
    void debugTrace(String message) {
      if (!kDebugMode) return;
      debugPrint(message);
    }

    void cancelAllWatchdogs() {
      loadWatchdog?.cancel();
      showWatchdog?.cancel();
      postRewardWatchdog?.cancel();
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          loadWatchdog?.cancel();
          if (completer.isCompleted) {
            debugTrace(
              'Rewarded ad lifecycle '
              'event=loaded_after_timeout '
              'unit=${AdsService.maskAdUnitId(adUnitId)}',
            );
            ad.dispose();
            return;
          }
          loadedAd = ad;
          debugTrace(
            'Rewarded ad loaded '
            'unit=${AdsService.maskAdUnitId(adUnitId)} '
            '${AdsService.summarizeResponseInfo(ad.responseInfo)}',
          );
          var rewardEarned = false;
          var finalized = false;
          var dismissed = false;
          var showed = false;
          var hadImpression = false;
          void logLifecycle(String event, {String? details}) {
            final buffer = StringBuffer(
              'Rewarded ad lifecycle '
              'event=$event '
              'unit=${AdsService.maskAdUnitId(adUnitId)} '
              'showed=$showed '
              'impression=$hadImpression '
              'rewardEarned=$rewardEarned '
              'dismissed=$dismissed '
              'finalized=$finalized',
            );
            if (details != null && details.isNotEmpty) {
              buffer.write(' $details');
            }
            debugTrace(buffer.toString());
          }

          void completeIfPending(bool value) {
            if (finalized) return;
            logLifecycle('finalize', details: 'result=$value');
            finalized = true;
            cancelAllWatchdogs();
            if (!completer.isCompleted) {
              completer.complete(value);
            }
          }

          Future<void> recoverOverlay(String reason) async {
            final recovered =
                await AdOverlayRecoveryService.finishStuckAdActivity(
                  reason: reason,
                );
            if (!recovered) {
              debugTrace(
                'Rewarded ad recovery did not finish an ad activity '
                'reason=$reason '
                'unit=${AdsService.maskAdUnitId(adUnitId)}',
              );
            }
          }

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              showed = true;
              logLifecycle(
                'shown',
                details:
                    'fullscreen_timeout_seconds='
                    '${fullscreenTimeout.inSeconds}',
              );
              // Once the ad is on screen, allow a much longer fullscreen
              // watchdog instead of timing out the entire request. Disposing a
              // rewarded ad mid-overlay can leave the native ad activity stuck.
              showWatchdog = Timer(fullscreenTimeout, () {
                if (dismissed) return;
                logLifecycle('watchdog_timeout');
                debugTrace('Rewarded ad watchdog timeout; forcing cleanup.');
                unawaited(_safeStaticLogEvent('ad_rewarded_watchdog_timeout'));
                _adsService.reportFullscreenAdHang(
                  format: 'rewarded',
                  reason: 'watchdog_timeout',
                );
                logLifecycle('dispose', details: 'reason=watchdog_timeout');
                ad.dispose();
                unawaited(recoverOverlay('watchdog_timeout'));
                completeIfPending(rewardEarned);
              });
            },
            onAdImpression: (ad) {
              hadImpression = true;
              logLifecycle('impression');
            },
            onAdDismissedFullScreenContent: (ad) {
              dismissed = true;
              logLifecycle('dismissed');
              logLifecycle('dispose', details: 'reason=dismissed');
              ad.dispose();
              completeIfPending(rewardEarned);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              dismissed = true;
              logLifecycle(
                'show_failed',
                details:
                    'code=${error.code} '
                    'domain=${error.domain} '
                    'message=${error.message}',
              );
              debugPrint(
                AdsService.summarizeAdError(
                  format: 'rewarded',
                  placement: 'hint',
                  adUnitId: adUnitId,
                  error: error,
                ),
              );
              unawaited(
                _safeStaticLogEvent(
                  'ad_rewarded_show_failed',
                  parameters: AdsService.adErrorAnalyticsParameters(
                    placement: 'hint',
                    format: 'rewarded',
                    adUnitId: adUnitId,
                    error: error,
                  ),
                ),
              );
              logLifecycle('dispose', details: 'reason=show_failed');
              ad.dispose();
              completeIfPending(false);
            },
          );
          logLifecycle('show_requested');
          ad.show(
            onUserEarnedReward: (adWithoutView, rewardItem) {
              rewardEarned = true;
              logLifecycle(
                'reward_earned',
                details:
                    'amount=${rewardItem.amount} '
                    'type=${rewardItem.type}',
              );
              // Reward should be granted as soon as SDK confirms earn event,
              // even if full-screen dismissal callback is delayed or missed.
              completeIfPending(true);
              // If close controls become unresponsive on some devices, force
              // cleanup shortly after reward is earned so gameplay can resume.
              postRewardWatchdog = Timer(const Duration(seconds: 8), () {
                if (dismissed) return;
                logLifecycle('post_reward_forced_close');
                debugTrace(
                  'Rewarded ad did not dismiss after reward; forcing cleanup.',
                );
                unawaited(
                  _safeStaticLogEvent('ad_rewarded_postreward_forced_close'),
                );
                _adsService.reportFullscreenAdHang(
                  format: 'rewarded',
                  reason: 'post_reward_forced_close',
                );
                logLifecycle('dispose', details: 'reason=post_reward_watchdog');
                ad.dispose();
                unawaited(recoverOverlay('post_reward_watchdog'));
              });
            },
          );
        },
        onAdFailedToLoad: (error) {
          cancelAllWatchdogs();
          debugTrace(
            'Rewarded ad lifecycle '
            'event=load_failed '
            'unit=${AdsService.maskAdUnitId(adUnitId)} '
            'code=${error.code} '
            'domain=${error.domain} '
            'message=${error.message}',
          );
          debugPrint(
            AdsService.summarizeLoadAdError(
              format: 'rewarded',
              placement: 'hint',
              adUnitId: adUnitId,
              error: error,
            ),
          );
          unawaited(
            _safeStaticLogEvent(
              'ad_rewarded_load_failed',
              parameters: AdsService.loadAdErrorAnalyticsParameters(
                placement: 'hint',
                format: 'rewarded',
                adUnitId: adUnitId,
                error: error,
              ),
            ),
          );
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    loadWatchdog = Timer(loadTimeout, () {
      if (loadedAd != null || completer.isCompleted) return;
      debugTrace(
        'Rewarded ad lifecycle '
        'event=load_timeout '
        'unit=${AdsService.maskAdUnitId(adUnitId)}',
      );
      debugTrace('Rewarded ad load timed out.');
      unawaited(_safeStaticLogEvent('ad_rewarded_load_timeout'));
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    final unlocked = await completer.future;
    cancelAllWatchdogs();
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
