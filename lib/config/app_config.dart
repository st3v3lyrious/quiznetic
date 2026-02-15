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
}
