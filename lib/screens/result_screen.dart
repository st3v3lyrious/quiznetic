/*
 DOC: Screen
 Title: Result Screen
 Purpose: Shows result summary and next actions after a quiz.
*/
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'quiz_screen.dart';
import 'difficulty_screen.dart';
import 'home_screen.dart';
import 'user_profile_screen.dart';

class ResultScreenArgs {
  final String categoryKey;
  final int score;
  final int total;
  final String difficulty;

  ResultScreenArgs({
    required this.categoryKey,
    required this.score,
    required this.total,
    required this.difficulty,
  });
}

class ResultScreen extends StatefulWidget {
  static const routeName = '/result';
  final Future<int> Function({
    required String categoryKey,
    required String difficulty,
    required int score,
    required int totalQuestions,
  })?
  saveScore;
  final Future<int> Function(String categoryKey, String difficulty)?
  getHighScore;
  final ScoreRepository? scoreRepository;
  final AuthService? authService;
  final LeaderboardBandService? leaderboardBandService;

  const ResultScreen({
    super.key,
    this.saveScore,
    this.getHighScore,
    this.scoreRepository,
    this.authService,
    this.leaderboardBandService,
  });

  /// Creates state for the quiz results screen.
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<_ResultData> _resultDataFuture;
  bool _didInit = false;
  bool _dismissGuestCta = false;

  /// Loads args once, saves score, and resolves the displayed high score.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didInit) {
      _didInit = true;
      final route = ModalRoute.of(context);
      if (route == null || route.settings.arguments == null) {
        return;
      }

      final args = route.settings.arguments as ResultScreenArgs;
      final scoreRepository =
          widget.scoreRepository ?? LocalFirstScoreRepository();
      final saveScore =
          widget.saveScore ??
          ({
            required String categoryKey,
            required String difficulty,
            required int score,
            required int totalQuestions,
          }) => scoreRepository
              .saveScore(
                categoryKey: categoryKey,
                score: score,
                difficulty: difficulty,
                totalQuestions: totalQuestions,
              )
              .then((result) => result.bestScore);
      final getHighScore =
          widget.getHighScore ??
          (String categoryKey, String difficulty) => scoreRepository
              .getBestScore(categoryKey: categoryKey, difficulty: difficulty);

