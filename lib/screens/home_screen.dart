import 'package:flutter/material.dart';
import 'difficulty_screen.dart';
import 'user_profile_screen.dart';
// Later, you’ll have other screens like 'logo_quiz_screen.dart'

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // List your categories here; for now, just "Flag Quiz"
  // 1) Give each category a unique key, name, and icon
  final List<Category> categories = const [
    Category(key: 'flag', name: 'Flag Quiz', icon: Icons.flag),
    // You could add more later:
    // Category(key: 'logo', name: 'Logo Quiz', icon: Icons.image),
    // Category(key: 'capital', name: 'Capital Quiz', icon: Icons.location_city),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiznetic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
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
                  const SizedBox(height: 40),
                  // 1) Logo at the top
                  Center(
                    child: Image.asset(
                      'assets/images/logo-no-background.png',
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose Your Quiz',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 2) Dynamic ListView of categories
                  Expanded(
                    child: ListView.builder(
                      itemCount: categories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemBuilder: (context, index) {
                        final cat = categories[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ElevatedButton.icon(
                            icon: Icon(cat.icon, size: 28),
                            label: Text(
                              cat.name,
                              style: const TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(60),
                            ),
                            onPressed: () {
                              // For now, only Flag Quiz is implemented:
                              if (cat.key == 'flag') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DifficultyScreen(categoryKey: cat.key),
                                  ),
                                );
                              } else {
                                // Placeholder for future categories
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${cat.name} is coming soon!',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
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

// Helper class for category metadata
class Category {
  final String key; // e.g. "flag", "logo", "capital"
  final String name; // e.g. "Flag Quiz"
  final IconData icon; // e.g. Icons.flag

  const Category({required this.key, required this.name, required this.icon});
}
