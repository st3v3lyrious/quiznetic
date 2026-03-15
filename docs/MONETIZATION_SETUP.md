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
  - Initializes Mobile Ads SDK once per app runtime after ad-consent state is ready.
- Ad consent/UMP service: `AdConsentService`.
  - Requests Google UMP consent info on app startup.
  - Shows the Google consent form when required.
  - Gates ad requests on `canRequestAds()`.
  - Exposes privacy-options state to `SettingsScreen`.
- Banner rendering component: `MonetizedBannerAd`.
  - Used on `HomeScreen` (placement: `home`).
  - Used on `ResultScreen` (placement: `result`).
- Ad visibility requirements:
  - `ENABLE_ADS=true`.
  - Running on supported mobile platform (Android/iOS).
  - Placement ad unit id is configured (or fallback banner id exists).
  - User does not have `remove_ads` entitlement.
- Policy/compliance guard:
  - Non-release builds block live AdMob `ca-app-pub-*` units by default.
  - Allowed in non-release only when unit id is an official Google test id, or when `ALLOW_LIVE_AD_UNITS_IN_DEBUG=true` is explicitly set.
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
  - Result interstitial runtime flow is implemented behind `ENABLE_RESULT_INTERSTITIAL_ADS` (default `false`).
  - Hybrid strategy is active when enabled: attempt result interstitial first, then fall back to result banner if load/show fails.
  - Interstitial telemetry emits:
    - `result_interstitial_requested`
    - `result_interstitial_shown`
    - `result_interstitial_fallback_banner`

## Platform Setup (Required)

Before enabling `ENABLE_ADS` or `ENABLE_REWARDED_HINTS` in QA/release builds,
ensure native AdMob platform keys are present.

### Android (`android/app/src/main/AndroidManifest.xml`)

Add AdMob app id metadata inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="${ADMOB_APP_ID}" />
```

- Use your AdMob **app id** (`~` separator), not an ad unit id (`/` separator).
- In this repo, the value comes from `.env` key `ADS_ANDROID_APP_ID`.
  `android/app/build.gradle.kts` reads `ADS_ANDROID_APP_ID` and injects it into
  the manifest placeholder `ADMOB_APP_ID`, which is then consumed by
  `android:value="${ADMOB_APP_ID}"`.

### iOS (`ios/Runner/Info.plist`)

Add AdMob app id:

```xml
<key>GADApplicationIdentifier</key>
<string>$(ADS_IOS_APP_ID)</string>
```

Add required SKAdNetwork IDs:

```xml
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
  <!-- Add the full current list from Google Mobile Ads docs -->
