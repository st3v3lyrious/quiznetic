import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:quiznetic_flutter/screens/login_screen.dart';

void main() {
  test('exposes the expected route name', () {
    expect(LoginScreen.routeName, equals('/login'));
  });

  test('is a widget that can be instantiated', () {
    expect(const LoginScreen(), isA<LoginScreen>());
  });

  test('uses an existing logo asset path', () {
    expect(
      LoginScreen.logoAssetPath,
      equals('assets/images/logo-no-background.png'),
    );
  });

  test('buildProviders excludes Google when client id is missing', () {
    final providers = LoginScreen.buildProviders(
      googleClientId: '   ',
      includeAppleProvider: true,
    );

    expect(providers.length, equals(2));
    expect(providers.first, isA<EmailAuthProvider>());
    expect(providers.last, isA<AppleProvider>());
    expect(providers.whereType<GoogleProvider>(), isEmpty);
  });

  test('buildProviders includes Google when client id is configured', () {
    final providers = LoginScreen.buildProviders(
      googleClientId: 'my-google-client-id.apps.googleusercontent.com',
      includeAppleProvider: true,
    );

    expect(providers.length, equals(3));
    expect(providers.first, isA<EmailAuthProvider>());
    expect(providers[1], isA<GoogleProvider>());
    expect(providers.last, isA<AppleProvider>());
  });

  test('buildProviders excludes Apple when provider is disabled', () {
    final providers = LoginScreen.buildProviders(
      googleClientId: 'my-google-client-id.apps.googleusercontent.com',
      includeAppleProvider: false,
    );

    expect(providers.length, equals(2));
    expect(providers.first, isA<EmailAuthProvider>());
    expect(providers.last, isA<GoogleProvider>());
    expect(providers.whereType<AppleProvider>(), isEmpty);
  });

  test('isAppleProviderEnabled returns false when feature flag is off', () {
    final enabled = LoginScreen.isAppleProviderEnabled(
      appleSignInEnabled: false,
      isWeb: false,
      platform: TargetPlatform.iOS,
    );

    expect(enabled, isFalse);
  });

  test('isAppleProviderEnabled returns true on supported web surface', () {
    final enabled = LoginScreen.isAppleProviderEnabled(
      appleSignInEnabled: true,
      isWeb: true,
      platform: TargetPlatform.linux,
    );

    expect(enabled, isTrue);
  });

  test(
    'isAppleProviderEnabled returns false on unsupported non-web platforms',
    () {
      final enabled = LoginScreen.isAppleProviderEnabled(
        appleSignInEnabled: true,
        isWeb: false,
        platform: TargetPlatform.windows,
      );

      expect(enabled, isFalse);
    },
  );

  test(
    'shouldShowAppleUnavailableMessage is false on Android when Apple is disabled',
    () {
      final show = LoginScreen.shouldShowAppleUnavailableMessage(
        appleProviderEnabled: false,
        isWeb: false,
        platform: TargetPlatform.android,
      );

      expect(show, isFalse);
    },
  );

  test(
    'shouldShowAppleUnavailableMessage is true on iOS when Apple is disabled',
    () {
      final show = LoginScreen.shouldShowAppleUnavailableMessage(
        appleProviderEnabled: false,
        isWeb: false,
        platform: TargetPlatform.iOS,
      );

      expect(show, isTrue);
    },
  );

  test('authFailureMessage maps operation-not-allowed to safe text', () {
    final message = LoginScreen.authFailureMessage(
      fba.FirebaseAuthException(code: 'operation-not-allowed'),
    );

    expect(message, contains('currently unavailable'));
  });

  test('authFailureMessage maps Google config failure hints to safe text', () {
    final message = LoginScreen.authFailureMessage(
      fba.FirebaseAuthException(
        code: 'unknown',
        message:
            'com.google.android.gms.common.api.ApiException: 10: DEVELOPER_ERROR',
      ),
    );

    expect(message, contains('not configured'));
  });

  testWidgets('buildHeader stays renderable in tight vertical space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 120,
            child: Builder(
              builder: (context) {
                return LoginScreen.buildHeader(
                  context: context,
                  constraints: const BoxConstraints.tightFor(
                    width: 360,
                    height: 120,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Quiznetic'), findsOneWidget);
  });
}
