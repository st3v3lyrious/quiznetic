import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/difficulty_screen.dart';
import 'package:quiznetic_flutter/screens/quiz_screen.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';

void main() {
  Future<void> pumpDifficultyScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateInitialRoutes: (initialRoute) => [
          MaterialPageRoute(
            settings: RouteSettings(
              name: DifficultyScreen.routeName,
              arguments: DifficultyScreenArgs(categoryKey: 'flag'),
            ),
            builder: (_) => const DifficultyScreen(),
          ),
        ],
        routes: {
          UserProfileScreen.routeName: (_) => const _ProfileProbe(),
          QuizScreen.routeName: (_) => const _QuizArgsProbe(),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders all difficulty actions', (tester) async {
    await pumpDifficultyScreen(tester);

    expect(find.text('Easy (15 flags)'), findsOneWidget);
    expect(find.text('Intermediate (30 flags)'), findsOneWidget);
    expect(find.text('Expert (50 flags)'), findsOneWidget);
  });

  testWidgets('routes to quiz with easy args', (tester) async {
    await pumpDifficultyScreen(tester);

    await tester.tap(find.text('Easy (15 flags)'));
    await tester.pumpAndSettle();

    expect(find.text('quiz:flag:15:easy'), findsOneWidget);
  });

  testWidgets('routes to quiz with intermediate args', (tester) async {
    await pumpDifficultyScreen(tester);

    await tester.tap(find.text('Intermediate (30 flags)'));
    await tester.pumpAndSettle();

    expect(find.text('quiz:flag:30:intermediate'), findsOneWidget);
  });

  testWidgets('routes to quiz with expert args', (tester) async {
    await pumpDifficultyScreen(tester);

    await tester.tap(find.text('Expert (50 flags)'));
    await tester.pumpAndSettle();

    expect(find.text('quiz:flag:50:expert'), findsOneWidget);
  });

  testWidgets('routes to profile from app bar action', (tester) async {
    await pumpDifficultyScreen(tester);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('profile-screen'), findsOneWidget);
  });
}

class _QuizArgsProbe extends StatelessWidget {
  const _QuizArgsProbe();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as QuizScreenArgs;
    return Scaffold(
      body: Text(
        'quiz:${args.categoryKey}:${args.flagsPerSession}:${args.difficulty}',
      ),
    );
  }
}

class _ProfileProbe extends StatelessWidget {
  const _ProfileProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('profile-screen'));
  }
}
