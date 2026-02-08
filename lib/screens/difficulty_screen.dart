/*
 DOC: Screen
 Title: Difficulty Screen
 Purpose: Lets users choose difficulty and question count.
*/
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';
import 'user_profile_screen.dart';

class DifficultyScreenArgs {
  final String categoryKey;
  DifficultyScreenArgs({required this.categoryKey});
}

class DifficultyScreen extends StatelessWidget {
  static const routeName = '/difficulty';
  const DifficultyScreen({super.key});

  /// Returns difficulty label suffix for the selected category.
  String _difficultyUnit(String categoryKey) {
    return categoryKey == 'capital' ? 'questions' : 'flags';
  }

  /// Builds difficulty options and starts a quiz for the selected category.
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as DifficultyScreenArgs;
    final unit = _difficultyUnit(args.categoryKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Difficulty'),
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
                      Navigator.pushNamed(
                        context,
                        QuizScreen.routeName,
                        arguments: QuizScreenArgs(
                          categoryKey: args.categoryKey,
                          flagsPerSession: 15, // Easy
                          difficulty: 'easy',
                        ),
                      );
                    },
                    child: Text(
                      'Easy (15 $unit)',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        QuizScreen.routeName,
                        arguments: QuizScreenArgs(
                          categoryKey: args.categoryKey,
                          flagsPerSession: 30, // Intermediate
                          difficulty: 'intermediate',
                        ),
                      );
                    },
                    child: Text(
                      'Intermediate (30 $unit)',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        QuizScreen.routeName,
                        arguments: QuizScreenArgs(
                          categoryKey: args.categoryKey,
                          flagsPerSession: 50, // Expert
                          difficulty: 'expert',
                        ),
                      );
                    },
                    child: Text(
                      'Expert (50 $unit)',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
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
            ),
          ),
        ),
      ),
    );
  }
}
