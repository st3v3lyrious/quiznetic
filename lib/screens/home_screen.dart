/*
 DOC: Screen
 Title: Home Screen
 Purpose: Shows quiz categories, guest upgrade CTA, and routes to difficulty selection.
*/
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'difficulty_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';
import 'upgrade_account_screen.dart';
import 'user_profile_screen.dart';
// Later, you’ll have other screens like 'logo_quiz_screen.dart'

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  final AuthService? authService;

  const HomeScreen({super.key, this.authService});

  // Give each category a unique key, name, and icon.
  final List<Category> categories = const [
    Category(key: 'flag', name: 'Flag Quiz', icon: Icons.flag),
    Category(
      key: 'capital',
      name: 'Capital Quiz',
      icon: Icons.location_city_outlined,
    ),
    // Example future category:
    // Category(key: 'logo', name: 'Logo Quiz', icon: Icons.image),
  ];

  /// Returns whether guest conversion CTA should be shown on home.
  bool _shouldShowGuestUpgradeCta(AuthService service) {
    try {
      final user = service.currentUser;
      return user != null && user.isAnonymous;
    } catch (_) {
      return false;
    }
  }

  /// Builds the category selection UI and handles category navigation.
  @override
  Widget build(BuildContext context) {
    final resolvedAuthService = authService ?? AuthService();
    final showGuestUpgradeCta = _shouldShowGuestUpgradeCta(resolvedAuthService);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable back button
        title: const Text('Quiznetic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Leaderboard',
            onPressed: () {
              Navigator.pushNamed(context, LeaderboardScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.pushNamed(context, UserProfileScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, SettingsScreen.routeName);
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
                      semanticLabel: BrandConfig.logoSemanticLabel,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose Your Quiz',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (showGuestUpgradeCta) ...[
                    Card(
                      key: const Key('guest-home-conversion-cta'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Playing as guest',
                              style: TextStyle(
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
                                'guest-home-conversion-cta-action',
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  UpgradeAccountScreen.routeName,
                                );
                              },
                              child: const Text('Create Account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                              if (cat.key == 'flag' || cat.key == 'capital') {
                                Navigator.pushNamed(
                                  context,
                                  DifficultyScreen.routeName,
                                  arguments: DifficultyScreenArgs(
                                    categoryKey: cat.key,
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
