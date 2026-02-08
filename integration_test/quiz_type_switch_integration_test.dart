import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('result flow can switch back to quiz type selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateInitialRoutes: (initialRoute) => [
          MaterialPageRoute(
            settings: RouteSettings(
              name: ResultScreen.routeName,
              arguments: ResultScreenArgs(
                categoryKey: 'flag',
                score: 7,
                total: 10,
                difficulty: 'easy',
              ),
            ),
            builder: (_) => ResultScreen(
              saveScore:
                  ({
                    required categoryKey,
                    required difficulty,
                    required score,
                    required totalQuestions,
                  }) async => score,
              getHighScore: (categoryKey, difficulty) async => 8,
            ),
          ),
        ],
        routes: {HomeScreen.routeName: (_) => const _HomeProbe()},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change Quiz Type'));
    await tester.pumpAndSettle();

    expect(find.text('home-screen'), findsOneWidget);
  });
}

class _HomeProbe extends StatelessWidget {
  const _HomeProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home-screen'));
  }
}
