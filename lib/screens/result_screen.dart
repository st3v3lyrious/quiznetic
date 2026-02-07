/*
 DOC: Screen
 Title: Result Screen
 Purpose: Shows result summary and next actions after a quiz.
*/
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/services/score_service.dart';
import '../services/user_profile.dart';
import 'quiz_screen.dart';
import 'difficulty_screen.dart';
import 'user_profile_screen.dart';

// CompatPopScope: a small compatibility wrapper that keeps older
// route-scoped will-pop callbacks (used on some SDKs) while also
// wrapping the child with a `WillPopScope` so newer SDKs that prefer
// the PopScope/WillPopScope mechanism still work. We avoid the name
// `PopScope` to prevent collisions if the framework later exports a
// widget with that name.
typedef PopCallback = Future<bool> Function();

class CompatPopScope extends StatefulWidget {
  final PopCallback? onPop;
  final Widget child;

  const CompatPopScope({this.onPop, required this.child, super.key});

  /// Creates compatibility state for pop-interception handling.
  @override
  State<CompatPopScope> createState() => _CompatPopScopeState();
}

class _CompatPopScopeState extends State<CompatPopScope> {
  ModalRoute<dynamic>? _route;
  // Token returned by newer registerPopEntry API (unknown type, so kept
  // as dynamic). We try to use the newer API first and fall back to the
  // older scoped callbacks when unavailable.
  dynamic _popEntryToken;

  /// Delegates pop handling to the callback when provided.
  Future<bool> _handleWillPop() async {
    if (widget.onPop != null) return await widget.onPop!();
    return true;
  }

  /// Registers or re-registers pop callbacks when route dependencies change.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route) {
      if (_route != null) {
        // Try to unregister using the newer API first.
        try {
          (_route as dynamic).unregisterPopEntry(_popEntryToken);
        } catch (_) {
          // Fallback to older API if present.
          try {
            _route!.removeScopedWillPopCallback(_handleWillPop);
          } catch (_) {
            // ignore: avoid_print
          }
        }
        _popEntryToken = null;
      }

      _route = route;
      if (_route != null) {
        // Try to register using the newer API first. The registerPopEntry
        // call's signature varies across SDKs; using `dynamic` lets us
        // attempt the call at runtime without static errors.
        try {
          _popEntryToken = (_route as dynamic).registerPopEntry(_handleWillPop);
        } catch (_) {
          // Fallback to older API if available.
          try {
            _route!.addScopedWillPopCallback(_handleWillPop);
          } catch (_) {
            // ignore: avoid_print
          }
        }
      }
    }
  }

  /// Unregisters pop callbacks before disposing this state object.
  @override
  void dispose() {
    if (_route != null) {
      // Prefer the newer unregister API when present.
      try {
        (_route as dynamic).unregisterPopEntry(_popEntryToken);
      } catch (_) {
        try {
          _route!.removeScopedWillPopCallback(_handleWillPop);
        } catch (_) {
          // ignore: avoid_print
        }
      }
    }
    super.dispose();
  }

  /// Wraps the child with a will-pop interceptor.
  @override
  Widget build(BuildContext context) {
    // Also wrap with WillPopScope so newer SDKs (or when route-scoped
    // callbacks aren't available) will still call our handler.
    return WillPopScope(onWillPop: _handleWillPop, child: widget.child);
  }
}

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

  const ResultScreen({super.key});

  /// Creates state for the quiz results screen.
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<int> _highScoreFuture;
  bool _didInit = false;

  /// Loads args once, saves score, and resolves the displayed high score.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didInit) {
      _didInit = true;

      // 1) Grab your args safely now that context is ready
      final args =
          ModalRoute.of(context)!.settings.arguments as ResultScreenArgs;

      // fire‐and‐forget; we don’t block the UI
      ScoreService()
          .saveScore(
            categoryKey: args.categoryKey,
            score: args.score,
            difficulty: args.difficulty,
          )
          .catchError((e) => debugPrint('SaveScore error: $e'));

      // Read existing high score, update if needed, and expose final value
      _highScoreFuture = UserProfile.getHighScore(args.categoryKey).then((old) {
        if (args.score > old) {
          return UserProfile.setHighScore(
            args.categoryKey,
            args.score,
          ).then((_) => args.score);
        } else {
          return old;
        }
      });
    }
  }

  /// Initializes result screen state.
  @override
  void initState() {
    super.initState();
  }

  /// Builds the score summary, high-score status, and follow-up actions.
  @override
  Widget build(BuildContext context) {
    // Safely read route arguments. If missing, show an error placeholder.
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

    // Guard against division by zero when computing percentage.
    final pct = args.total > 0 ? (args.score / args.total * 100).round() : 0;

    return CompatPopScope(
      onPop: () async => false,
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
        body: FutureBuilder<int>(
          future: _highScoreFuture,
          builder: (context, snapshot) {
            // 1) Loading spinner
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // 2) Error state
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading high score'));
            }

            // 3) Data ready
            final highScore = snapshot.data!;
            final isNew = args.score >= highScore;

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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

                    // High-score display
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

                    const SizedBox(height: 40),
                    // Action buttons: Play again, Change difficulty, Change quiz type
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
                            // Navigate to the difficulty selection for the same
                            // category. Use pushNamedAndRemoveUntil so we don't
                            // keep the splash/result screens on the navigation
                            // stack.
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
                        // TODO: Implement quiz-type selection screen (e.g. Flag, Logo, Capitals).
                        // When other quiz types are implemented, enable the button below to
                        // navigate to a quiz-type selection screen. For now it's commented
                        // out so users can't navigate to an unimplemented screen.
                        /*
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            QuizTypeSelectionScreen.routeName,
                            // optionally pass current selection
                          );
                        },
                        child: const Text('Change Quiz Type'),
                      ),
                      */
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // High score update is handled once during didChangeDependencies via
  // the _highScoreFuture; no separate method is needed here.
}
