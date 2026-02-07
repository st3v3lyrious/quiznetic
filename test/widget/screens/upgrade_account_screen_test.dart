import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';

void main() {
  test('exposes the expected route name', () {
    expect(UpgradeAccountScreen.routeName, equals('/upgrade'));
  });

  test('is a widget that can be instantiated', () {
    expect(const UpgradeAccountScreen(), isA<UpgradeAccountScreen>());
  });
}
