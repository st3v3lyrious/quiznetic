import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('backend submit score feature flag defaults to false', () {
      expect(AppConfig.enableBackendSubmitScore, isFalse);
    });
  });
}
