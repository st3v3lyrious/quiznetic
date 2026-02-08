import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/leaderboard_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home routes to leaderboard screen from app-bar action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        routes: {LeaderboardScreen.routeName: (_) => const _LeaderboardProbe()},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Leaderboard'));
    await tester.pumpAndSettle();

    expect(find.text('leaderboard-screen'), findsOneWidget);
  });
}

class _LeaderboardProbe extends StatelessWidget {
  const _LeaderboardProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('leaderboard-screen'));
  }
}
