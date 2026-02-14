import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/entry_choice_screen.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/legal_document_screen.dart';
import 'package:quiznetic_flutter/screens/login_screen.dart';
import 'package:quiznetic_flutter/widgets/legal_consent_notice.dart';

void main() {
  test('exposes the expected route name', () {
    expect(EntryChoiceScreen.routeName, equals('/entry'));
  });

  testWidgets('shows both first-entry choices', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EntryChoiceScreen()));

    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Sign In / Create Account'), findsOneWidget);
    expect(find.byKey(LegalConsentNotice.copyKey), findsOneWidget);
    expect(find.byKey(LegalConsentNotice.termsLinkKey), findsOneWidget);
    expect(find.byKey(LegalConsentNotice.privacyLinkKey), findsOneWidget);
  });

  testWidgets('sign in choice routes to provider login screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          EntryChoiceScreen.routeName: (_) => const EntryChoiceScreen(),
          LoginScreen.routeName: (_) => const _LoginProbe(),
        },
        initialRoute: EntryChoiceScreen.routeName,
      ),
    );

    await tester.tap(find.text('Sign In / Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('login-screen'), findsOneWidget);
  });

  testWidgets('guest choice runs injected action and can route to home', (
    tester,
  ) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          EntryChoiceScreen.routeName: (_) => EntryChoiceScreen(
            continueAsGuest: (context) async {
              called = true;
              Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
            },
          ),
          HomeScreen.routeName: (_) => const _HomeProbe(),
        },
        initialRoute: EntryChoiceScreen.routeName,
      ),
    );

    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(find.text('home-screen'), findsOneWidget);
  });

  testWidgets('terms link opens the terms document screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          EntryChoiceScreen.routeName: (_) => const EntryChoiceScreen(),
          LegalDocumentScreen.routeName: (_) => const LegalDocumentScreen(),
        },
        initialRoute: EntryChoiceScreen.routeName,
      ),
    );

    await tester.tap(find.byKey(LegalConsentNotice.termsLinkKey));
    await tester.pumpAndSettle();

    expect(find.text(LegalDocumentScreen.termsTitle), findsOneWidget);
  });

  testWidgets('privacy link opens the privacy policy screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          EntryChoiceScreen.routeName: (_) => const EntryChoiceScreen(),
          LegalDocumentScreen.routeName: (_) => const LegalDocumentScreen(),
        },
        initialRoute: EntryChoiceScreen.routeName,
      ),
    );

    await tester.tap(find.byKey(LegalConsentNotice.privacyLinkKey));
    await tester.pumpAndSettle();

    expect(find.text(LegalDocumentScreen.privacyTitle), findsOneWidget);
  });
}

class _LoginProbe extends StatelessWidget {
  const _LoginProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('login-screen'));
  }
}

class _HomeProbe extends StatelessWidget {
  const _HomeProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home-screen'));
  }
}
