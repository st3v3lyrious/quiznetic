import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/models/flag_question.dart';
import 'package:quiznetic_flutter/screens/leaderboard_screen.dart';
import 'package:quiznetic_flutter/screens/quiz_screen.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';
import 'package:quiznetic_flutter/services/accessibility_preferences.dart';
import 'package:quiznetic_flutter/services/hint_monetization_service.dart';
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
    HintMonetizationGateway? hintMonetizationService,
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
              hintMonetizationService: hintMonetizationService,
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

  testWidgets('hint action removes two wrong options when granted', (
    tester,
  ) async {
    final hintService = _FakeHintMonetizationService(
      rewardedHintsRemainingValue: 1,
      canOfferPaidHintValue: false,
      queuedResults: Queue<HintRequestResult>.from([
        const HintRequestResult(
          status: HintRequestStatus.granted,
          source: HintGrantSource.rewardedAd,
          message: 'granted',
          rewardedHintsRemaining: 0,
        ),
      ]),
    );

    await pumpQuiz(tester, hintMonetizationService: hintService);

    expect(find.byKey(QuizScreen.hintActionButtonKey), findsOneWidget);
    expect(find.text('Watch Ad for Hint'), findsOneWidget);

    await tester.tap(find.byKey(QuizScreen.hintActionButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('France'), findsOneWidget);
    expect(find.text('Germany'), findsOneWidget);
    expect(find.text('Italy'), findsNothing);
    expect(find.text('Spain'), findsNothing);
  });

  testWidgets(
    'hint action label switches to paid price when free quota is exhausted',
    (tester) async {
      final hintService = _FakeHintMonetizationService(
        rewardedHintsRemainingValue: 0,
        canOfferPaidHintValue: true,
        paidHintPriceUsdCentsValue: 50,
        queuedResults: Queue<HintRequestResult>(),
      );

      await pumpQuiz(tester, hintMonetizationService: hintService);

      expect(find.byKey(QuizScreen.hintActionButtonKey), findsOneWidget);
      expect(find.text('Buy Hint (\$0.50)'), findsOneWidget);
    },
  );

  testWidgets('disables rewarded hint CTA when ad readiness is unavailable', (
    tester,
  ) async {
    final hintService = _FakeHintMonetizationService(
      rewardedHintsRemainingValue: 1,
      canOfferPaidHintValue: false,
      rewardedHintReadyValue: false,
      queuedResults: Queue<HintRequestResult>(),
    );

    await pumpQuiz(tester, hintMonetizationService: hintService);

    final hintButton = tester.widget<ElevatedButton>(
      find.byKey(QuizScreen.hintActionButtonKey),
    );
    expect(find.text('Hint Ads Unavailable'), findsOneWidget);
    expect(
      find.text('Free hints left: 1. Ad hints are temporarily unavailable.'),
      findsOneWidget,
    );
    expect(hintButton.onPressed, isNull);
  });

  testWidgets('uses forced rewarded hint refresh on initial quiz load', (
    tester,
  ) async {
    final hintService = _FakeHintMonetizationService(
      rewardedHintsRemainingValue: 1,
      canOfferPaidHintValue: false,
      rewardedHintReadyValue: true,
      refreshedReadyStates: Queue<bool>.from([false]),
      queuedResults: Queue<HintRequestResult>(),
    );

    await pumpQuiz(tester, hintMonetizationService: hintService);

    final hintButton = tester.widget<ElevatedButton>(
      find.byKey(QuizScreen.hintActionButtonKey),
    );
    expect(find.text('Hint Ads Unavailable'), findsOneWidget);
    expect(hintButton.onPressed, isNull);
    expect(hintService.refreshRewardedHintReadyCalls, 1);
    expect(hintService.isRewardedHintReadyCalls, 0);
  });

  testWidgets('retries rewarded hint availability on next question', (
    tester,
  ) async {
    final hintService = _FakeHintMonetizationService(
      rewardedHintsRemainingValue: 1,
      canOfferPaidHintValue: false,
      rewardedHintReadyValue: false,
      refreshedReadyStates: Queue<bool>.from([false, true]),
      queuedResults: Queue<HintRequestResult>(),
    );

    await pumpQuiz(
      tester,
      injectedQuestions: [question, question],
      flagsPerSession: 2,
      hintMonetizationService: hintService,
    );

    var hintButton = tester.widget<ElevatedButton>(
      find.byKey(QuizScreen.hintActionButtonKey),
    );
    expect(hintButton.onPressed, isNull);

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(QuizScreen.nextActionButtonKey));
    await tester.pumpAndSettle();

    hintButton = tester.widget<ElevatedButton>(
      find.byKey(QuizScreen.hintActionButtonKey),
    );
    expect(find.text('Watch Ad for Hint'), findsOneWidget);
    expect(hintButton.onPressed, isNotNull);
    expect(hintService.refreshRewardedHintReadyCalls, greaterThanOrEqualTo(1));
  });

  testWidgets(
    'keeps rewarded hint CTA stable while next-question refresh is in flight',
    (tester) async {
      final pendingRefresh = Completer<bool>();
      final hintService = _FakeHintMonetizationService(
        rewardedHintsRemainingValue: 1,
        canOfferPaidHintValue: false,
        rewardedHintReadyValue: true,
        refreshedReadyStates: Queue<bool>.from([true]),
        pendingRefreshReadyCompleter: pendingRefresh,
        queuedResults: Queue<HintRequestResult>(),
      );

      await pumpQuiz(
        tester,
        injectedQuestions: [question, question],
        flagsPerSession: 2,
        hintMonetizationService: hintService,
      );

      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(QuizScreen.nextActionButtonKey));
      await tester.pump();

      final hintButton = tester.widget<ElevatedButton>(
        find.byKey(QuizScreen.hintActionButtonKey),
      );
      expect(find.text('Watch Ad for Hint'), findsOneWidget);
      expect(hintButton.onPressed, isNotNull);

      pendingRefresh.complete(true);
      await tester.pumpAndSettle();

      final enabledHintButton = tester.widget<ElevatedButton>(
        find.byKey(QuizScreen.hintActionButtonKey),
      );
      expect(find.text('Watch Ad for Hint'), findsOneWidget);
      expect(enabledHintButton.onPressed, isNotNull);
    },
  );

  testWidgets('moving to next question invalidates stale hint request UI', (
    tester,
  ) async {
    final pendingResult = Completer<HintRequestResult>();
    final hintService = _FakeHintMonetizationService(
      rewardedHintsRemainingValue: 1,
      canOfferPaidHintValue: false,
      queuedResults: Queue<HintRequestResult>(),
      pendingRequestCompleter: pendingResult,
    );

    await pumpQuiz(
      tester,
      injectedQuestions: [question, question],
      flagsPerSession: 2,
      hintMonetizationService: hintService,
    );

    await tester.tap(find.byKey(QuizScreen.hintActionButtonKey));
    await tester.pump();
    expect(find.text('Processing hint...'), findsOneWidget);

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(QuizScreen.nextActionButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Flag Quiz (2/2)'), findsOneWidget);
    expect(find.text('Processing hint...'), findsNothing);

    pendingResult.complete(
      const HintRequestResult(
        status: HintRequestStatus.failed,
        message: 'stale hint failure',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('stale hint failure'), findsNothing);
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

class _FakeHintMonetizationService implements HintMonetizationGateway {
  _FakeHintMonetizationService({
    required this.rewardedHintsRemainingValue,
    required this.canOfferPaidHintValue,
    required this.queuedResults,
    this.paidHintPriceUsdCentsValue = 50,
    this.rewardedHintReadyValue = true,
    Queue<bool>? refreshedReadyStates,
    this.pendingRequestCompleter,
    this.pendingRefreshReadyCompleter,
  }) : refreshedReadyStates = refreshedReadyStates ?? Queue<bool>();

  int rewardedHintsRemainingValue;
  final bool canOfferPaidHintValue;
  final int paidHintPriceUsdCentsValue;
  final Queue<HintRequestResult> queuedResults;
  bool rewardedHintReadyValue;
  final Queue<bool> refreshedReadyStates;
  final Completer<HintRequestResult>? pendingRequestCompleter;
  final Completer<bool>? pendingRefreshReadyCompleter;
  int resetSessionCalls = 0;
  int isRewardedHintReadyCalls = 0;
  int refreshRewardedHintReadyCalls = 0;

  @override
  bool get isEnabled => true;

  @override
  bool get hasRewardedHintsRemaining => rewardedHintsRemainingValue > 0;

  @override
  bool get canOfferPaidHint => canOfferPaidHintValue;

  @override
  int get rewardedHintsRemaining => rewardedHintsRemainingValue;

  @override
  int get paidHintPriceUsdCents => paidHintPriceUsdCentsValue;

  @override
  void resetSession() {
    resetSessionCalls++;
  }

  @override
  Future<bool> isRewardedHintReady() async {
    isRewardedHintReadyCalls++;
    return rewardedHintReadyValue;
  }

  @override
  Future<bool> refreshRewardedHintReady() async {
    refreshRewardedHintReadyCalls++;
    if (refreshedReadyStates.isNotEmpty) {
      rewardedHintReadyValue = refreshedReadyStates.removeFirst();
      return rewardedHintReadyValue;
    }
    if (pendingRefreshReadyCompleter != null) {
      rewardedHintReadyValue = await pendingRefreshReadyCompleter!.future;
      return rewardedHintReadyValue;
    }
    return rewardedHintReadyValue;
  }

  @override
  Future<HintRequestResult> requestHint() async {
    if (pendingRequestCompleter != null) {
      return pendingRequestCompleter!.future;
    }
    if (queuedResults.isNotEmpty) {
      return queuedResults.removeFirst();
    }
    return const HintRequestResult(
      status: HintRequestStatus.failed,
      message: 'No queued hint result',
    );
  }
}
