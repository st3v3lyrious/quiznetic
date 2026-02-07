import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/login_screen.dart';

void main() {
  test('exposes the expected route name', () {
    expect(LoginScreen.routeName, equals('/login'));
  });

  test('is a widget that can be instantiated', () {
    expect(const LoginScreen(), isA<LoginScreen>());
  });
}
