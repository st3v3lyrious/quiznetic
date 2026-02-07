import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/difficulty_screen.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';

void main() {
  testWidgets('renders category selection and routes to difficulty with args', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == DifficultyScreen.routeName) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const _DifficultyArgsProbe(),
            );
          }
          return null;
        },
      ),
    );

    expect(find.text('Choose Your Quiz'), findsOneWidget);
    expect(find.text('Flag Quiz'), findsOneWidget);

    await tester.tap(find.text('Flag Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('difficulty:flag'), findsOneWidget);
  });

  testWidgets('routes to profile when profile action is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        routes: {UserProfileScreen.routeName: (_) => const _ProfileProbe()},
      ),
    );

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    expect(find.text('profile-screen'), findsOneWidget);
  });
}

class _DifficultyArgsProbe extends StatelessWidget {
  const _DifficultyArgsProbe();

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as DifficultyScreenArgs;
    return Scaffold(body: Text('difficulty:${args.categoryKey}'));
  }
}

class _ProfileProbe extends StatelessWidget {
  const _ProfileProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('profile-screen'));
  }
}
