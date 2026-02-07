/*
 DOC: Screen
 Title: User Profile Screen
 Purpose: Displays user profile and saved high-score records.
*/
// lib/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import '../services/score_service.dart';
import 'package:quiznetic_flutter/utils/helpers.dart';

class UserProfileScreen extends StatelessWidget {
  static const routeName = '/profile';
  const UserProfileScreen({super.key});

  // Human-readable labels for your category keys:
  static const _labels = {
    'flag': 'Flag Quiz',
    'logo': 'Logo Quiz',
    'capital': 'Capital Quiz',
    // add more as you introduce them...
  };

  /// TODO: Describe the behavior of `build`.
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: FutureBuilder<List<CategoryScore>>(
        future: ScoreService().getAllHighScores(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final scores = snap.data ?? [];

          // If you want to show categories even with zero score,
          // unify `scores` with _labels.keys here.

          if (scores.isEmpty) {
            return const Center(child: Text('No scores yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: scores.length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return Column(
                  children: const [
                    CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'High Scores',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                );
              }

              // build one card per (category + difficulty)
              final sc = scores[i - 1]; // shift because header consumed index 0
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.star, color: cs.primary),
                  title: Text(
                    // e.g. "Flag Quiz (Easy)"
                    '${_labels[sc.categoryKey] ?? sc.categoryKey} '
                    '(${toUpperCase(sc.difficulty[0])})',
                  ),
                  trailing: Text(
                    '${sc.highScore}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
