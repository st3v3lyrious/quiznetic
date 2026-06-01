import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/utils/auth_ui_helper.dart';

void main() {
  group('AuthUiHelper', () {
    test('isGoogleProviderEnabled requires a non-empty client id', () {
      expect(AuthUiHelper.isGoogleProviderEnabled(''), isFalse);
      expect(AuthUiHelper.isGoogleProviderEnabled('   '), isFalse);
      expect(
        AuthUiHelper.isGoogleProviderEnabled(
          'client-id.apps.googleusercontent.com',
        ),
        isTrue,
      );
    });

    test('isAppleProviderEnabled honors feature flag and platform', () {
      expect(
        AuthUiHelper.isAppleProviderEnabled(
          appleSignInEnabled: false,
          isWeb: false,
          platform: TargetPlatform.iOS,
        ),
        isFalse,
      );
      expect(
        AuthUiHelper.isAppleProviderEnabled(
          appleSignInEnabled: true,
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        isTrue,
      );
      expect(
        AuthUiHelper.isAppleProviderEnabled(
          appleSignInEnabled: true,
          isWeb: false,
          platform: TargetPlatform.windows,
        ),
        isFalse,
      );
    });

    test('shouldShowAppleUnavailableMessage hides copy on Android', () {
      expect(
        AuthUiHelper.shouldShowAppleUnavailableMessage(
          appleProviderEnabled: false,
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
      expect(
        AuthUiHelper.shouldShowAppleUnavailableMessage(
          appleProviderEnabled: false,
          isWeb: false,
          platform: TargetPlatform.iOS,
        ),
        isTrue,
      );
    });

    test('authFailureReason maps Google config issue heuristics', () {
      final exception = fba.FirebaseAuthException(
        code: 'unknown',
        message:
            'com.google.android.gms.common.api.ApiException: 10: DEVELOPER_ERROR',
      );

      expect(
        AuthUiHelper.authFailureReason(exception),
        equals('google_config'),
      );
      expect(
        AuthUiHelper.authFailureMessage(exception),
        contains('not configured'),
      );
    });

    test('authFailureReason maps firebase auth code when not heuristic', () {
      const code = 'network-request-failed';
      final exception = fba.FirebaseAuthException(code: code);

      expect(AuthUiHelper.authFailureReason(exception), equals(code));
      expect(AuthUiHelper.authFailureMessage(exception), contains('Network'));
    });

    test('detects existing-account collision auth failures', () {
      expect(
        AuthUiHelper.isExistingAccountCollision(
          fba.FirebaseAuthException(
            code: 'account-exists-with-different-credential',
          ),
        ),
        isTrue,
      );
      expect(
        AuthUiHelper.isExistingAccountCollision(
          fba.FirebaseAuthException(code: 'credential-already-in-use'),
        ),
        isTrue,
      );
      expect(
        AuthUiHelper.isExistingAccountCollision(
          fba.FirebaseAuthException(code: 'network-request-failed'),
        ),
        isFalse,
      );
    });

    test('recommends the strongest existing-account sign-in method label', () {
      expect(
        AuthUiHelper.recommendedExistingAccountMethodLabel(
          const ['password', 'google.com'],
        ),
        equals('email and password'),
      );
      expect(
        AuthUiHelper.recommendedExistingAccountMethodLabel(
          const ['google.com'],
        ),
        equals('Google'),
      );
      expect(
        AuthUiHelper.recommendedExistingAccountMethodLabel(
          const ['apple.com'],
        ),
        equals('Apple'),
      );
      expect(
        AuthUiHelper.recommendedExistingAccountMethodLabel(const ['phone']),
        equals('phone'),
      );
      expect(
        AuthUiHelper.recommendedExistingAccountMethodLabel(const ['github.com']),
        isNull,
      );
    });

    test('builds targeted existing-account recovery copy', () {
      expect(
        AuthUiHelper.existingAccountRecoveryMessage(
          email: 'player@example.com',
          signInMethods: const ['password'],
        ),
        contains('email and password'),
      );
      expect(
        AuthUiHelper.existingAccountRecoveryMessage(
          email: 'player@example.com',
          signInMethods: const ['google.com'],
        ),
        contains('Google'),
      );
      expect(
        AuthUiHelper.existingAccountRecoveryMessage(
          email: 'player@example.com',
          signInMethods: const ['github.com'],
        ),
        contains('different sign-in method'),
      );
    });
  });
}
