/*
 DOC: Utility
 Title: App Config
 Purpose: Provides compile-time configuration values used by app features.
*/
class AppConfig {
  AppConfig._();

  /// Compile-time Google OAuth client id, passed via --dart-define.
  static const googleOAuthClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
    defaultValue: '',
  );

  /// Enables backend-authoritative score submission via callable `submitScore`.
  ///
  /// This is OFF by default to keep Spark-plan compatibility and avoid
  /// requiring Cloud Functions/Cloud Build billing in local and low-cost
  /// environments.
  static const enableBackendSubmitScore = bool.fromEnvironment(
    'ENABLE_BACKEND_SUBMIT_SCORE',
    defaultValue: false,
  );

  /// Enables Firebase Crashlytics collection for runtime crash reporting.
  ///
  /// Keep this ON for release builds unless Crashlytics itself is suspected to
  /// be causing startup/runtime instability.
  static const enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: true,
  );

  /// Enables Firebase Analytics collection and event logging.
  ///
  /// Keep ON in release builds for baseline product telemetry and crash
  /// breadcrumbs unless analytics behavior itself is under investigation.
  static const enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  /// Enables Sign in with Apple provider surface in auth flows.
  ///
  /// Keep ON for production if Apple Auth is configured in Firebase + Apple
  /// Developer portals. Defaults OFF so MVP can launch safely if Apple setup is
  /// not completed yet.
  static const enableAppleSignIn = bool.fromEnvironment(
    'ENABLE_APPLE_SIGN_IN',
    defaultValue: false,
  );

  /// Enables mobile ad rendering in supported placements.
  ///
  /// Keep OFF until both Android/iOS ad unit ids are configured and ad policy
  /// validations are complete.
  static const enableAds = bool.fromEnvironment(
    'ENABLE_ADS',
    defaultValue: false,
  );

  /// Enables result-screen interstitial attempts.
  ///
  /// Keep OFF by default for safe MVP rollback and enable only after QA passes
  /// for load/show/fallback behavior.
  static const enableResultInterstitialAds = bool.fromEnvironment(
    'ENABLE_RESULT_INTERSTITIAL_ADS',
    defaultValue: false,
  );

  /// Allows non-test AdMob units in non-release builds.
  ///
  /// Keep OFF by default so debug/profile QA builds do not accidentally serve
  /// live ads when `ENABLE_ADS=true` unless explicitly intended.
  static const allowLiveAdUnitsInDebug = bool.fromEnvironment(
    'ALLOW_LIVE_AD_UNITS_IN_DEBUG',
    defaultValue: false,
  );

  /// Enables in-app purchase flows for monetization entitlements.
  ///
  /// Keep OFF until store products are configured and purchase/restore flows
  /// have passed manual QA.
  static const enableIap = bool.fromEnvironment(
    'ENABLE_IAP',
    defaultValue: false,
  );

  /// Canonical product id for the lifetime "Remove Ads" unlock.
  static const iapRemoveAdsProductId = String.fromEnvironment(
    'IAP_REMOVE_ADS_PRODUCT_ID',
    defaultValue: 'quiznetic.remove_ads_lifetime',
  );

  /// Enables rewarded-ad hint flow (remove two wrong answers).
  ///
  /// Keep OFF until rewarded ad placements and session-cap UX are validated.
  static const enableRewardedHints = bool.fromEnvironment(
    'ENABLE_REWARDED_HINTS',
    defaultValue: false,
  );

  /// Maximum rewarded hints a user can consume during one quiz session.
  static const rewardedHintsPerSession = int.fromEnvironment(
    'REWARDED_HINTS_PER_SESSION',
    defaultValue: 3,
  );

  /// Enables paid hint fallback after rewarded hint quota is exhausted.
  ///
  /// Keep OFF until consumable SKU setup and purchase/restore QA pass.
  static const enablePaidHints = bool.fromEnvironment(
    'ENABLE_PAID_HINTS',
    defaultValue: false,
  );

  /// Consumable SKU used to purchase one extra hint.
  static const iapHintConsumableProductId = String.fromEnvironment(
    'IAP_HINT_CONSUMABLE_PRODUCT_ID',
    defaultValue: 'quiznetic.hint_single',
  );

  /// Store-facing list price for one paid hint in USD cents.
  static const paidHintPriceUsdCents = int.fromEnvironment(
    'PAID_HINT_PRICE_USD_CENTS',
    defaultValue: 50,
  );

  /// Android banner ad unit id fallback used when placement-specific ids are
  /// not provided.
  static const adsAndroidBannerUnitId = String.fromEnvironment(
    'ADS_ANDROID_BANNER_UNIT_ID',
    defaultValue: '',
  );

  /// iOS banner ad unit id fallback used when placement-specific ids are not
  /// provided.
  static const adsIosBannerUnitId = String.fromEnvironment(
    'ADS_IOS_BANNER_UNIT_ID',
    defaultValue: '',
  );

  /// Android banner ad unit id for the home screen placement.
  static const adsAndroidHomeBannerUnitId = String.fromEnvironment(
    'ADS_ANDROID_HOME_BANNER_UNIT_ID',
    defaultValue: 'ca-app-pub-9485263915698875/3297690403',
  );

  /// iOS banner ad unit id for the home screen placement.
  static const adsIosHomeBannerUnitId = String.fromEnvironment(
    'ADS_IOS_HOME_BANNER_UNIT_ID',
    defaultValue: 'ca-app-pub-9485263915698875/8503108567',
  );

  /// Android banner ad unit id for the result screen placement.
  static const adsAndroidResultBannerUnitId = String.fromEnvironment(
    'ADS_ANDROID_RESULT_BANNER_UNIT_ID',
    defaultValue: '',
  );

  /// iOS banner ad unit id for the result screen placement.
  static const adsIosResultBannerUnitId = String.fromEnvironment(
    'ADS_IOS_RESULT_BANNER_UNIT_ID',
    defaultValue: '',
  );

  /// Android interstitial ad unit id for result-screen transitions.
  static const adsAndroidResultInterstitialUnitId = String.fromEnvironment(
    'ADS_ANDROID_RESULT_INTERSTITIAL_UNIT_ID',
    defaultValue: 'ca-app-pub-9485263915698875/2360517831',
  );

  /// iOS interstitial ad unit id for result-screen transitions.
  static const adsIosResultInterstitialUnitId = String.fromEnvironment(
    'ADS_IOS_RESULT_INTERSTITIAL_UNIT_ID',
    defaultValue: 'ca-app-pub-9485263915698875/6662220346',
  );

  /// Android rewarded ad unit id used for hint unlock flow.
  static const adsAndroidRewardedHintUnitId = String.fromEnvironment(
    'ADS_ANDROID_REWARDED_HINT_UNIT_ID',
    defaultValue: 'ca-app-pub-9485263915698875/3186009767',
  );

  /// iOS rewarded ad unit id used for hint unlock flow.
  static const adsIosRewardedHintUnitId = String.fromEnvironment(
    'ADS_IOS_REWARDED_HINT_UNIT_ID',
    defaultValue: 'ca-app-pub-9485263915698875/8542782807',
  );
}
