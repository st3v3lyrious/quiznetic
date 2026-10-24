import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiznetic_flutter/services/analytics_consent.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';
import 'package:quiznetic_flutter/widgets/analytics_consent_panel.dart';

void main() {
  testWidgets(
    'mobile panel offers equal choices, policy, and public withdrawal',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      var reloads = 0;
      var policy = 0;
      final controller = AnalyticsConsent(
        analytics: AnalyticsService(
          isWeb: true,
          enabled: true,
          loadWebAnalytics: () async {},
          disableWebAnalytics: () {},
          setCollectionEnabled: (_) async {},
        ),
        reload: () => reloads++,
      );
      await controller.initialize();
      await tester.pumpWidget(
        MaterialApp(
          home: AnalyticsConsentPanel(
            consent: controller,
            onPrivacy: () => policy++,
            child: const Scaffold(body: Text('Quiz')),
          ),
        ),
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Accept analytics'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Refuse analytics'),
        findsOneWidget,
      );
      await tester.tap(find.text('Privacy Policy'));
      expect(policy, 1);
      await tester.tap(find.text('Accept analytics'));
      await tester.pumpAndSettle();
      expect(find.text('Analytics preferences · On'), findsOneWidget);
      await tester.tap(find.text('Analytics preferences · On'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refuse analytics'));
      await tester.pumpAndSettle();
      expect(controller.choice, false);
      expect(reloads, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