</array>
```

- Keep SKAdNetwork list up to date with Google Mobile Ads SDK requirements.
- If ATT is used for personalized ads, also ensure `NSUserTrackingUsageDescription`
  and your ATT flow are configured.

### iOS ATT MVP default

- `NSUserTrackingUsageDescription` is configured in `ios/Runner/Info.plist`.
- MVP default behavior does not force ATT prompt before showing ads.
- ATT runtime prompt/consent flow should be implemented only when monetization
  scope includes IDFA usage, personalized ads, or advanced attribution.
- If you later enable ATT prompt flow, validate behavior for both
  `authorized` and `denied/restricted` states during monetization QA.

## Ad Consent / Privacy Messaging (Required For Live EEA/UK Ads)

The app-side UMP flow is now implemented, but live EEA/UK ads still require the
AdMob console side to be configured for the current app.

### AdMob console prerequisites

1. Host a public privacy-policy URL for the app.
2. In AdMob `Privacy & messaging`, publish a `European regulations` message for
   the current AdMob app entry.
3. Re-test on a registered test device after the message is published.

Without that console-side message, the in-app UMP code can still run, but live
EEA/UK monetization may remain blocked or no-fill.

### App-side baseline now shipped

- Launch-time consent info update + consent-form display when required
- Ad requests gated on `canRequestAds()`
- Settings entry point for privacy options (`Ad Privacy Choices`)
- Consent status included in ad diagnostics report

### Consent QA env helpers

- `ADS_ANDROID_TEST_DEVICE_IDS`
- `ADS_IOS_TEST_DEVICE_IDS`
- `ADS_CONSENT_DEBUG_GEOGRAPHY`
  - supported values: `eea`, `uk` (alias of `eea`), `regulated_us_state`, `other`
- `ADS_TAG_FOR_UNDER_AGE_OF_CONSENT`

## Feature Flags

Defined in `lib/config/app_config.dart`:

- `ENABLE_ADS` (default: `false`)
- `ENABLE_RESULT_INTERSTITIAL_ADS` (default: `false`)
- `ALLOW_LIVE_AD_UNITS_IN_DEBUG` (default: `false`)
- `ADS_ANDROID_TEST_DEVICE_IDS` (default: empty comma-separated list)
- `ADS_IOS_TEST_DEVICE_IDS` (default: empty comma-separated list)
- `ADS_CONSENT_DEBUG_GEOGRAPHY` (default: empty / SDK default)
- `ADS_TAG_FOR_UNDER_AGE_OF_CONSENT` (default: `false`)
- `ENABLE_IAP` (default: `false`)
- `IAP_REMOVE_ADS_PRODUCT_ID` (default: `quiznetic.remove_ads_lifetime`)
- `ADS_ANDROID_HOME_BANNER_UNIT_ID` (default: empty)
- `ADS_IOS_HOME_BANNER_UNIT_ID` (default: empty)
- `ADS_ANDROID_RESULT_BANNER_UNIT_ID` (default: empty)
- `ADS_IOS_RESULT_BANNER_UNIT_ID` (default: empty)
- `ADS_ANDROID_RESULT_INTERSTITIAL_UNIT_ID` (default: empty)
- `ADS_IOS_RESULT_INTERSTITIAL_UNIT_ID` (default: empty)
- `ADS_ANDROID_BANNER_UNIT_ID` (default: empty fallback for any placement)
- `ADS_IOS_BANNER_UNIT_ID` (default: empty fallback for any placement)
- `ADS_ANDROID_REWARDED_HINT_UNIT_ID` (default: empty)
- `ADS_IOS_REWARDED_HINT_UNIT_ID` (default: empty)
- `ADS_ANDROID_TEST_BANNER_UNIT_ID` (default: empty)
- `ADS_IOS_TEST_BANNER_UNIT_ID` (default: empty)
- `ADS_ANDROID_TEST_INTERSTITIAL_UNIT_ID` (default: empty)
- `ADS_IOS_TEST_INTERSTITIAL_UNIT_ID` (default: empty)
- `ADS_ANDROID_TEST_REWARDED_UNIT_ID` (default: empty)
- `ADS_IOS_TEST_REWARDED_UNIT_ID` (default: empty)
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
8. Non-release QA builds use Google test ids (or explicitly set `ALLOW_LIVE_AD_UNITS_IN_DEBUG=true` for tightly controlled internal validation only).
9. If Ad Inspector or test-mode behavior is inconsistent, set `ADS_ANDROID_TEST_DEVICE_IDS` / `ADS_IOS_TEST_DEVICE_IDS` so the app registers test devices programmatically before initializing the SDK.
10. AdMob `Privacy & messaging` is published for the current app, with a public privacy-policy URL configured for the message.
11. `ENABLE_RESULT_INTERSTITIAL_ADS` is enabled only after result flow QA passes (show + failure fallback + no-regression checks).

When using Google test units in non-release builds, provide them through env:

- `ADS_ANDROID_TEST_BANNER_UNIT_ID`
- `ADS_IOS_TEST_BANNER_UNIT_ID`
- `ADS_ANDROID_TEST_INTERSTITIAL_UNIT_ID`
- `ADS_IOS_TEST_INTERSTITIAL_UNIT_ID`
- `ADS_ANDROID_TEST_REWARDED_UNIT_ID`
- `ADS_IOS_TEST_REWARDED_UNIT_ID`
- `ADS_ANDROID_TEST_DEVICE_IDS`
- `ADS_IOS_TEST_DEVICE_IDS`

## Build Examples

Populate `.env` first, then run with:

```bash
./tools/sync_env.sh
flutter run --dart-define-from-file=.env
```

`tools/sync_env.sh` expects a plain `KEY=VALUE` `.env` file. Keep comments on
their own lines and do not use shell expressions in env values.

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
  --dart-define=ENABLE_RESULT_INTERSTITIAL_ADS=false \
  --dart-define=ALLOW_LIVE_AD_UNITS_IN_DEBUG=false \
  --dart-define=ADS_ANDROID_TEST_DEVICE_IDS=$ADS_ANDROID_TEST_DEVICE_IDS \
  --dart-define=ADS_IOS_TEST_DEVICE_IDS=$ADS_IOS_TEST_DEVICE_IDS \
  --dart-define=ENABLE_IAP=true \
  --dart-define=ENABLE_REWARDED_HINTS=false \
  --dart-define=ENABLE_PAID_HINTS=false \
  --dart-define=IAP_REMOVE_ADS_PRODUCT_ID=quiznetic.remove_ads_lifetime \
  --dart-define=ADS_ANDROID_HOME_BANNER_UNIT_ID=$ADS_ANDROID_TEST_BANNER_UNIT_ID \
  --dart-define=ADS_IOS_HOME_BANNER_UNIT_ID=$ADS_IOS_TEST_BANNER_UNIT_ID \
  --dart-define=ADS_ANDROID_RESULT_BANNER_UNIT_ID=$ADS_ANDROID_TEST_BANNER_UNIT_ID \
  --dart-define=ADS_IOS_RESULT_BANNER_UNIT_ID=$ADS_IOS_TEST_BANNER_UNIT_ID \
  --dart-define=ADS_ANDROID_RESULT_INTERSTITIAL_UNIT_ID=$ADS_ANDROID_TEST_INTERSTITIAL_UNIT_ID \
  --dart-define=ADS_IOS_RESULT_INTERSTITIAL_UNIT_ID=$ADS_IOS_TEST_INTERSTITIAL_UNIT_ID
```

