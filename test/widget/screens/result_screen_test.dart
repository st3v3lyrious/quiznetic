import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/difficulty_screen.dart';
import 'package:quiznetic_flutter/screens/quiz_screen.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';

void main() {
  Future<void> pumpResult(
    WidgetTester tester, {
    required ResultScreenArgs args,
    required Future<void> Function({
      required String categoryKey,
      required String difficulty,
      required int score,
    })
    saveScore,
    required Future<int> Function(String categoryKey) getHighScore,
    required Future<void> Function(String categoryKey, int score) setHighScore,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateInitialRoutes: (initialRoute) => [
          MaterialPageRoute(
            settings: RouteSettings(
              name: ResultScreen.routeName,
              arguments: args,
            ),
            builder: (_) => ResultScreen(
              saveScore: saveScore,
              getHighScore: getHighScore,
              setHighScore: setHighScore,
            ),
          ),
        ],
        routes: {
          QuizScreen.routeName: (_) => const _QuizArgsProbe(),
          DifficultyScreen.routeName: (_) => const _DifficultyArgsProbe(),
          UserProfileScreen.routeName: (_) => const _ProfileProbe(),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows missing-data placeholder when route args are absent', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ResultScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Missing result data'), findsOneWidget);
  });

  testWidgets('renders score summary and high-score message', (tester) async {
    var saveScoreCalled = false;
    var setHighScoreCalled = false;
    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 7,
        total: 10,
        difficulty: 'easy',
      ),
      saveScore:
          ({required categoryKey, required difficulty, required score}) async {
            saveScoreCalled = true;
          },
      getHighScore: (categoryKey) async => 5,
      setHighScore: (categoryKey, score) async {
        setHighScoreCalled = true;
      },
    );

    expect(find.text('You scored 7 out of 10'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.textContaining('New High Score: 7!'), findsOneWidget);
    expect(saveScoreCalled, isTrue);
    expect(setHighScoreCalled, isTrue);
  });

  testWidgets('play again button routes to quiz with expected args', (
    tester,
  ) async {
    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 4,
        total: 15,
        difficulty: 'intermediate',
      ),
      saveScore:
          ({
            required categoryKey,
            required difficulty,
            required score,
          }) async {},
      getHighScore: (categoryKey) async => 10,
      setHighScore: (categoryKey, score) async {},
    );

    await tester.tap(find.text('Play Again'));
    await tester.pumpAndSettle();

    expect(find.text('quiz:flag:15:intermediate'), findsOneWidget);
  });

  testWidgets('change difficulty button routes with category args', (
    tester,
  ) async {
    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 4,
        total: 15,
        difficulty: 'intermediate',
      ),
      saveScore:
          ({
            required categoryKey,
            required difficulty,
            required score,
          }) async {},
      getHighScore: (categoryKey) async => 10,
      setHighScore: (categoryKey, score) async {},
    );

    await tester.tap(find.text('Change Difficulty'));
    await tester.pumpAndSettle();

    expect(find.text('difficulty:flag'), findsOneWidget);
  });
}

class _QuizArgsProbe extends StatelessWidget {
  const _QuizArgsProbe();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as QuizScreenArgs;
    return Scaffold(
      body: Text(
        'quiz:${args.categoryKey}:${args.flagsPerSession}:${args.difficulty}',
      ),
    );
  }
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
