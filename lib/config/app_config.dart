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
}
