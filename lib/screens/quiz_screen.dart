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
import '../data/capital_loader.dart';
import '../data/flag_loader.dart';
import '../models/flag_question.dart';
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
  final Future<List<FlagQuestion>> Function()? flagsLoader;
  final List<FlagQuestion> Function(List<FlagQuestion>)? quizPreparer;

  const QuizScreen({super.key, this.flagsLoader, this.quizPreparer});

  /// Creates state for the quiz session screen.
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<FlagQuestion> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _answered = false;
  String? _selectedOption;
  int _score = 0;
  bool _showFlagDescriptionsEnabled = false;
  bool _showCurrentFlagDescription = false;
  late final QuizScreenArgs args;
  bool _argsLoaded = false;
  bool _hasLoggedQuizStarted = false;

  static const quizProgressSemanticsKey = Key('quiz-progress-semantics');
  static const answerFeedbackCardKey = Key('quiz-answer-feedback-card');

  /// Initializes state before route-bound data is loaded.
  @override
  void initState() {
    super.initState();
    _loadAccessibilityPreferences();
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

  /// Reads route args once, loads flags, and prepares randomized questions.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      args = ModalRoute.of(context)!.settings.arguments as QuizScreenArgs;
      _argsLoaded = true;
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
    }
  }

  /// Advances to the next question or navigates to results when finished.
  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedOption = null;
        _showCurrentFlagDescription = false;
      });
    } else {
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
        appBar: AppBar(title: Text(_categoryTitle(args.categoryKey))),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          '${_categoryTitle(args.categoryKey)} (${_currentIndex + 1}/${_questions.length})',
        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
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
                        ...q.options.map((opt) {
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
                          ElevatedButton(
                            onPressed: _nextQuestion,
                            child: Text(
                              _currentIndex < _questions.length - 1
                                  ? 'Next'
                                  : 'See Results',
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
