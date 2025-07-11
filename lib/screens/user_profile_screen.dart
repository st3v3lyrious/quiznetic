// lib/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import '../services/user_profile.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  // Define which categories you want to show here:
  static const _categories = {
    'flag': 'Flag Quiz',
    'logo': 'Logo Quiz',
    'capital': 'Capital Quiz',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Optional: user avatar / name here
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 16),
          const Text(
            'High Scores',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // One FutureBuilder per category
          ..._categories.entries.map((entry) {
            final key = entry.key;
            final label = entry.value;
            return FutureBuilder<int>(
              future: UserProfile.getHighScore(key),
              builder: (context, snap) {
                final hs = snap.data ?? 0;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.star, color: cs.primary),
                    title: Text(label),
                    trailing: Text(
                      '$hs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
