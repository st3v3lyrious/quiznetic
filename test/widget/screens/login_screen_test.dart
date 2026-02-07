import 'package:flutter_test/flutter_test.dart';
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
    final providers = LoginScreen.buildProviders(googleClientId: '   ');

    expect(providers.length, equals(2));
    expect(providers.first, isA<EmailAuthProvider>());
    expect(providers.last, isA<AppleProvider>());
    expect(providers.whereType<GoogleProvider>(), isEmpty);
  });

  test('buildProviders includes Google when client id is configured', () {
    final providers = LoginScreen.buildProviders(
      googleClientId: 'my-google-client-id.apps.googleusercontent.com',
    );

    expect(providers.length, equals(3));
    expect(providers.first, isA<EmailAuthProvider>());
    expect(providers[1], isA<GoogleProvider>());
    expect(providers.last, isA<AppleProvider>());
  });
}
