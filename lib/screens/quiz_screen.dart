/*
 DOC: Screen
 Title: Quiz
 Purpose: Presents questions, records answers, and handles scoring.
*/
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/services/accessibility_preferences.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';
import 'package:quiznetic_flutter/services/hint_monetization_service.dart';
import '../data/capital_loader.dart';
import '../data/flag_loader.dart';
import '../models/flag_question.dart';
import 'leaderboard_screen.dart';
import 'result_screen.dart';

class QuizScreenArgs {
  final String categoryKey;
  final int flagsPerSession;
  final String difficulty;
  QuizScreenArgs({
    required this.categoryKey,
    required this.flagsPerSession,
    required this.difficulty,
  });
}

class QuizScreen extends StatefulWidget {
  static const routeName = '/quiz';
  static const describeFlagButtonKey = Key('quiz-describe-flag-button');
  static const flagDescriptionCardKey = Key('quiz-flag-description-card');
  static const flagDescriptionUnavailableKey = Key(
    'quiz-flag-description-unavailable',
  );
  static const hintActionButtonKey = Key('quiz-hint-action-button');
  static const hintSummaryKey = Key('quiz-hint-summary');
  static const nextActionButtonKey = Key('quiz-next-action-button');
  final Future<List<FlagQuestion>> Function()? flagsLoader;
  final List<FlagQuestion> Function(List<FlagQuestion>)? quizPreparer;
  final HintMonetizationGateway? hintMonetizationService;

  const QuizScreen({
    super.key,
    this.flagsLoader,
    this.quizPreparer,
    this.hintMonetizationService,
  });

  /// Creates state for the quiz session screen.
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  static const double _contentHorizontalPadding = 16;
  static const double _contentTopPadding = 24;
  static const double _contentBottomPadding = 24;
  List<FlagQuestion> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _answered = false;
  String? _selectedOption;
  int _score = 0;
  bool _showFlagDescriptionsEnabled = false;
  bool _showCurrentFlagDescription = false;
  bool _isUnlockingHint = false;
  final Set<String> _eliminatedOptions = <String>{};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _nextActionKey = GlobalKey();
  late final QuizScreenArgs args;
  late final HintMonetizationGateway _hintMonetizationService;
  bool _argsLoaded = false;
  bool _hasLoggedQuizStarted = false;
  bool _rewardedHintReady = false;
  bool _refreshingRewardedHintAvailability = false;
  int _hintRequestEpoch = 0;

  static const quizProgressSemanticsKey = Key('quiz-progress-semantics');
  static const answerFeedbackCardKey = Key('quiz-answer-feedback-card');

