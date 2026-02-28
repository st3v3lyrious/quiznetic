/*
 DOC: Utility
 Title: Auth UI Helper
 Purpose: Centralizes auth-provider availability and auth-failure UX mapping.
*/
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/foundation.dart';
import 'package:quiznetic_flutter/config/app_config.dart';

class AuthUiHelper {
  AuthUiHelper._();

  /// Returns true when Google provider config is available.
  static bool isGoogleProviderEnabled(String clientId) {
    return clientId.trim().isNotEmpty;
  }

  /// Returns true when Apple provider is available in current build/platform.
  static bool isAppleProviderEnabled({
    bool? appleSignInEnabled,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    if (!(appleSignInEnabled ?? AppConfig.enableAppleSignIn)) {
      return false;
    }
    if (isWeb) {
      return true;
    }

    final resolvedPlatform = platform ?? defaultTargetPlatform;
    return resolvedPlatform == TargetPlatform.android ||
        resolvedPlatform == TargetPlatform.iOS ||
        resolvedPlatform == TargetPlatform.macOS;
  }

  /// Returns true when we should show an "Apple unavailable" notice.
  ///
  /// On Android we intentionally hide this notice to avoid irrelevant UX copy.
  static bool shouldShowAppleUnavailableMessage({
    required bool appleProviderEnabled,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    if (appleProviderEnabled) return false;
    if (isWeb) return true;

    final resolvedPlatform = platform ?? defaultTargetPlatform;
    return resolvedPlatform == TargetPlatform.iOS ||
        resolvedPlatform == TargetPlatform.macOS;
  }

  /// Maps Firebase Auth failures to user-safe sign-in messages.
  static String authFailureMessage(Exception exception) {
    if (isLikelyGoogleConfigIssue(exception)) {
      return 'Google sign-in is not configured for this app build yet. Please use email sign-in or try again later.';
    }

    if (exception is fba.FirebaseAuthException) {
      switch (exception.code) {
        case 'operation-not-allowed':
          return 'This sign-in method is currently unavailable. Please try another option.';
        case 'invalid-credential':
          return 'The sign-in credentials are invalid for this app build. Please try another sign-in option.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method. Use that method and try again.';
        case 'web-context-cancelled':
          return 'Sign-in was cancelled. Please try again.';
        case 'web-context-already-presented':
          return 'Another sign-in prompt is already open.';
        case 'missing-or-invalid-nonce':
          return 'Apple sign-in validation failed. Please try again.';
        case 'network-request-failed':
          return 'Network error while signing in. Check your connection and try again.';
      }
    }
    return 'Sign-in failed. Please try again.';
  }

  /// Normalized reason used for analytics segmentation.
  static String authFailureReason(Exception exception) {
    if (isLikelyGoogleConfigIssue(exception)) {
      return 'google_config';
    }
    if (exception is fba.FirebaseAuthException) {
      return exception.code;
    }
    return 'unknown';
  }

  /// Heuristics for Android Google auth setup errors surfaced as unknown.
  static bool isLikelyGoogleConfigIssue(Exception exception) {
    final raw = exception.toString().toLowerCase();
    return raw.contains('developer_error') ||
        raw.contains('apiexception: 10') ||
        raw.contains('12500') ||
        raw.contains('sign_in_failed');
  }
}
