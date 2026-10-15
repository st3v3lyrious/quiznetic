import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/navigation/app_router.dart';
import 'package:quiznetic_flutter/screens/difficulty_screen.dart';
import 'package:quiznetic_flutter/screens/leaderboard_screen.dart';
import 'package:quiznetic_flutter/screens/legal_document_screen.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';

void main() {
  test(
    'restores validated category, leaderboard filters and legal documents',
    () {
      final difficulty = AppLocation.resolve(
        const RouteSettings(name: '/difficulty?category=capital'),
      );
      expect(
        (difficulty.arguments as DifficultyScreenArgs).categoryKey,
        'capital',
      );
      expect(difficulty.needsRecovery, false);
      final board = AppLocation.resolve(
        const RouteSettings(
          name: '/leaderboard?category=capital&difficulty=expert',
        ),
      );
      expect((board.arguments as LeaderboardScreenArgs).difficulty, 'expert');
      final legal = AppLocation.resolve(
        const RouteSettings(name: '/legal/document?document=privacy'),
      );
      expect(legal.arguments, LegalDocumentScreen.privacyArgs);
    },
  );

  test('normalizes invalid filters and never restores scores from a URL', () {
    final board = AppLocation.resolve(
      const RouteSettings(
        name: '/leaderboard?category=unknown&difficulty=impossible',
      ),
    );
    expect((board.arguments as LeaderboardScreenArgs).categoryKey, 'flag');
    expect((board.arguments as LeaderboardScreenArgs).difficulty, 'easy');
    for (final path in [
      '/quiz',
      '/result?score=15&total=15',
      '/difficulty',
      '/difficulty?category=unknown',
      '/legal/document',
      '/missing',
    ]) {
      expect(
        AppLocation.resolve(RouteSettings(name: path)).needsRecovery,
        true,
        reason: path,
      );
    }
    final result = AppLocation.resolve(
      RouteSettings(
        name: '/result',
        arguments: ResultScreenArgs(
          categoryKey: 'flag',
          score: 12,
          total: 15,
          difficulty: 'easy',
        ),
      ),
    );
    expect(result.needsRecovery, false);
    expect(result.uri.toString(), '/result');
  });

  test('login return destinations must be internal known routes', () {
    for (final next in [
      'https://example.com/home',
      '//example.com/home',
      '/missing',
      '/login',
      '/entry',
    ]) {
      expect(
        AppLocation.resolve(
          RouteSettings(name: '/login', arguments: next),
        ).arguments,
        isNull,
      );
    }
    final location = AppLocation.resolve(
      const RouteSettings(
        name: '/login',
        arguments: '/leaderboard?category=capital',
      ),
    );
    expect(
      location.uri.queryParameters['next'],
      '/leaderboard?category=capital',
    );
    expect(
      AppLocation.resolve(
        RouteSettings(name: location.uri.toString()),
      ).arguments,
      '/leaderboard?category=capital',
    );
  });

  testWidgets('cold deep link bypasses splash and supports back and forward', (
    tester,
  ) async {
    final router = AppRouter(
      routes: {
        for (final path in ['/splash', '/home', '/leaderboard', '/settings'])
          path: (context) => Scaffold(
            body: Column(
              children: [
                Text('page:$path'),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  child: const Text('Open settings'),
                ),
              ],
            ),
          ),
      },
    );
    final provider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(uri: Uri.parse('/leaderboard')),
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerDelegate: router,
        routeInformationParser: const AppRouteParser(),
        routeInformationProvider: provider,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('page:/leaderboard'), findsOneWidget);
    expect(find.text('page:/splash'), findsNothing);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(router.currentConfiguration.path, '/settings');
    await router.setNewRoutePath(Uri.parse('/leaderboard'));
    await tester.pumpAndSettle();
    expect(find.text('page:/leaderboard'), findsOneWidget);
    await router.setNewRoutePath(Uri.parse('/settings'));
    await tester.pumpAndSettle();
    expect(find.text('page:/settings'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    provider.dispose();
  });

  testWidgets('popup routes remain open while URL updates are reported', (
    tester,
  ) async {
    final router = AppRouter(
      routes: {
        '/home': (context) => Scaffold(
          body: DropdownButton<String>(
            value: 'flag',
            items: const [
              DropdownMenuItem(value: 'flag', child: Text('Flags')),
              DropdownMenuItem(value: 'capital', child: Text('Capitals')),
            ],
            onChanged: (_) {},
          ),
        ),
      },
    );
    final provider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(uri: Uri.parse('/home')),
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerDelegate: router,
        routeInformationParser: const AppRouteParser(),
        routeInformationProvider: provider,
      ),
    );
    await tester.pumpAndSettle();
    final notifications = <Uri>[];
    router.addListener(() => notifications.add(router.currentConfiguration));
    await tester.tap(find.text('Flags'));
    await tester.pumpAndSettle();
    expect(find.text('Capitals').hitTestable(), findsOneWidget);
    expect(notifications, isEmpty);
    expect(router.currentConfiguration.path, '/home');
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    provider.dispose();
  });

  testWidgets(
    'session refresh shows recovery without invoking result builder',
    (tester) async {
      var resultBuilds = 0;
      final router = AppRouter(
        routes: {
          '/home': (_) => const Scaffold(body: Text('home')),
          '/result': (_) {
            resultBuilds++;
            return const Text('result');
          },
        },
      );
      final provider = PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(
          uri: Uri.parse('/result?score=15'),
        ),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: router,
          routeInformationParser: const AppRouteParser(),
          routeInformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('This session is no longer available'), findsOneWidget);
      expect(resultBuilds, 0);
      await tester.tap(find.text('Choose a Quiz'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      provider.dispose();
    },
  );
}
