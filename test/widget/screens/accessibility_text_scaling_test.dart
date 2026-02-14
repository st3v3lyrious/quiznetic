import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/about_screen.dart';
import 'package:quiznetic_flutter/screens/difficulty_screen.dart';
import 'package:quiznetic_flutter/screens/entry_choice_screen.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/leaderboard_screen.dart';
import 'package:quiznetic_flutter/screens/quiz_screen.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';
import 'package:quiznetic_flutter/screens/settings_screen.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';
import 'package:quiznetic_flutter/services/leaderboard_service.dart';
import 'package:quiznetic_flutter/services/score_service.dart';
import 'package:quiznetic_flutter/models/flag_question.dart';

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
      _scaledMaterialApp(
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

  testWidgets('home remains usable with large text scaling', (tester) async {
    await tester.pumpWidget(
      _scaledApp(const HomeScreen(), textScaler: largeTextScale),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Quiz'), findsOneWidget);
    expect(find.text('Flag Quiz'), findsOneWidget);
    expect(find.text('Capital Quiz'), findsOneWidget);
  });

  testWidgets('quiz remains usable with large text scaling', (tester) async {
    final question = FlagQuestion(
      imagePath: 'assets/flags/France.png',
      correctAnswer: 'France',
      options: const ['France', 'Italy', 'Spain', 'Germany'],
    );

    await tester.pumpWidget(
      _scaledMaterialApp(
        initialRoute: QuizScreen.routeName,
        onGenerateRoute: (settings) {
          if (settings.name == QuizScreen.routeName) {
            return MaterialPageRoute(
              settings: RouteSettings(
                name: QuizScreen.routeName,
                arguments: QuizScreenArgs(
                  categoryKey: 'flag',
                  flagsPerSession: 1,
                  difficulty: 'easy',
                ),
              ),
              builder: (_) => QuizScreen(
                flagsLoader: () async => [question],
                quizPreparer: (_) => [question],
              ),
            );
          }
          if (settings.name == ResultScreen.routeName) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('result-route')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Which country does this flag belong to?'),
      findsOneWidget,
    );
    expect(find.text('France'), findsOneWidget);

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-answer-feedback-card')), findsOneWidget);
    expect(find.text('See Results'), findsOneWidget);
  });

  testWidgets('result remains readable with large text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _scaledMaterialApp(
        initialRoute: ResultScreen.routeName,
        onGenerateRoute: (settings) {
          if (settings.name == ResultScreen.routeName) {
            return MaterialPageRoute(
              settings: RouteSettings(
                name: ResultScreen.routeName,
                arguments: ResultScreenArgs(
                  categoryKey: 'flag',
                  score: 7,
                  total: 10,
                  difficulty: 'easy',
                ),
              ),
              builder: (_) => ResultScreen(
                saveScore:
                    ({
                      required categoryKey,
                      required difficulty,
                      required score,
                      required totalQuestions,
                    }) async => score,
                getHighScore: (categoryKey, difficulty) async => 6,
              ),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You scored 7 out of 10'), findsOneWidget);
    expect(find.text('Play Again'), findsOneWidget);
    expect(find.byKey(const Key('result-summary-semantics')), findsOneWidget);
  });

  testWidgets('leaderboard remains usable with large text scaling', (
    tester,
  ) async {
    final service = LeaderboardService(
      currentUserLoader: () => null,
      entriesLoader:
          ({required categoryKey, required difficulty, required limit}) async =>
              [
                LeaderboardEntry(
                  uid: 'u1',
                  score: 99,
                  updatedAt: DateTime.utc(2025, 1, 1),
                  isAnonymous: false,
                  displayName: 'Player One',
                ),
              ],
    );

    await tester.pumpWidget(
      _scaledApp(
        LeaderboardScreen(leaderboardService: service),
        textScaler: largeTextScale,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Global Leaderboard'), findsOneWidget);
    expect(find.text('Player One'), findsOneWidget);
    expect(find.byKey(const Key('leaderboard-scope-summary')), findsOneWidget);
  });

  testWidgets('profile remains usable with large text scaling', (tester) async {
    await tester.pumpWidget(
      _scaledApp(
        UserProfileScreen(
          scoreLoader: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 12,
            ),
          ],
        ),
        textScaler: largeTextScale,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('High Scores'), findsOneWidget);
    expect(find.text('Flag Quiz (Easy)'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });
}

Widget _scaledApp(Widget home, {required TextScaler textScaler}) {
  return _scaledMaterialApp(home: home, textScaler: textScaler);
}

Widget _scaledMaterialApp({
  Widget? home,
  TextScaler textScaler = const TextScaler.linear(1.8),
  String? initialRoute,
  RouteFactory? onGenerateRoute,
}) {
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
    initialRoute: initialRoute,
    onGenerateRoute: onGenerateRoute,
  );
}
