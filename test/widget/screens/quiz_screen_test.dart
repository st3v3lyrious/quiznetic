import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/models/flag_question.dart';
import 'package:quiznetic_flutter/screens/quiz_screen.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';

void main() {
  final question = FlagQuestion(
    imagePath: 'assets/flags/France.png',
    correctAnswer: 'France',
    options: ['France', 'Italy', 'Spain', 'Germany'],
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
  }) async {
    final q = injectedQuestion ?? question;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2200);
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
                flagsPerSession: 1,
                difficulty: 'easy',
              ),
            ),
            builder: (_) => QuizScreen(
              flagsLoader: () async => [q],
              quizPreparer: (_) => [q],
            ),
          ),
        ],
        routes: {ResultScreen.routeName: (_) => const _ResultArgsProbe()},
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

    expect(find.text('See Results'), findsOneWidget);
  });

  testWidgets('navigates to results with expected arguments', (tester) async {
    await pumpQuiz(tester);

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('See Results'));
    await tester.pumpAndSettle();

    expect(find.text('result:flag:easy:1:1'), findsOneWidget);
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
