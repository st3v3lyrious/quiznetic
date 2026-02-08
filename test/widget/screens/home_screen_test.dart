import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/difficulty_screen.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/leaderboard_screen.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';

void main() {
  testWidgets('renders category selection and routes to difficulty with args', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == DifficultyScreen.routeName) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const _DifficultyArgsProbe(),
            );
          }
          return null;
        },
      ),
    );

    expect(find.text('Choose Your Quiz'), findsOneWidget);
    expect(find.text('Flag Quiz'), findsOneWidget);
    expect(find.text('Capital Quiz'), findsOneWidget);

    await tester.tap(find.text('Flag Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('difficulty:flag'), findsOneWidget);
  });

  testWidgets('routes capital category to difficulty with args', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == DifficultyScreen.routeName) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const _DifficultyArgsProbe(),
            );
          }
          return null;
        },
      ),
    );

    await tester.tap(find.text('Capital Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('difficulty:capital'), findsOneWidget);
  });

  testWidgets('routes to profile when profile action is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        routes: {UserProfileScreen.routeName: (_) => const _ProfileProbe()},
      ),
    );

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    expect(find.text('profile-screen'), findsOneWidget);
  });

  testWidgets('routes to leaderboard when leaderboard action is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        routes: {LeaderboardScreen.routeName: (_) => const _LeaderboardProbe()},
      ),
    );

    await tester.tap(find.byTooltip('Leaderboard'));
    await tester.pumpAndSettle();

    expect(find.text('leaderboard-screen'), findsOneWidget);
  });

  testWidgets(
    'shows guest conversion CTA for anonymous users and routes to upgrade',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authService: AuthService(
              currentUserProvider: () => _FakeUser(isAnonymous: true),
            ),
          ),
          routes: {
            UpgradeAccountScreen.routeName: (_) => const _UpgradeProbe(),
          },
        ),
      );

      expect(
        find.byKey(const Key('guest-home-conversion-cta')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('guest-home-conversion-cta-action')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('guest-home-conversion-cta-action')),
      );
      await tester.pumpAndSettle();

      expect(find.text('upgrade-screen'), findsOneWidget);
    },
  );

  testWidgets('hides guest conversion CTA for non-anonymous users', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: AuthService(
            currentUserProvider: () => _FakeUser(isAnonymous: false),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('guest-home-conversion-cta')), findsNothing);
  });
}

class _DifficultyArgsProbe extends StatelessWidget {
  const _DifficultyArgsProbe();

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as DifficultyScreenArgs;
    return Scaffold(body: Text('difficulty:${args.categoryKey}'));
  }
}

class _ProfileProbe extends StatelessWidget {
  const _ProfileProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('profile-screen'));
  }
}

class _UpgradeProbe extends StatelessWidget {
  const _UpgradeProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('upgrade-screen'));
  }
}

class _LeaderboardProbe extends StatelessWidget {
  const _LeaderboardProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('leaderboard-screen'));
  }
}

class _FakeUser implements User {
  _FakeUser({required this.isAnonymous});

  @override
  final bool isAnonymous;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
