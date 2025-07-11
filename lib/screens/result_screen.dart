import 'package:flutter/material.dart';
import '../services/user_profile.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatefulWidget {
  final String categoryKey; // new: e.g. 'flag'
  final int score;
  final int total;

  const ResultScreen({
    super.key,
    required this.categoryKey,
    required this.score,
    required this.total,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<int> _highScoreFuture;

  @override
  void initState() {
    super.initState();
    // Read existing high score, update if needed, and expose final value
    _highScoreFuture = UserProfile.getHighScore(widget.categoryKey).then((old) {
      if (widget.score > old) {
        return UserProfile.setHighScore(
          widget.categoryKey,
          widget.score,
        ).then((_) => widget.score);
      } else {
        return old;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.score / widget.total * 100).round();
    // final cs = Theme.of(context).colorScheme;

    // Update the high score for this category if needed
    _updateHighScore();

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results')),
      body: FutureBuilder<int>(
        future: _highScoreFuture,
        builder: (context, snapshot) {
          final highScore = snapshot.data ?? 0;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You scored ${widget.score} out of ${widget.total}',
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
                    'High Score: $highScore',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      // For simplicity, assume categoryKey == 'flag' always runs QuizScreen(),
                      // or you could pass a factory that picks the right screen per category.
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            categoryKey: widget.categoryKey,
                            flagsPerSession: widget.total,
                          ),
                        ),
                      );
                    },
                    child: const Text('Play Again'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateHighScore() async {
    final oldHigh = await UserProfile.getHighScore(widget.categoryKey);
    if (widget.score > oldHigh) {
      await UserProfile.setHighScore(widget.categoryKey, widget.score);
    }
  }
}