      _resultDataFuture = _loadResultData(
        args: args,
        saveScore: saveScore,
        getHighScore: getHighScore,
      );
    }
  }

  /// Loads high score and optional guest leaderboard band for conversion CTA.
  Future<_ResultData> _loadResultData({
    required ResultScreenArgs args,
    required Future<int> Function({
      required String categoryKey,
      required String difficulty,
      required int score,
      required int totalQuestions,
    })
    saveScore,
    required Future<int> Function(String categoryKey, String difficulty)
    getHighScore,
  }) async {
    final authService = widget.authService ?? AuthService();
    final leaderboardBandService =
        widget.leaderboardBandService ?? LeaderboardBandService();

    try {
      final highScore = await saveScore(
        categoryKey: args.categoryKey,
        score: args.score,
        difficulty: args.difficulty,
        totalQuestions: args.total,
      );
      final band = await _loadAnonymousBand(
        authService: authService,
        leaderboardBandService: leaderboardBandService,
        args: args,
      );
      return _ResultData(highScore: highScore, guestBand: band);
    } catch (e) {
      debugPrint('SaveScore error: $e');
      final highScore = await getHighScore(args.categoryKey, args.difficulty);
      return _ResultData(highScore: highScore, guestBand: null);
    }
  }

  /// Resolves leaderboard band for anonymous users so CTA messaging can be shown.
  Future<LeaderboardBandResult?> _loadAnonymousBand({
    required AuthService authService,
    required LeaderboardBandService leaderboardBandService,
    required ResultScreenArgs args,
  }) async {
    final user = _safeCurrentUser(authService);
    if (user == null || !user.isAnonymous) {
      return null;
    }

    try {
      return await leaderboardBandService.getBandForScore(
        categoryKey: args.categoryKey,
        difficulty: args.difficulty,
        score: args.score,
        candidateUid: user.uid,
        candidateIsAnonymous: true,
        candidateDisplayName: user.displayName,
      );
    } catch (e) {
      debugPrint('Leaderboard band lookup failed: $e');
      return null;
    }
  }

  /// Reads the current user from auth safely in environments without Firebase init.
  User? _safeCurrentUser(AuthService authService) {
    try {
      return authService.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Returns user-facing conversion copy for the resolved leaderboard band.
  String _guestBandMessage(LeaderboardBand band) {
    return switch (band) {
      LeaderboardBand.top10 => "You're in the top 10 as a guest.",
      LeaderboardBand.top20 => "You're in the top 20 as a guest.",
      LeaderboardBand.top100 => "You're in the top 100 as a guest.",
      LeaderboardBand.outsideTop100 =>
        "You're climbing the rankings as a guest.",
    };
  }

  /// Opens account-upgrade flow and hides CTA when guest converts successfully.
  Future<void> _openUpgradeFlow() async {
    await Navigator.pushNamed(context, UpgradeAccountScreen.routeName);

    final authService = widget.authService ?? AuthService();
    final user = _safeCurrentUser(authService);
    if (mounted && user != null && !user.isAnonymous) {
      setState(() {
        _dismissGuestCta = true;
      });
    }
  }

  /// Builds the score summary, high-score status, and follow-up actions.
  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || route.settings.arguments == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Quiz Results'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile',
              onPressed: () {
                Navigator.pushNamed(context, UserProfileScreen.routeName);
              },
            ),
          ],
        ),
        body: const Center(child: Text('Missing result data')),
      );
    }

    final args = route.settings.arguments as ResultScreenArgs;
    final pct = args.total > 0 ? (args.score / args.total * 100).round() : 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Quiz Results'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile',
              onPressed: () {
                Navigator.pushNamed(context, UserProfileScreen.routeName);
              },
            ),
          ],
        ),
        body: FutureBuilder<_ResultData>(
          future: _resultDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading high score'));
            }

            final resultData = snapshot.data!;
            final highScore = resultData.highScore;
            final isNew = args.score >= highScore;
            final guestBand = _dismissGuestCta ? null : resultData.guestBand;

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'You scored ${args.score} out of ${args.total}',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isNew
                                ? '🎉 New High Score: $highScore!'
                                : 'High Score: $highScore',
                            style: const TextStyle(fontSize: 20),
                          ),
                          if (isNew) ...[
                            const SizedBox(height: 8),
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 32,
                            ),
                          ],
                          if (guestBand != null) ...[
                            const SizedBox(height: 24),
                            Card(
                              key: const Key('guest-conversion-cta'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      _guestBandMessage(guestBand.band),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Create an account to compete globally.',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      key: const Key(
                                        'guest-conversion-cta-action',
                                      ),
                                      onPressed: _openUpgradeFlow,
                                      child: const Text('Create Account'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    QuizScreen.routeName,
                                    arguments: QuizScreenArgs(
                                      categoryKey: args.categoryKey,
                                      flagsPerSession: args.total,
                                      difficulty: args.difficulty,
                                    ),
                                  );
                                },
                                child: const Text('Play Again'),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    DifficultyScreen.routeName,
                                    (route) => false,
                                    arguments: DifficultyScreenArgs(
                                      categoryKey: args.categoryKey,
                                    ),
                                  );
                                },
                                child: const Text('Change Difficulty'),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    HomeScreen.routeName,
                                    (route) => false,
                                  );
                                },
                                child: const Text('Change Quiz Type'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ResultData {
  final int highScore;
  final LeaderboardBandResult? guestBand;

  _ResultData({required this.highScore, required this.guestBand});
}
