import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/accessibility_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AccessibilityPreferences', () {
    test('defaults show flag descriptions to false when unset', () async {
      SharedPreferences.setMockInitialValues({});

      final enabled =
          await AccessibilityPreferences.showFlagDescriptionsEnabled();
      expect(enabled, isFalse);
    });

    test('persists show flag descriptions toggle', () async {
      SharedPreferences.setMockInitialValues({});

      await AccessibilityPreferences.setShowFlagDescriptionsEnabled(true);
      final enabled =
          await AccessibilityPreferences.showFlagDescriptionsEnabled();

      expect(enabled, isTrue);
    });
  });
}
