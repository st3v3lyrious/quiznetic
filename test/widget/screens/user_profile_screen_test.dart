import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';
import 'package:quiznetic_flutter/services/score_service.dart';

void main() {
  testWidgets('shows loading spinner while scores are loading', (tester) async {
    final completer = Completer<List<CategoryScore>>();

    await tester.pumpWidget(
      MaterialApp(home: UserProfileScreen(scoreLoader: () => completer.future)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no score is available', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: UserProfileScreen(scoreLoader: () async => [])),
    );

    await tester.pumpAndSettle();
    expect(find.text('No scores yet.'), findsOneWidget);
  });

  testWidgets('renders high score cards when data exists', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(
          scoreLoader: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 12,
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('High Scores'), findsOneWidget);
    expect(find.text('Flag Quiz (E)'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('shows error state when loading fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(
          scoreLoader: () async => throw Exception('boom'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Error:'), findsOneWidget);
  });
}
