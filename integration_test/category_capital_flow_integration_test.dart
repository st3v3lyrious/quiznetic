import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quiznetic_flutter/screens/difficulty_screen.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capital category routes from home to difficulty screen', (
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
    await tester.pumpAndSettle();

    expect(find.text('Capital Quiz'), findsOneWidget);

    await tester.tap(find.text('Capital Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('difficulty:capital'), findsOneWidget);
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