  /// Initializes state before route-bound data is loaded.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hintMonetizationService =
        widget.hintMonetizationService ?? HintMonetizationService.instance;
    _loadAccessibilityPreferences();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshRewardedHintAvailability(forceRefresh: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAccessibilityPreferences() async {
    try {
      final enabled =
          await AccessibilityPreferences.showFlagDescriptionsEnabled();
      if (!mounted) return;
      setState(() {
        _showFlagDescriptionsEnabled = enabled;
      });
    } catch (e, stackTrace) {
      debugPrint('QuizScreen accessibility preference load failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _refreshRewardedHintAvailability({
    required bool forceRefresh,
  }) async {
    if (!_hintMonetizationService.isEnabled ||
        !_hintMonetizationService.hasRewardedHintsRemaining) {
      if (!mounted || !_rewardedHintReady) return;
      setState(() {
        _rewardedHintReady = false;
      });
      return;
    }
    if (_refreshingRewardedHintAvailability) return;

    _refreshingRewardedHintAvailability = true;
    try {
      final ready = forceRefresh
          ? await _hintMonetizationService.refreshRewardedHintReady()
          : await _hintMonetizationService.isRewardedHintReady();
      if (!mounted || _rewardedHintReady == ready) return;
      setState(() {
        _rewardedHintReady = ready;
      });
    } catch (e, stackTrace) {
      debugPrint('QuizScreen hint availability refresh failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || !_rewardedHintReady) return;
      setState(() {
        _rewardedHintReady = false;
      });
    } finally {
      _refreshingRewardedHintAvailability = false;
    }
  }

  /// Returns default question loader for the requested category.
  Future<List<FlagQuestion>> Function() _defaultLoaderForCategory(
    String categoryKey,
  ) {
    return switch (categoryKey) {
      'capital' => loadAllCapitals,
      _ => loadAllFlags,
    };
  }

  /// Returns default quiz-preparer for the requested category.
  List<FlagQuestion> Function(List<FlagQuestion>) _defaultPreparerForCategory(
    String categoryKey,
  ) {
    return switch (categoryKey) {
      'capital' => prepareCapitalQuiz,
      _ => prepareQuiz,
    };
  }

  /// Returns app-bar category title from category key.
  String _categoryTitle(String categoryKey) {
    return switch (categoryKey) {
      'capital' => 'Capital Quiz',
      _ => 'Flag Quiz',
    };
  }

  /// Returns prompt text shown above answer options.
  String _questionPrompt(String categoryKey) {
    return switch (categoryKey) {
      'capital' => 'What is the capital of this country?',
      _ => 'Which country does this flag belong to?',
    };
  }

  /// Returns empty-state message by category type.
  String _emptyStateMessage(String categoryKey) {
    return switch (categoryKey) {
      'capital' => 'No capital questions found.\nPlease verify flag assets.',
      _ => 'No flags found.\nPlease add images to assets/flags/',
    };
  }

  /// Opens leaderboard filtered to the current quiz scope.
  void _openLeaderboard() {
    Navigator.pushNamed(
      context,
      LeaderboardScreen.routeName,
      arguments: LeaderboardScreenArgs(
        categoryKey: args.categoryKey,
        difficulty: args.difficulty,
      ),
    );
  }

  /// Reads route args once, loads flags, and prepares randomized questions.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      args = ModalRoute.of(context)!.settings.arguments as QuizScreenArgs;
      _argsLoaded = true;
      _hintMonetizationService.resetSession();
      unawaited(_refreshRewardedHintAvailability(forceRefresh: true));
      final loadQuestions =
          widget.flagsLoader ?? _defaultLoaderForCategory(args.categoryKey);
      final prepare =
          widget.quizPreparer ?? _defaultPreparerForCategory(args.categoryKey);
      // -> HERE: load + randomize once at startup
      loadQuestions().then((allFlags) {
        // Shuffle & pick only widget.flagsPerSession
        allFlags.shuffle();
        final count = args.flagsPerSession < allFlags.length
            ? args.flagsPerSession
            : allFlags.length;
        final subset = allFlags.sublist(0, count);
        final quiz = prepare(subset);
        if (!_hasLoggedQuizStarted) {
          _hasLoggedQuizStarted = true;
          unawaited(
            AnalyticsService.instance.logEvent(
              'quiz_started',
              parameters: {
                'category': args.categoryKey,
                'difficulty': args.difficulty,
                'question_count': quiz.length,
              },
            ),
          );
        }
        setState(() {
          _questions = quiz;
          _isLoading = false;
        });
      });
    }
  }

  /// Records an answer and increments score when correct.
  void _handleAnswer(String answer) {
    if (!_answered) {
      setState(() {
        _selectedOption = answer;
        _answered = true;
        if (answer == _questions[_currentIndex].correctAnswer) {
          _score++;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nextContext = _nextActionKey.currentContext;
        if (nextContext != null) {
          Scrollable.ensureVisible(
            nextContext,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: 1,
          );
        }
      });
    }
  }

  /// Advances to the next question or navigates to results when finished.
  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _hintRequestEpoch++;
        _currentIndex++;
        _answered = false;
        _selectedOption = null;
        _isUnlockingHint = false;
        _eliminatedOptions.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(0);
      });
      unawaited(_refreshRewardedHintAvailability(forceRefresh: true));
    } else {
      _hintRequestEpoch++;
      // Instead of pushing ResultScreen(score: _score, total: _questions.length),
      // do:
      Navigator.pushNamed(
        context,
        ResultScreen.routeName,
        arguments: ResultScreenArgs(
          categoryKey: args.categoryKey,
          difficulty: args.difficulty,
          score: _score,
          total: _questions.length,
        ),
      );
    }
  }

  bool _canApplyHint(FlagQuestion question) {
    if (_answered) return false;
    final remainingWrongOptions = question.options
        .where(
          (option) =>
              option != question.correctAnswer &&
              !_eliminatedOptions.contains(option),
        )
        .length;
    return remainingWrongOptions >= 2;
  }

  String _paidHintLabel() {
    final dollars = (_hintMonetizationService.paidHintPriceUsdCents / 100)
        .toStringAsFixed(2);
    return 'Buy Hint (\$$dollars)';
  }

  Future<void> _requestHint(FlagQuestion question) async {
    if (_isUnlockingHint || !_canApplyHint(question)) return;
    final requestEpoch = _hintRequestEpoch;
    final requestedQuestionIndex = _currentIndex;

    setState(() {
      _isUnlockingHint = true;
    });

    final result = await _hintMonetizationService.requestHint();
    if (!mounted) return;
    final isStale =
        requestEpoch != _hintRequestEpoch ||
        requestedQuestionIndex != _currentIndex;

    if (isStale) {
      return;
    }

    if (result.status == HintRequestStatus.granted) {
      final optionsToEliminate = question.options
          .where(
            (option) =>
                option != question.correctAnswer &&
                !_eliminatedOptions.contains(option),
          )
          .take(2)
          .toList(growable: false);

      setState(() {
        _eliminatedOptions.addAll(optionsToEliminate);
      });

      final sourceName = switch (result.source) {
        HintGrantSource.rewardedAd => 'rewarded_ad',
        HintGrantSource.paidHint => 'paid_hint',
        null => 'unknown',
      };
      unawaited(
        AnalyticsService.instance.logEvent(
          'quiz_hint_applied',
          parameters: {
            'category': args.categoryKey,
            'difficulty': args.difficulty,
            'question_index': _currentIndex + 1,
            'source': sourceName,
            'remaining_rewarded_hints':
                result.rewardedHintsRemaining ??
                _hintMonetizationService.rewardedHintsRemaining,
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hint applied. Two wrong answers removed.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }

    if (mounted) {
      setState(() {
        _isUnlockingHint = false;
        if (!_hintMonetizationService.hasRewardedHintsRemaining) {
          _rewardedHintReady = false;
        }
      });
    }
  }

  /// Returns concise non-color feedback details for the answered question.
  _AnswerFeedback _answerFeedbackFor(FlagQuestion question) {
    final selected = _selectedOption ?? '';
    if (selected == question.correctAnswer) {
      return _AnswerFeedback(
        icon: Icons.check_circle_outline,
        title: 'Correct',
        detail: '$selected is the right answer.',
        semanticsLabel: 'Correct. $selected is the right answer.',
      );
    }
    return _AnswerFeedback(
      icon: Icons.error_outline,
      title: 'Incorrect',
      detail:
          'You selected $selected. Correct answer: ${question.correctAnswer}.',
      semanticsLabel:
          'Incorrect. You selected $selected. Correct answer: ${question.correctAnswer}.',
    );
  }

  String? _flagDescriptionFor(FlagQuestion question) {
    final description = question.visualDescription?.trim();
    if (description == null || description.isEmpty) {
      return null;
    }
    return description;
  }

  /// Builds loading, empty, and active-quiz UI states.
  @override
  Widget build(BuildContext context) {
    // 1) Show a loader while flags load
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Guard against empty questions (in case no assets were found)
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_categoryTitle(args.categoryKey)),
          actions: [
            IconButton(
              icon: const Icon(Icons.leaderboard),
              tooltip: 'Leaderboard',
              onPressed: _openLeaderboard,
            ),
          ],
        ),
        body: Center(
          child: Text(
            _emptyStateMessage(args.categoryKey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final q = _questions[_currentIndex];
    final answerFeedback = _answered ? _answerFeedbackFor(q) : null;
    final flagDescription = _flagDescriptionFor(q);
    final visibleOptions = q.options
        .where((option) => !_eliminatedOptions.contains(option))
        .toList(growable: false);
    final cs = Theme.of(context).colorScheme;
    final nextActionLabel = _currentIndex < _questions.length - 1
        ? 'Next'
        : 'See Results';
    final rewardedHintActionAvailable =
        _hintMonetizationService.hasRewardedHintsRemaining &&
        _rewardedHintReady;
    final hintActionLabel = _isUnlockingHint
        ? 'Processing hint...'
        : _hintMonetizationService.hasRewardedHintsRemaining
        ? rewardedHintActionAvailable
              ? 'Watch Ad for Hint'
              : 'Hint Ads Unavailable'
        : _hintMonetizationService.canOfferPaidHint
        ? _paidHintLabel()
        : 'Hints Unavailable';
    final hintSummaryText =
        _hintMonetizationService.hasRewardedHintsRemaining &&
            !rewardedHintActionAvailable
        ? 'Free hints left: ${_hintMonetizationService.rewardedHintsRemaining}. Ad hints are temporarily unavailable.'
        : _hintMonetizationService.hasRewardedHintsRemaining
        ? 'Free hints left: ${_hintMonetizationService.rewardedHintsRemaining}'
        : _hintMonetizationService.canOfferPaidHint
        ? 'Free hints used for this session.'
        : 'No hints left this session.';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          '${_categoryTitle(args.categoryKey)} (${_currentIndex + 1}/${_questions.length})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Leaderboard',
            onPressed: _openLeaderboard,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              width: double.infinity, // fills up to that 600px max
              height: 6,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Semantics(
                key: quizProgressSemanticsKey,
                container: true,
                liveRegion: true,
                label: 'Question ${_currentIndex + 1} of ${_questions.length}',
                value:
                    '${(((_currentIndex + 1) / _questions.length) * 100).round()} percent complete',
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    _contentHorizontalPadding,
                    _contentTopPadding,
                    _contentHorizontalPadding,
                    _contentBottomPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _questionPrompt(args.categoryKey),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Image.asset(
                          q.imagePath,
                          height: 180,
                          fit: BoxFit.contain,
                          semanticLabel:
                              BrandConfig.quizQuestionImageSemanticLabel,
                        ),
                        if (args.categoryKey == 'flag' &&
                            _showFlagDescriptionsEnabled) ...[
                          const SizedBox(height: 8),
                          if (flagDescription == null)
                            const Text(
                              'Flag description is not available for this question yet.',
                              key: QuizScreen.flagDescriptionUnavailableKey,
                              textAlign: TextAlign.center,
                            )
                          else ...[
                            TextButton.icon(
                              key: QuizScreen.describeFlagButtonKey,
                              onPressed: () {
                                setState(() {
                                  _showCurrentFlagDescription =
                                      !_showCurrentFlagDescription;
                                });
                              },
                              icon: Icon(
                                _showCurrentFlagDescription
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              label: Text(
                                _showCurrentFlagDescription
                                    ? 'Hide Flag Description'
                                    : 'Describe Flag',
                              ),
                            ),
                            if (_showCurrentFlagDescription)
                              Semantics(
                                container: true,
                                liveRegion: true,
                                label: 'Flag description: $flagDescription',
                                child: Card(
                                  key: QuizScreen.flagDescriptionCardKey,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      flagDescription,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                        const SizedBox(height: 24),
                        if (_hintMonetizationService.isEnabled) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    key: QuizScreen.hintSummaryKey,
                                    hintSummaryText,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Hint removes 2 wrong answers for this question.',
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    key: QuizScreen.hintActionButtonKey,
                                    onPressed:
                                        (_isUnlockingHint || !_canApplyHint(q))
                                        ? null
                                        : _hintMonetizationService
                                              .hasRewardedHintsRemaining
                                        ? rewardedHintActionAvailable
                                              ? () => _requestHint(q)
                                              : null
                                        : _hintMonetizationService
                                              .canOfferPaidHint
                                        ? () => _requestHint(q)
                                        : null,
                                    icon: const Icon(Icons.lightbulb_outline),
                                    label: Text(hintActionLabel),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        ...visibleOptions.map((opt) {
                          final isCorrect = opt == q.correctAnswer;
                          final isSelected = opt == _selectedOption;
                          Color bg;
                          Color fg = cs.onPrimary;

                          if (!_answered) {
                            bg = cs.primary;
                          } else if (isCorrect) {
                            bg = cs.secondary;
                          } else if (isSelected) {
                            bg = cs.error;
                            fg = cs.onError;
                          } else {
                            bg = cs.surfaceContainerHighest;
                            fg = cs.onSurface;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bg,
                                foregroundColor: fg,
                                minimumSize: const Size.fromHeight(48),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () => _handleAnswer(opt),
                              child: Text(
                                opt,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }),
                        if (_answered) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            label: answerFeedback!.semanticsLabel,
                            child: Card(
                              key: answerFeedbackCardKey,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(answerFeedback.icon),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            answerFeedback.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(answerFeedback.detail),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            key: _nextActionKey,
                            width: double.infinity,
                            child: ElevatedButton(
                              key: QuizScreen.nextActionButtonKey,
                              onPressed: _nextQuestion,
                              child: Text(nextActionLabel),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerFeedback {
  final IconData icon;
  final String title;
  final String detail;
  final String semanticsLabel;

  const _AnswerFeedback({
    required this.icon,
    required this.title,
    required this.detail,
    required this.semanticsLabel,
  });
}
