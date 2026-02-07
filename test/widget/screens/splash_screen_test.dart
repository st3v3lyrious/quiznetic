import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/entry_choice_screen.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/splash_screen.dart';

void main() {
  testWidgets('renders splash logo image', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          SplashScreen.routeName: (_) => const SplashScreen(
            startupDelay: Duration.zero,
            currentUserProvider: _nullUser,
          ),
          EntryChoiceScreen.routeName: (_) => const _EntryProbe(),
          HomeScreen.routeName: (_) => const _HomeProbe(),
        },
        initialRoute: SplashScreen.routeName,
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('routes to entry choice when no active user exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          SplashScreen.routeName: (_) => const SplashScreen(
            startupDelay: Duration.zero,
            currentUserProvider: _nullUser,
          ),
          EntryChoiceScreen.routeName: (_) => const _EntryProbe(),
          HomeScreen.routeName: (_) => const _HomeProbe(),
        },
        initialRoute: SplashScreen.routeName,
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('entry-screen'), findsOneWidget);
  });

  testWidgets('routes to home when an active user exists', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          SplashScreen.routeName: (_) => SplashScreen(
            startupDelay: Duration.zero,
            currentUserProvider: () => _FakeUser(uid: 'u1', isAnonymous: true),
          ),
          EntryChoiceScreen.routeName: (_) => const _EntryProbe(),
          HomeScreen.routeName: (_) => const _HomeProbe(),
        },
        initialRoute: SplashScreen.routeName,
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('home-screen'), findsOneWidget);
  });
}

User? _nullUser() => null;

class _EntryProbe extends StatelessWidget {
  const _EntryProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('entry-screen'));
  }
}

class _HomeProbe extends StatelessWidget {
  const _HomeProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home-screen'));
  }
}

class _FakeUser implements User {
  _FakeUser({required this.uid, required this.isAnonymous});

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
