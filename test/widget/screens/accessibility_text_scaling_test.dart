import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/about_screen.dart';
import 'package:quiznetic_flutter/screens/difficulty_screen.dart';
import 'package:quiznetic_flutter/screens/entry_choice_screen.dart';
import 'package:quiznetic_flutter/screens/settings_screen.dart';

void main() {
  const largeTextScale = TextScaler.linear(1.8);

  testWidgets('entry choice remains usable with large text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _scaledApp(const EntryChoiceScreen(), textScaler: largeTextScale),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Sign In / Create Account'), findsOneWidget);
  });

  testWidgets('settings remains usable with large text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _scaledApp(const SettingsScreen(), textScaler: largeTextScale),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-sign-out-button')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-about-link')),
      200,
    );
    expect(find.byKey(const Key('settings-about-link')), findsOneWidget);
  });

  testWidgets('about remains readable with large text scaling', (tester) async {
    await tester.pumpWidget(
      _scaledApp(const AboutScreen(), textScaler: largeTextScale),
    );
    await tester.pumpAndSettle();

    expect(find.text('QuizNetic'), findsOneWidget);
    expect(find.text('Train your world trivia reflexes.'), findsOneWidget);
  });

  testWidgets('difficulty actions remain present with large text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final data = MediaQuery.of(context);
          if (child == null) {
            return const SizedBox.shrink();
          }
          return MediaQuery(
            data: data.copyWith(textScaler: largeTextScale),
            child: child,
          );
        },
        initialRoute: DifficultyScreen.routeName,
        onGenerateRoute: (settings) {
          if (settings.name == DifficultyScreen.routeName) {
            return MaterialPageRoute(
              settings: RouteSettings(
                name: DifficultyScreen.routeName,
                arguments: DifficultyScreenArgs(categoryKey: 'flag'),
              ),
              builder: (_) => const DifficultyScreen(),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Easy (15 flags)'), findsOneWidget);
    expect(find.text('Intermediate (30 flags)'), findsOneWidget);
    expect(find.text('Expert (50 flags)'), findsOneWidget);
  });
}

Widget _scaledApp(Widget home, {required TextScaler textScaler}) {
  return MaterialApp(
    builder: (context, child) {
      final data = MediaQuery.of(context);
      if (child == null) {
        return const SizedBox.shrink();
      }
      return MediaQuery(
        data: data.copyWith(textScaler: textScaler),
        child: child,
      );
    },
    home: home,
  );
}
