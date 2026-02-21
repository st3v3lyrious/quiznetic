# MONETIZATION SETUP (ADS + IAP)

This runbook documents how to activate monetization safely for MVP.

## Current Baseline (Shipped)

- Banner ad slots are implemented on:
  - `HomeScreen`
  - `ResultScreen`
- In-app purchase baseline is implemented for:
  - `Remove Ads (Lifetime)` non-consumable product
  - purchase initiation
  - restore purchases
  - persisted entitlement (`entitlement_remove_ads`)
- All monetization logic is behind compile-time flags and defaults to OFF.

## Ad Implementation Overview

- Ad provider/SDK: Google Mobile Ads (`google_mobile_ads` / AdMob).
- Core ad control service: `AdsService`.
  - Handles runtime gating and eligibility checks.
  - Resolves platform + placement ad unit IDs.
  - Initializes Mobile Ads SDK once per app runtime.
- Banner rendering component: `MonetizedBannerAd`.
  - Used on `HomeScreen` (placement: `home`).
  - Used on `ResultScreen` (placement: `result`).
- Ad visibility requirements:
  - `ENABLE_ADS=true`.
  - Running on supported mobile platform (Android/iOS).
  - Placement ad unit id is configured (or fallback banner id exists).
  - User does not have `remove_ads` entitlement.
- Placement/unit-id resolution:
  - Uses placement-specific keys first (`HOME`, `RESULT` by platform).
  - Falls back to shared platform banner keys when placement key is missing.
- Telemetry:
  - Banner impressions emit `ad_impression`.
  - Banner clicks emit `ad_click`.
- Rewarded ad usage (hints):
  - Controlled by `ENABLE_REWARDED_HINTS`.
  - Managed by hint monetization flow (`HintMonetizationService`) via `AdsService`.
  - Uses `ADS_ANDROID_REWARDED_HINT_UNIT_ID` / `ADS_IOS_REWARDED_HINT_UNIT_ID`.
- Result interstitial status:
  - Android interstitial unit id is configured via `ADS_ANDROID_RESULT_INTERSTITIAL_UNIT_ID`.
  - UI rendering flow for result interstitial is not yet enabled in-app; current result placement remains banner-based.

## Feature Flags

Defined in `lib/config/app_config.dart`:

- `ENABLE_ADS` (default: `false`)
- `ENABLE_IAP` (default: `false`)
- `IAP_REMOVE_ADS_PRODUCT_ID` (default: `quiznetic.remove_ads_lifetime`)
- `ADS_ANDROID_HOME_BANNER_UNIT_ID` (default: `ca-app-pub-9485263915698875/3297690403`)
- `ADS_IOS_HOME_BANNER_UNIT_ID` (default: `ca-app-pub-9485263915698875/8503108567`)
- `ADS_ANDROID_RESULT_BANNER_UNIT_ID` (default: empty)
- `ADS_IOS_RESULT_BANNER_UNIT_ID` (default: empty)
- `ADS_ANDROID_RESULT_INTERSTITIAL_UNIT_ID` (default: `ca-app-pub-9485263915698875/2360517831`)
- `ADS_IOS_RESULT_INTERSTITIAL_UNIT_ID` (default: `ca-app-pub-9485263915698875/6662220346`)
- `ADS_ANDROID_BANNER_UNIT_ID` (default: empty fallback for any placement)
- `ADS_IOS_BANNER_UNIT_ID` (default: empty fallback for any placement)
- `ADS_ANDROID_REWARDED_HINT_UNIT_ID` (default: `ca-app-pub-9485263915698875/3186009767`)
- `ADS_IOS_REWARDED_HINT_UNIT_ID` (default: `ca-app-pub-9485263915698875/8542782807`)
- `ENABLE_REWARDED_HINTS` (default: `false`)
- `REWARDED_HINTS_PER_SESSION` (default: `3`)
- `ENABLE_PAID_HINTS` (default: `false`)
- `IAP_HINT_CONSUMABLE_PRODUCT_ID` (default: `quiznetic.hint_single`)
- `PAID_HINT_PRICE_USD_CENTS` (default: `50`)

## Activation Conditions

Enable monetization only when all are true:

1. Ad network account is approved and payment profile is complete.
2. Store products are created and approved in Google Play / App Store Connect.
3. Product ID in store matches `IAP_REMOVE_ADS_PRODUCT_ID`.
4. Android/iOS ad unit IDs are created and mapped to release builds.
5. Sandbox purchase, cancel/fail, and restore flows pass manual QA.
6. Privacy policy/store metadata disclose ads + IAP behavior.
7. Hint flow QA passes when enabled (rewarded hint -> session cap -> paid fallback).

## Build Examples

### Safe baseline (no monetization)

```bash
flutter run \
  --dart-define=ENABLE_ADS=false \
  --dart-define=ENABLE_IAP=false
```

### Monetization QA build (non-production ad units)

```bash
flutter run \
  --dart-define=ENABLE_ADS=true \
  --dart-define=ENABLE_IAP=true \
  --dart-define=ENABLE_REWARDED_HINTS=false \
  --dart-define=ENABLE_PAID_HINTS=false \
  --dart-define=IAP_REMOVE_ADS_PRODUCT_ID=quiznetic.remove_ads_lifetime \
  --dart-define=ADS_ANDROID_HOME_BANNER_UNIT_ID=your.android.home.banner.unit.id \
  --dart-define=ADS_IOS_HOME_BANNER_UNIT_ID=your.ios.home.banner.unit.id \
  --dart-define=ADS_ANDROID_RESULT_BANNER_UNIT_ID=your.android.result.banner.unit.id \
  --dart-define=ADS_IOS_RESULT_BANNER_UNIT_ID=your.ios.result.banner.unit.id \
  --dart-define=ADS_ANDROID_RESULT_INTERSTITIAL_UNIT_ID=your.android.result.interstitial.unit.id
```

### Hint monetization QA build (rewarded + paid fallback)

```bash
flutter run \
  --dart-define=ENABLE_ADS=true \
  --dart-define=ENABLE_IAP=true \
  --dart-define=ENABLE_REWARDED_HINTS=true \
  --dart-define=ENABLE_PAID_HINTS=true \
  --dart-define=REWARDED_HINTS_PER_SESSION=3 \
  --dart-define=IAP_HINT_CONSUMABLE_PRODUCT_ID=quiznetic.hint_single \
  --dart-define=PAID_HINT_PRICE_USD_CENTS=50 \
  --dart-define=ADS_ANDROID_REWARDED_HINT_UNIT_ID=your.android.rewarded.unit.id \
  --dart-define=ADS_IOS_REWARDED_HINT_UNIT_ID=your.ios.rewarded.unit.id
```

## Rollback

If monetization causes instability or policy risk:

1. Set `ENABLE_ADS=false`.
2. Set `ENABLE_IAP=false`.
3. Cut hotfix build and re-run release checklist.

## Manual QA Focus

Use `docs/MVP_LAUNCH_TEST_CHECKLIST.md` section `Monetization Priority Gate`.
