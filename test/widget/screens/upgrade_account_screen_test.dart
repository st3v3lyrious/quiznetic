import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/foundation.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';

void main() {
  test('exposes the expected route name', () {
    expect(UpgradeAccountScreen.routeName, equals('/upgrade'));
  });

  test('is a widget that can be instantiated', () {
    expect(const UpgradeAccountScreen(), isA<UpgradeAccountScreen>());
  });

  test('buildProviders excludes Google when client id is missing', () {
    final providers = UpgradeAccountScreen.buildProviders(
      googleClientId: ' ',
      includeAppleProvider: true,
    );

    expect(providers.length, equals(2));
    expect(providers.first, isA<EmailAuthProvider>());
    expect(providers.last, isA<AppleProvider>());
    expect(providers.whereType<GoogleProvider>(), isEmpty);
  });

  test('buildProviders includes Google when client id is configured', () {
    final providers = UpgradeAccountScreen.buildProviders(
      googleClientId: 'my-google-client-id.apps.googleusercontent.com',
      includeAppleProvider: true,
    );

    expect(providers.length, equals(3));
    expect(providers.first, isA<EmailAuthProvider>());
    expect(providers[1], isA<GoogleProvider>());
    expect(providers.last, isA<AppleProvider>());
  });

  test('buildProviders excludes Apple when provider is disabled', () {
    final providers = UpgradeAccountScreen.buildProviders(
      googleClientId: 'my-google-client-id.apps.googleusercontent.com',
      includeAppleProvider: false,
    );

    expect(providers.length, equals(2));
    expect(providers.first, isA<EmailAuthProvider>());
    expect(providers.last, isA<GoogleProvider>());
    expect(providers.whereType<AppleProvider>(), isEmpty);
  });

  test('isAppleProviderEnabled returns false when feature flag is off', () {
    final enabled = UpgradeAccountScreen.isAppleProviderEnabled(
      appleSignInEnabled: false,
      isWeb: false,
      platform: TargetPlatform.iOS,
    );

    expect(enabled, isFalse);
  });

  test('isAppleProviderEnabled returns false on unsupported platforms', () {
    final enabled = UpgradeAccountScreen.isAppleProviderEnabled(
      appleSignInEnabled: true,
      isWeb: false,
      platform: TargetPlatform.windows,
    );

    expect(enabled, isFalse);
  });

  test('authFailureMessage maps network failures to safe text', () {
    final message = UpgradeAccountScreen.authFailureMessage(
      fba.FirebaseAuthException(code: 'network-request-failed'),
    );

    expect(message, contains('Network error'));
  });

  test('preservesGuestIdentity allows same uid', () {
    final result = UpgradeAccountScreen.preservesGuestIdentity(
      initialAnonymousUid: 'guest123',
      user: _FakeUser(uid: 'guest123'),
    );
    expect(result, isTrue);
  });

  test('preservesGuestIdentity rejects changed uid', () {
    final result = UpgradeAccountScreen.preservesGuestIdentity(
      initialAnonymousUid: 'guest123',
      user: _FakeUser(uid: 'user999'),
    );
    expect(result, isFalse);
  });
}

class _FakeUser implements fba.User {
  _FakeUser({required this.uid});

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
