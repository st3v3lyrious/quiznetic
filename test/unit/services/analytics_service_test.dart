import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    test(
      'initialize toggles analytics collection based on feature flag',
      () async {
        bool? enabledValue;
        final service = AnalyticsService(
          enabled: true,
          setCollectionEnabled: (enabled) async {
            enabledValue = enabled;
          },
          logEvent: ({required name, parameters}) async {},
          logScreenView: ({screenName, screenClass}) async {},
          logCrashBreadcrumb: (_) {},
        );

        await service.initialize();

        expect(enabledValue, isTrue);
      },
    );

    test('initialize swallows setup failures', () async {
      final service = AnalyticsService(
        enabled: true,
        setCollectionEnabled: (_) async => throw StateError('set-failed'),
        logEvent: ({required name, parameters}) async {},
        logScreenView: ({screenName, screenClass}) async {},
        logCrashBreadcrumb: (_) {},
      );

      await service.initialize();
    });

    test('logEvent no-ops when analytics is disabled', () async {
      var didLogEvent = false;
      var didLogBreadcrumb = false;
      final service = AnalyticsService(
        enabled: false,
        setCollectionEnabled: (_) async {},
        logEvent: ({required name, parameters}) async {
          didLogEvent = true;
        },
        logScreenView: ({screenName, screenClass}) async {},
        logCrashBreadcrumb: (_) {
          didLogBreadcrumb = true;
        },
      );

      await service.logEvent('ignored_event', parameters: {'value': 1});

      expect(didLogEvent, isFalse);
      expect(didLogBreadcrumb, isFalse);
    });

    test('logEvent normalizes payload and writes breadcrumb', () async {
      String? loggedName;
      Map<String, Object>? loggedParams;
      String? breadcrumb;
      final service = AnalyticsService(
        enabled: true,
        setCollectionEnabled: (_) async {},
        logEvent: ({required name, parameters}) async {
          loggedName = name;
          loggedParams = parameters;
        },
        logScreenView: ({screenName, screenClass}) async {},
        logCrashBreadcrumb: (message) {
          breadcrumb = message;
        },
      );

      await service.logEvent(
        'Score Submit Success!',
        parameters: {
          'Category Key': 'FLAG',
          'isAnonymous': true,
          'attemptCount': 4,
          'longText': List.filled(120, 'x').join(),
          'nullValue': null,
        },
      );

      expect(loggedName, equals('score_submit_success'));
      expect(loggedParams?['category_key'], equals('FLAG'));
      expect(loggedParams?['isanonymous'], equals(1));
      expect(loggedParams?['attemptcount'], equals(4));
      expect(
        (loggedParams?['longtext'] as String).length,
        lessThanOrEqualTo(100),
      );
      expect(loggedParams?.containsKey('nullvalue'), isFalse);
      expect(breadcrumb, equals('analytics:score_submit_success'));
    });

    test('logScreenView normalizes payload and writes breadcrumb', () async {
      String? loggedScreenName;
      String? loggedScreenClass;
      String? breadcrumb;
      final service = AnalyticsService(
        enabled: true,
        setCollectionEnabled: (_) async {},
        logEvent: ({required name, parameters}) async {},
        logScreenView: ({screenName, screenClass}) async {
          loggedScreenName = screenName;
          loggedScreenClass = screenClass;
        },
        logCrashBreadcrumb: (message) {
          breadcrumb = message;
        },
      );

      await service.logScreenView(
        screenName: '  /Result Screen  ',
        screenClass: 'MaterialPageRoute<Result>',
      );

      expect(loggedScreenName, equals('result_screen'));
      expect(loggedScreenClass, equals('materialpageroute_result'));
      expect(breadcrumb, equals('screen_view:result_screen'));
    });

    test('log methods swallow downstream failures', () async {
      final service = AnalyticsService(
        enabled: true,
        setCollectionEnabled: (_) async {},
        logEvent: ({required name, parameters}) async {
          throw StateError('event-failed');
        },
        logScreenView: ({screenName, screenClass}) async {
          throw StateError('screen-failed');
        },
        logCrashBreadcrumb: (_) {},
      );

      await service.logEvent('bad_event');
      await service.logScreenView(screenName: 'screen');
    });
  });

  group('AnalyticsNavigationObserver', () {
    test(
      'tracks named route transitions and de-duplicates consecutive names',
      () async {
        final trackedScreens = <String>[];
        final service = AnalyticsService(
          enabled: true,
          setCollectionEnabled: (_) async {},
          logEvent: ({required name, parameters}) async {},
          logScreenView: ({screenName, screenClass}) async {
            trackedScreens.add(screenName ?? '');
          },
          logCrashBreadcrumb: (_) {},
        );
        final observer = AnalyticsNavigationObserver(analyticsService: service);

        final homeRoute = MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/home'),
          builder: (_) => const SizedBox.shrink(),
        );
        final duplicateHomeRoute = MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/home'),
          builder: (_) => const SizedBox.shrink(),
        );
        final quizRoute = MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/quiz'),
          builder: (_) => const SizedBox.shrink(),
        );

        observer.didPush(homeRoute, null);
        observer.didPush(duplicateHomeRoute, homeRoute);
        observer.didReplace(newRoute: quizRoute, oldRoute: homeRoute);
        observer.didPop(quizRoute, homeRoute);

        await Future<void>.delayed(Duration.zero);

        expect(trackedScreens, equals(['home', 'quiz', 'home']));
      },
    );
  });
}
