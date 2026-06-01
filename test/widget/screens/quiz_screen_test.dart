import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/models/flag_question.dart';
import 'package:quiznetic_flutter/screens/leaderboard_screen.dart';
import 'package:quiznetic_flutter/screens/quiz_screen.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';
import 'package:quiznetic_flutter/services/accessibility_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final question = FlagQuestion(
    imagePath: 'assets/flags/France.png',
    correctAnswer: 'France',
    options: ['France', 'Italy', 'Spain', 'Germany'],
    visualDescription:
        'Three equal vertical bands with no emblem or central symbol.',
  );

  final capitalQuestion = FlagQuestion(
    imagePath: 'assets/flags/France.png',
    correctAnswer: 'Paris',
    options: ['Paris', 'Rome', 'Madrid', 'Berlin'],
  );

  Future<void> pumpQuiz(
    WidgetTester tester, {
    String categoryKey = 'flag',
    FlagQuestion? injectedQuestion,
    List<FlagQuestion>? injectedQuestions,
    int? flagsPerSession,
    bool showFlagDescriptions = false,
    Size physicalSize = const Size(1200, 2200),
  }) async {
    final questions = injectedQuestions ?? [injectedQuestion ?? question];
    final sessionQuestionCount = flagsPerSession ?? questions.length;
    SharedPreferences.setMockInitialValues({
      AccessibilityPreferences.showFlagDescriptionsKey: showFlagDescriptions,
    });
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = physicalSize;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        onGenerateInitialRoutes: (initialRoute) => [
          MaterialPageRoute(
            settings: RouteSettings(
              name: QuizScreen.routeName,
              arguments: QuizScreenArgs(
                categoryKey: categoryKey,
                flagsPerSession: sessionQuestionCount,
                difficulty: 'easy',
              ),
            ),
            builder: (_) => QuizScreen(
              flagsLoader: () async => List<FlagQuestion>.from(questions),
              quizPreparer: (subset) => subset,
            ),
          ),
        ],
        routes: {
          ResultScreen.routeName: (_) => const _ResultArgsProbe(),
          LeaderboardScreen.routeName: (_) => const _LeaderboardArgsProbe(),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders quiz progress and answer options', (tester) async {
    await pumpQuiz(tester);

    expect(find.text('Flag Quiz (1/1)'), findsOneWidget);
    expect(
      find.text('Which country does this flag belong to?'),
      findsOneWidget,
    );
    expect(find.text('France'), findsOneWidget);
    expect(find.text('Italy'), findsOneWidget);
    expect(find.text('Spain'), findsOneWidget);
    expect(find.text('Germany'), findsOneWidget);
    expect(find.byKey(const Key('quiz-progress-semantics')), findsOneWidget);
    expect(
      find.bySemanticsLabel(BrandConfig.quizQuestionImageSemanticLabel),
      findsOneWidget,
    );
  });

  testWidgets(
    'renders capital quiz title and prompt when category is capital',
    (tester) async {
      await pumpQuiz(
        tester,
        categoryKey: 'capital',
        injectedQuestion: capitalQuestion,
      );

      expect(find.text('Capital Quiz (1/1)'), findsOneWidget);
      expect(find.text('What is the capital of this country?'), findsOneWidget);
      expect(find.text('Paris'), findsOneWidget);
    },
  );

  testWidgets('reveals See Results after selecting an answer', (tester) async {
    await pumpQuiz(tester);

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-answer-feedback-card')), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('France is the right answer.'), findsOneWidget);
    expect(find.text('See Results'), findsOneWidget);
  });

  testWidgets('keeps next action visible on shorter phone heights', (
    tester,
  ) async {
    await pumpQuiz(
      tester,
      injectedQuestions: [question, question],
      flagsPerSession: 2,
      physicalSize: const Size(800, 1200),
    );

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();

    final nextFinder = find.byKey(QuizScreen.nextActionButtonKey);
    final scrollableState = tester.state<ScrollableState>(
      find.byType(Scrollable),
    );
    expect(nextFinder, findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    final nextTopLeft = tester.getTopLeft(nextFinder);
    final nextBottomRight = tester.getBottomRight(nextFinder);
    expect(nextTopLeft.dy, lessThan(tester.view.physicalSize.height));
    expect(
      nextBottomRight.dy,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );

    await tester.tap(nextFinder);
    await tester.pumpAndSettle();

    expect(find.text('Flag Quiz (2/2)'), findsOneWidget);
    expect(
      find.text('Which country does this flag belong to?'),
      findsOneWidget,
    );
    expect(find.byKey(QuizScreen.nextActionButtonKey), findsNothing);
    expect(
      scrollableState.position.pixels,
      0,
      reason:
          'Advancing to the next question should reset the scroll position.',
    );
  });

  testWidgets('advancing to the next question resets scroll to the top', (
    tester,
  ) async {
    await pumpQuiz(
      tester,
      injectedQuestions: [question, question],
      flagsPerSession: 2,
      physicalSize: const Size(800, 1200),
    );

    final scrollableFinder = find.byType(Scrollable);
    final scrollableState = tester.state<ScrollableState>(scrollableFinder);

    await tester.drag(scrollableFinder, const Offset(0, -250));
    await tester.pumpAndSettle();

    expect(
      scrollableState.position.pixels,
      greaterThan(0),
      reason: 'The test should start from a non-zero scroll position.',
    );

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(QuizScreen.nextActionButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Flag Quiz (2/2)'), findsOneWidget);
    expect(scrollableState.position.pixels, 0);
  });

  testWidgets(
    'shows describe-flag affordance when accessibility setting is on',
    (tester) async {
      await pumpQuiz(tester, showFlagDescriptions: true);

      final buttonFinder = find.byKey(QuizScreen.describeFlagButtonKey);
      expect(buttonFinder, findsOneWidget);
      expect(find.byKey(QuizScreen.flagDescriptionCardKey), findsNothing);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(QuizScreen.flagDescriptionCardKey), findsOneWidget);
      expect(
        find.text(
          'Three equal vertical bands with no emblem or central symbol.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'hides describe-flag affordance when accessibility setting is off',
    (tester) async {
      await pumpQuiz(tester, showFlagDescriptions: false);

      expect(find.byKey(QuizScreen.describeFlagButtonKey), findsNothing);
    },
  );

  testWidgets(
    'describe-flag visibility persists across questions until user hides it',
    (tester) async {
      await pumpQuiz(
        tester,
        showFlagDescriptions: true,
        injectedQuestions: [question, question, question],
        flagsPerSession: 3,
      );

      // Enable description on Q1.
      await tester.tap(find.byKey(QuizScreen.describeFlagButtonKey));
      await tester.pumpAndSettle();
      expect(find.byKey(QuizScreen.flagDescriptionCardKey), findsOneWidget);

      // Advance to Q2 and verify description remains visible.
      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byKey(QuizScreen.flagDescriptionCardKey), findsOneWidget);

      // Hide on Q2.
      await tester.tap(find.byKey(QuizScreen.describeFlagButtonKey));
      await tester.pumpAndSettle();
      expect(find.byKey(QuizScreen.flagDescriptionCardKey), findsNothing);

      // Advance to Q3 and verify hidden state persists.
      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byKey(QuizScreen.flagDescriptionCardKey), findsNothing);
    },
  );

  testWidgets('navigates to results with expected arguments', (tester) async {
    await pumpQuiz(tester);

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('See Results'));
    await tester.pumpAndSettle();

    expect(find.text('result:flag:easy:1:1'), findsOneWidget);
  });

  testWidgets('routes to leaderboard with current quiz scope', (tester) async {
    await pumpQuiz(tester, categoryKey: 'capital');

    await tester.tap(find.byTooltip('Leaderboard'));
    await tester.pumpAndSettle();

    expect(find.text('leaderboard:capital:easy'), findsOneWidget);
  });
}

class _ResultArgsProbe extends StatelessWidget {
  const _ResultArgsProbe();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as ResultScreenArgs;
    return Scaffold(
      body: Text(
        'result:${args.categoryKey}:${args.difficulty}:${args.score}:${args.total}',
      ),
    );
  }
}

class _LeaderboardArgsProbe extends StatelessWidget {
  const _LeaderboardArgsProbe();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is LeaderboardScreenArgs) {
      return Scaffold(
        body: Text('leaderboard:${args.categoryKey}:${args.difficulty}'),
      );
    }
    return const Scaffold(body: Text('leaderboard:default'));
  }
}
