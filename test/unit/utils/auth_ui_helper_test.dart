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
  });
}
