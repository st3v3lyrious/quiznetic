import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/entitlement_service.dart';

void main() {
  group('EntitlementService', () {
    test('initialize defaults remove ads entitlement to false', () async {
      final service = EntitlementService(
        loadBoolValue: (key) async => null,
        saveBoolValue: (key, value) async {},
      );

      await service.initialize();

      expect(service.hasRemoveAds, isFalse);
    });

    test('initialize loads persisted remove ads entitlement', () async {
      final service = EntitlementService(
        loadBoolValue: (key) async => true,
        saveBoolValue: (key, value) async {},
      );

      await service.initialize();

      expect(service.hasRemoveAds, isTrue);
    });

    test('setRemoveAds updates runtime value and persists', () async {
      String? persistedKey;
      bool? persistedValue;
      final service = EntitlementService(
        loadBoolValue: (_) async => null,
        saveBoolValue: (key, value) async {
          persistedKey = key;
          persistedValue = value;
        },
      );

      await service.initialize();
      await service.setRemoveAds(true);

      expect(service.hasRemoveAds, isTrue);
      expect(persistedKey, EntitlementService.removeAdsEntitlementKey);
      expect(persistedValue, isTrue);
    });

    test(
      'setRemoveAds keeps runtime entitlement even if persistence fails',
      () async {
        final service = EntitlementService(
          loadBoolValue: (key) async => null,
          saveBoolValue: (key, value) async => throw StateError('disk-failed'),
        );

        await service.initialize();
        await service.setRemoveAds(true);

        expect(service.hasRemoveAds, isTrue);
      },
    );
  });
}
