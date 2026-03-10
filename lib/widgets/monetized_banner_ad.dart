/*
 DOC: Widget
 Title: Monetized Banner Ad
 Purpose: Renders a banner ad only when ads are enabled and not removed.
*/
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quiznetic_flutter/services/ads_service.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';
import 'package:quiznetic_flutter/services/entitlement_service.dart';

class MonetizedBannerAd extends StatefulWidget {
  const MonetizedBannerAd({
    super.key,
    required this.placement,
    this.adsService,
    this.entitlementService,
    this.analyticsService,
  });

  final String placement;
  final AdsService? adsService;
  final EntitlementService? entitlementService;
  final AnalyticsService? analyticsService;

  @override
  State<MonetizedBannerAd> createState() => _MonetizedBannerAdState();
}

class _MonetizedBannerAdState extends State<MonetizedBannerAd> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _didRunInitialLoad = false;

  late final AdsService _adsService;
  late final EntitlementService _entitlementService;
  late final AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _adsService = widget.adsService ?? AdsService.instance;
    _entitlementService =
        widget.entitlementService ?? EntitlementService.instance;
    _analyticsService = widget.analyticsService ?? AnalyticsService.instance;
    _entitlementService.hasRemoveAdsListenable.addListener(
      _handleEntitlementUpdate,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRunInitialLoad) return;
    _didRunInitialLoad = true;
    unawaited(_maybeLoadBannerAd());
  }

  void _handleEntitlementUpdate() {
    if (_entitlementService.hasRemoveAds) {
      _disposeBannerAd();
      if (mounted) {
        setState(() {
          _loaded = false;
        });
      }
      return;
    }

    unawaited(_maybeLoadBannerAd());
  }

  Future<void> _maybeLoadBannerAd() async {
    if (!mounted ||
        !_adsService.isBannerEnabledForPlacement(widget.placement) ||
        _entitlementService.hasRemoveAds) {
      return;
    }
    if (_bannerAd != null) return;

    final adUnitId = _adsService.bannerAdUnitIdForPlacement(widget.placement);
    if (adUnitId == null || adUnitId.isEmpty) return;
    final adSize = await _resolveBannerAdSize();
    if (!mounted || _bannerAd != null) return;

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint(
            'Banner ad loaded [${widget.placement}] '
            'unit=${AdsService.maskAdUnitId(adUnitId)} '
            '${AdsService.summarizeResponseInfo(ad.responseInfo)}',
          );
          if (!mounted) return;
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          _disposeBannerAd(ad);
          if (!mounted) return;
          setState(() {
            _loaded = false;
          });
          debugPrint(
            AdsService.summarizeLoadAdError(
              format: 'banner',
              placement: widget.placement,
              adUnitId: adUnitId,
              error: error,
            ),
          );
          unawaited(
            _analyticsService.logEvent(
              'ad_banner_load_failed',
              parameters: AdsService.loadAdErrorAnalyticsParameters(
                placement: widget.placement,
                format: 'banner',
                adUnitId: adUnitId,
                error: error,
              ),
            ),
          );
        },
        onAdImpression: (ad) {
          unawaited(
            _analyticsService.logEvent(
              'ad_impression',
              parameters: {'placement': widget.placement},
            ),
          );
        },
        onAdClicked: (ad) {
          unawaited(
            _analyticsService.logEvent(
              'ad_click',
              parameters: {'placement': widget.placement},
            ),
          );
        },
      ),
    );

    _bannerAd = bannerAd;
    await bannerAd.load();
  }

  Future<AdSize> _resolveBannerAdSize() async {
    final mediaQuery = MediaQuery.maybeOf(context);
    final width = mediaQuery?.size.width.truncate() ?? 0;
    if (width <= 0) {
      return AdSize.banner;
    }

    final adaptive =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    return adaptive ?? AdSize.banner;
  }

  void _disposeBannerAd([Ad? ad]) {
    final adToDispose = ad ?? _bannerAd;
    if (adToDispose == null) return;

    if (identical(_bannerAd, adToDispose)) {
      _bannerAd = null;
    }
    adToDispose.dispose();
  }

  @override
  void dispose() {
    _entitlementService.hasRemoveAdsListenable.removeListener(
      _handleEntitlementUpdate,
    );
    _disposeBannerAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _entitlementService.hasRemoveAdsListenable,
      builder: (context, hasRemoveAds, _) {
        if (hasRemoveAds ||
            !_adsService.isBannerEnabledForPlacement(widget.placement) ||
            !_loaded ||
            _bannerAd == null) {
          return const SizedBox.shrink();
        }

        final bannerAd = _bannerAd!;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            key: Key('banner-ad-${widget.placement}'),
            width: bannerAd.size.width.toDouble(),
            height: bannerAd.size.height.toDouble(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AdWidget(ad: bannerAd),
            ),
          ),
        );
      },
    );
  }
}
