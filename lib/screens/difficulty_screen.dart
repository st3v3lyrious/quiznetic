import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class DifficultyScreen extends StatelessWidget {
  final String categoryKey;
  const DifficultyScreen({super.key, required this.categoryKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Difficulty')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            categoryKey: categoryKey,
                            flagsPerSession: 15, // Easy
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Easy (15 flags)',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            categoryKey: categoryKey,
                            flagsPerSession: 30, // Intermediate
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Intermediate (30 flags)',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            categoryKey: categoryKey,
                            flagsPerSession: 50, // Expert
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Expert (50 flags)',
                      style: TextStyle(fontSize: 24),
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
