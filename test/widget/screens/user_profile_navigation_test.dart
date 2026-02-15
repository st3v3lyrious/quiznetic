import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/about_screen.dart';
import 'package:quiznetic_flutter/screens/settings_screen.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';
import 'package:quiznetic_flutter/services/score_service.dart';

void main() {
  testWidgets('profile app bar routes to settings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {SettingsScreen.routeName: (_) => const _SettingsProbe()},
        home: UserProfileScreen(
          scoreLoader: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 8,
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('settings-screen'), findsOneWidget);
  });

  testWidgets('profile app bar routes to about', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {AboutScreen.routeName: (_) => const _AboutProbe()},
        home: UserProfileScreen(
          scoreLoader: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 8,
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('About'));
    await tester.pumpAndSettle();

    expect(find.text('about-screen'), findsOneWidget);
  });
}

class _SettingsProbe extends StatelessWidget {
  const _SettingsProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('settings-screen'));
  }
}

class _AboutProbe extends StatelessWidget {
  const _AboutProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('about-screen'));
  }
}
