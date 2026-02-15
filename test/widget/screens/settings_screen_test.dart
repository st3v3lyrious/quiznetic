import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/about_screen.dart';
import 'package:quiznetic_flutter/screens/entry_choice_screen.dart';
import 'package:quiznetic_flutter/screens/legal_document_screen.dart';
import 'package:quiznetic_flutter/screens/settings_screen.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';

void main() {
  test('exposes the expected route name', () {
    expect(SettingsScreen.routeName, equals('/settings'));
  });

  testWidgets('renders core settings sections and controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          authService: AuthService(
            currentUserProvider: () =>
                _FakeUser(uid: 'settings_guest', isAnonymous: true),
          ),
        ),
      ),
    );

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Gameplay'), findsOneWidget);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.byKey(const Key('settings-sign-out-button')), findsOneWidget);
    expect(find.byKey(const Key('settings-sound-toggle')), findsOneWidget);
    expect(find.byKey(const Key('settings-haptics-toggle')), findsOneWidget);
    expect(find.byKey(const Key('settings-terms-link')), findsOneWidget);
    expect(find.byKey(const Key('settings-privacy-link')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-about-link')),
      200,
    );
    expect(find.byKey(const Key('settings-about-link')), findsOneWidget);
  });

  testWidgets('terms link opens the terms document screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const SettingsScreen(),
          LegalDocumentScreen.routeName: (_) => const LegalDocumentScreen(),
        },
      ),
    );

    await tester.tap(find.byKey(const Key('settings-terms-link')));
    await tester.pumpAndSettle();

    expect(find.text(LegalDocumentScreen.termsTitle), findsOneWidget);
  });

  testWidgets('privacy link opens the privacy document screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const SettingsScreen(),
          LegalDocumentScreen.routeName: (_) => const LegalDocumentScreen(),
        },
      ),
    );

    final privacyFinder = find.byKey(const Key('settings-privacy-link'));
    await tester.scrollUntilVisible(privacyFinder, 150);
    await tester.tap(privacyFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(LegalDocumentScreen.privacyTitle), findsOneWidget);
  });

  testWidgets('about link routes to about screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const SettingsScreen(),
          AboutScreen.routeName: (_) => const _AboutProbe(),
        },
      ),
    );

    final aboutFinder = find.byKey(const Key('settings-about-link'));
    await tester.scrollUntilVisible(aboutFinder, 200);
    await tester.tap(aboutFinder);
    await tester.pumpAndSettle();

    expect(find.text('about-screen'), findsOneWidget);
  });

  testWidgets('sign out action signs out and routes to entry choice', (
    tester,
  ) async {
    var signOutCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => SettingsScreen(
            authService: AuthService(
              currentUserProvider: () => _FakeUser(
                uid: 'settings_account',
                isAnonymous: false,
                email: 'player@quiznetic.app',
              ),
              signOutProvider: () async {
                signOutCalled = true;
              },
            ),
          ),
          EntryChoiceScreen.routeName: (_) => const _EntryProbe(),
        },
      ),
    );

    await tester.tap(find.byKey(const Key('settings-sign-out-button')));
    await tester.pumpAndSettle();

    expect(signOutCalled, isTrue);
    expect(find.text('entry-choice-screen'), findsOneWidget);
  });

  testWidgets(
    'sign out failure shows generic snackbar message without raw error details',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            authService: AuthService(
              currentUserProvider: () => _FakeUser(
                uid: 'settings_account',
                isAnonymous: false,
                email: 'player@quiznetic.app',
              ),
              signOutProvider: () async {
                throw Exception('sign-out-internal-detail');
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('settings-sign-out-button')));
      await tester.pump();

      expect(find.text('Sign out failed. Please try again.'), findsOneWidget);
      expect(find.textContaining('sign-out-internal-detail'), findsNothing);
    },
  );
}

class _EntryProbe extends StatelessWidget {
  const _EntryProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('entry-choice-screen'));
  }
}

class _AboutProbe extends StatelessWidget {
  const _AboutProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('about-screen'));
  }
}

class _FakeUser implements User {
  _FakeUser({required this.uid, required this.isAnonymous, this.email});

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  final String? email;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
