import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('backend submit score feature flag defaults to false', () {
      expect(AppConfig.enableBackendSubmitScore, isFalse);
    });

    test('crash reporting feature flag defaults to true', () {
      expect(AppConfig.enableCrashReporting, isTrue);
    });

    test('analytics feature flag defaults to true', () {
      expect(AppConfig.enableAnalytics, isTrue);
    });

    test('apple sign-in feature flag defaults to false', () {
      expect(AppConfig.enableAppleSignIn, isFalse);
    });
  });
}