### Hint monetization QA build (rewarded + paid fallback)

```bash
flutter run \
  --dart-define=ENABLE_ADS=true \
  --dart-define=ENABLE_RESULT_INTERSTITIAL_ADS=false \
  --dart-define=ALLOW_LIVE_AD_UNITS_IN_DEBUG=false \
  --dart-define=ADS_ANDROID_TEST_DEVICE_IDS=$ADS_ANDROID_TEST_DEVICE_IDS \
  --dart-define=ADS_IOS_TEST_DEVICE_IDS=$ADS_IOS_TEST_DEVICE_IDS \
  --dart-define=ENABLE_IAP=true \
  --dart-define=ENABLE_REWARDED_HINTS=true \
  --dart-define=ENABLE_PAID_HINTS=true \
  --dart-define=REWARDED_HINTS_PER_SESSION=3 \
  --dart-define=IAP_HINT_CONSUMABLE_PRODUCT_ID=quiznetic.hint_single \
  --dart-define=PAID_HINT_PRICE_USD_CENTS=50 \
  --dart-define=ADS_ANDROID_REWARDED_HINT_UNIT_ID=$ADS_ANDROID_TEST_REWARDED_UNIT_ID \
  --dart-define=ADS_IOS_REWARDED_HINT_UNIT_ID=$ADS_IOS_TEST_REWARDED_UNIT_ID
```

### Result hybrid ad QA build (interstitial-first + banner fallback)

```bash
flutter run \
  --dart-define=ENABLE_ADS=true \
  --dart-define=ENABLE_RESULT_INTERSTITIAL_ADS=true \
  --dart-define=ALLOW_LIVE_AD_UNITS_IN_DEBUG=false \
  --dart-define=ADS_ANDROID_TEST_DEVICE_IDS=$ADS_ANDROID_TEST_DEVICE_IDS \
  --dart-define=ADS_IOS_TEST_DEVICE_IDS=$ADS_IOS_TEST_DEVICE_IDS \
  --dart-define=ADS_ANDROID_RESULT_INTERSTITIAL_UNIT_ID=$ADS_ANDROID_TEST_INTERSTITIAL_UNIT_ID \
  --dart-define=ADS_IOS_RESULT_INTERSTITIAL_UNIT_ID=$ADS_IOS_TEST_INTERSTITIAL_UNIT_ID \
  --dart-define=ADS_ANDROID_RESULT_BANNER_UNIT_ID=$ADS_ANDROID_TEST_BANNER_UNIT_ID \
  --dart-define=ADS_IOS_RESULT_BANNER_UNIT_ID=$ADS_IOS_TEST_BANNER_UNIT_ID
```

## app-ads.txt Baseline

- Template file is provided at `docs/app-ads.txt.example`.
- Choose a production domain for hosting (for example `quiznetic.com` or
  `quizneticapp.com`).
- Publish this content as `https://<your-domain>/app-ads.txt` on the domain
  linked from your store listing before enabling live ads in production.
- Add the exact `app-ads.txt` URL/domain in Google Play Console and
  App Store Connect metadata.

## Rollback

If monetization causes instability or policy risk:

1. Set `ENABLE_ADS=false`.
2. Set `ENABLE_IAP=false`.
3. Cut hotfix build and re-run release checklist.

## Manual QA Focus

Use `docs/MVP_LAUNCH_TEST_CHECKLIST.md` section `Monetization Priority Gate`.
