import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiznetic_flutter/services/analytics_consent.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> calls;
  late AnalyticsService analytics;
  late AnalyticsConsent consent;
  final now = DateTime(2026, 10, 24);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    analytics = AnalyticsService(
      isWeb: true,
      enabled: true,
      loadWebAnalytics: () async => calls.add('load'),
      disableWebAnalytics: () => calls.add('disable'),
      setCollectionEnabled: (on) async => calls.add('collection:$on'),
      logEvent: ({required name, parameters}) async => calls.add(name),
      logScreenView: ({screenName, screenClass}) async => calls.add('screen'),
    );
    consent = AnalyticsConsent(
      analytics: analytics,
      now: () => now,
      reload: () => calls.add('reload'),
    );
  });
  test(
    'no SDK or events before choice; rejected events are never replayed',
    () async {
      await analytics.initialize();
      await consent.initialize();
      await analytics.logEvent('before');
      await analytics.logScreenView(screenName: '/entry');
      expect(calls, ['disable']);
      await consent.choose(true);
      await analytics.logEvent('after');
      expect(calls, ['disable', 'load', 'collection:true', 'after']);
    },
  );
  test(
    'refusal persists, restores without SDK, and remains independent of Auth',
    () async {
      await consent.initialize();
      await consent.choose(false);
      final restored = AnalyticsConsent(analytics: analytics, now: () => now);
      await restored.initialize();
      expect(restored.choice, false);
      expect(calls, everyElement('disable'));
    },
  );
  test(
    'acceptance restores; withdrawal stops events before reload and clears choice',
    () async {
      await consent.initialize();
      await consent.choose(true);
      final restored = AnalyticsConsent(
        analytics: analytics,
        now: () => now,
        reload: () => calls.add('reload'),
      );
      await restored.initialize();
      expect(restored.choice, true);
      await restored.choose(false);
      await analytics.logEvent('must-not-send');
      expect(calls.sublist(calls.length - 3), [
        'disable',
        'collection:false',
        'reload',
      ]);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          AnalyticsConsent.choiceKey,
        ),
        false,
      );
    },
  );
  test('expired consent requires a new choice without loading SDK', () async {
    SharedPreferences.setMockInitialValues({
      AnalyticsConsent.choiceKey: true,
      AnalyticsConsent.timeKey: now
          .subtract(const Duration(days: 181))
          .millisecondsSinceEpoch,
    });
    await consent.initialize();
    expect(consent.choice, null);
    expect(calls, ['disable']);
  });
  test(
    'failed SDK opt-in remains off and is not restored next visit',
    () async {
      final failing = AnalyticsService(
        isWeb: true,
        enabled: true,
        loadWebAnalytics: () async => throw StateError('offline'),
        disableWebAnalytics: () {},
        setCollectionEnabled: (_) async {},
      );
      final controller = AnalyticsConsent(analytics: failing);
      await controller.initialize();
      await controller.choose(true);
      expect(controller.choice, null);
      expect(controller.error, isNotNull);
      expect(failing.canCollect, false);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          AnalyticsConsent.choiceKey,
        ),
        null,
      );
    },
  );
  test('paused Web ignores and removes earlier browser acceptance', () async {
    SharedPreferences.setMockInitialValues({
      AnalyticsConsent.choiceKey: true,
      AnalyticsConsent.timeKey: now.millisecondsSinceEpoch,
    });
    var loads = 0;
    var events = 0;
    final paused = AnalyticsService(
      isWeb: true,
      loadWebAnalytics: () async => loads++,
      disableWebAnalytics: () {},
      logEvent: ({required name, parameters}) async => events++,
    );
    final controller = AnalyticsConsent(analytics: paused, now: () => now);
    await controller.initialize();
    await controller.choose(true);
    await paused.setWebConsent(true);
    await paused.logEvent('must_not_send');
    expect(controller.available, false);
    expect(controller.choice, false);
    expect(paused.canCollect, false);
    expect(loads, 0);
    expect(events, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(AnalyticsConsent.choiceKey), false);
    expect(prefs.containsKey(AnalyticsConsent.timeKey), false);
  });

  test(
    'build kill switch prevents SDK initialization even with consent',
    () async {
      final disabled = AnalyticsService(
        isWeb: true,
        enabled: false,
        loadWebAnalytics: () async => calls.add('load'),
        disableWebAnalytics: () {},
      );
      await disabled.setWebConsent(true);
      expect(disabled.canCollect, false);
      expect(calls, isEmpty);
    },
  );
}
