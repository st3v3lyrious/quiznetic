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
}
