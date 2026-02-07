/*
 DOC: Screen
 Title: Quiz
 Purpose: Presents questions, records answers, and handles scoring.
*/

import 'package:flutter/material.dart';
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
  late final QuizScreenArgs args;
  bool _argsLoaded = false;

  /// Initializes state before route-bound data is loaded.
  @override
  void initState() {
    super.initState();
  }

  /// Reads route args once, loads flags, and prepares randomized questions.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      args = ModalRoute.of(context)!.settings.arguments as QuizScreenArgs;
      _argsLoaded = true;
      final loadFlags = widget.flagsLoader ?? loadAllFlags;
      final prepare = widget.quizPreparer ?? prepareQuiz;
      // -> HERE: load + randomize once at startup
      loadFlags().then((allFlags) {
        // Shuffle & pick only widget.flagsPerSession
        allFlags.shuffle();
        final count = args.flagsPerSession < allFlags.length
            ? args.flagsPerSession
            : allFlags.length;
        final subset = allFlags.sublist(0, count);
        final quiz = prepare(subset);
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
        appBar: AppBar(title: Text('Flag Quiz')),
        body: const Center(
          child: Text(
            'No flags found.\nPlease add images to assets/flags/',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final q = _questions[_currentIndex];
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('Flag Quiz (${_currentIndex + 1}/${_questions.length})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              width: double.infinity, // fills up to that 600px max
              height: 6,
              margin: const EdgeInsets.symmetric(vertical: 4),
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(q.imagePath, height: 180, fit: BoxFit.contain),
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
                        child: Text(opt, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  if (_answered)
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      child: Text(
                        _currentIndex < _questions.length - 1
                            ? 'Next'
                            : 'See Results',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
