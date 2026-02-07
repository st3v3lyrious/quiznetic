import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';
import 'package:quiznetic_flutter/services/score_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile retry recovers from transient loader failure', (
    tester,
  ) async {
    var callCount = 0;

    Future<List<CategoryScore>> loader() async {
      callCount++;
      if (callCount == 1) {
        throw Exception('temporary-failure');
      }
      return [
        CategoryScore(categoryKey: 'flag', difficulty: 'easy', highScore: 31),
      ];
    }

    await tester.pumpWidget(
      MaterialApp(home: UserProfileScreen(scoreLoader: loader)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load your profile'), findsOneWidget);
    expect(find.byKey(const Key('profile-error-retry-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-error-retry-button')));
    await tester.pumpAndSettle();

    expect(callCount, greaterThanOrEqualTo(2));
    expect(find.text('High Scores'), findsOneWidget);
    expect(find.text('Flag Quiz (Easy)'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
  });
}
