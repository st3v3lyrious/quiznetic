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
}
