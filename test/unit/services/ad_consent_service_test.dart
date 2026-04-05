import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quiznetic_flutter/services/ad_consent_service.dart';

void main() {
  group('AdConsentService', () {
    test(
      'runs consent info update and form flow before capturing snapshot',
      () async {
        ConsentRequestParameters? capturedParameters;
        var formShown = false;
        final service = AdConsentService(
          enabled: true,
          supportsAds: () => true,
          targetPlatformOverride: TargetPlatform.android,
          androidTestDeviceIds: const ['android-test-device-1234'],
          debugGeography: 'eea',
          requestConsentInfoUpdate: (parameters) async {
            capturedParameters = parameters;
            return null;
          },
          loadAndShowConsentFormIfRequired: () async {
            formShown = true;
            return null;
          },
          getConsentStatus: () async => ConsentStatus.obtained,
          canRequestAds: () async => true,
          isConsentFormAvailable: () async => true,
          getPrivacyOptionsRequirementStatus: () async =>
              PrivacyOptionsRequirementStatus.required,
          showPrivacyOptionsForm: () async => null,
        );

        final snapshot = await service.ensureConsentFlowCompleted();

        expect(formShown, isTrue);
        expect(snapshot.didAttemptInfoUpdate, isTrue);
        expect(snapshot.canRequestAds, isTrue);
        expect(snapshot.consentStatus, ConsentStatus.obtained);
        expect(snapshot.isPrivacyOptionsRequired, isTrue);
        expect(
          capturedParameters?.consentDebugSettings?.debugGeography,
          DebugGeography.debugGeographyEea,
        );
        expect(
          capturedParameters?.consentDebugSettings?.testIdentifiers,
          contains('android-test-device-1234'),
        );
      },
    );

    test(
      'captures prior-session canRequestAds state when update fails',
      () async {
        final service = AdConsentService(
          enabled: true,
          supportsAds: () => true,
          requestConsentInfoUpdate: (_) async =>
              FormError(errorCode: 7, message: 'network unavailable'),
          getConsentStatus: () async => ConsentStatus.required,
          canRequestAds: () async => true,
          isConsentFormAvailable: () async => false,
          getPrivacyOptionsRequirementStatus: () async =>
              PrivacyOptionsRequirementStatus.required,
          showPrivacyOptionsForm: () async => null,
        );

        final snapshot = await service.ensureConsentFlowCompleted();

        expect(snapshot.canRequestAds, isTrue);
        expect(snapshot.lastErrorMessage, contains('network unavailable'));
      },
    );

    test('privacy options form is not shown when not required', () async {
      var privacyOptionsCalls = 0;
      final service = AdConsentService(
        enabled: true,
        supportsAds: () => true,
        getConsentStatus: () async => ConsentStatus.obtained,
        canRequestAds: () async => true,
        isConsentFormAvailable: () async => false,
        getPrivacyOptionsRequirementStatus: () async =>
            PrivacyOptionsRequirementStatus.notRequired,
        showPrivacyOptionsForm: () async {
          privacyOptionsCalls++;
          return null;
        },
      );

      final result = await service.showPrivacyOptionsForm();

      expect(result, 'Privacy options are not required right now.');
      expect(privacyOptionsCalls, 0);
    });

    test(
      'refreshConsentFlow reruns consent update and recaches snapshot',
      () async {
        var updateCalls = 0;
        var canRequestAds = false;
        final service = AdConsentService(
          enabled: true,
          supportsAds: () => true,
          requestConsentInfoUpdate: (_) async {
            updateCalls++;
            return null;
          },
          loadAndShowConsentFormIfRequired: () async => null,
          getConsentStatus: () async =>
              canRequestAds ? ConsentStatus.obtained : ConsentStatus.required,
          canRequestAds: () async => canRequestAds,
          isConsentFormAvailable: () async => !canRequestAds,
          getPrivacyOptionsRequirementStatus: () async => canRequestAds
              ? PrivacyOptionsRequirementStatus.notRequired
              : PrivacyOptionsRequirementStatus.required,
          showPrivacyOptionsForm: () async => null,
        );

        final first = await service.ensureConsentFlowCompleted();
        canRequestAds = true;
        final refreshed = await service.refreshConsentFlow();
        final cached = await service.ensureConsentFlowCompleted();

        expect(first.canRequestAds, isFalse);
        expect(refreshed.canRequestAds, isTrue);
        expect(cached.canRequestAds, isTrue);
        expect(updateCalls, 2);
      },
    );
  });
}
