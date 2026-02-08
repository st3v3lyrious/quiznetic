import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/leaderboard_screen.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';
import 'package:quiznetic_flutter/services/leaderboard_service.dart';

void main() {
  testWidgets('renders ranked rows and highlights current user rank', (
    tester,
  ) async {
    final service = LeaderboardService(
      currentUserLoader: () => _FakeUser(uid: 'u2'),
      entriesLoader:
          ({required categoryKey, required difficulty, required limit}) async =>
              [
                LeaderboardEntry(
                  uid: 'u1',
                  score: 99,
                  updatedAt: DateTime.utc(2025, 1, 1, 0, 1, 0),
                  isAnonymous: false,
                  displayName: 'Player One',
                ),
                LeaderboardEntry(
                  uid: 'u2',
                  score: 98,
                  updatedAt: DateTime.utc(2025, 1, 1, 0, 2, 0),
                  isAnonymous: true,
                  displayName: 'Guest-u2',
                ),
              ],
    );

    await tester.pumpWidget(
      MaterialApp(home: LeaderboardScreen(leaderboardService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Global Leaderboard'), findsOneWidget);
    expect(find.byKey(const Key('leaderboard-scope-summary')), findsOneWidget);
    expect(find.byKey(const Key('leaderboard-your-rank-card')), findsOneWidget);
    expect(find.text('Your rank: #2'), findsOneWidget);
    expect(find.text('Player One'), findsOneWidget);
    expect(find.text('Guest-u2'), findsOneWidget);
  });

  testWidgets('shows empty state when no leaderboard entries exist', (
    tester,
  ) async {
    final service = LeaderboardService(
      currentUserLoader: () => _FakeUser(uid: 'u2'),
      entriesLoader:
          ({required categoryKey, required difficulty, required limit}) async =>
              [],
    );

    await tester.pumpWidget(
      MaterialApp(home: LeaderboardScreen(leaderboardService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No leaderboard entries yet'), findsOneWidget);
    expect(
      find.byKey(const Key('leaderboard-empty-refresh-button')),
      findsOneWidget,
    );
  });

  testWidgets('shows error state and retries load', (tester) async {
    var attempts = 0;
    final service = LeaderboardService(
      currentUserLoader: () => _FakeUser(uid: 'u1'),
      entriesLoader:
          ({required categoryKey, required difficulty, required limit}) async {
            attempts++;
            if (attempts == 1) {
              throw Exception('temporary-failure');
            }
            return [
              LeaderboardEntry(
                uid: 'u1',
                score: 88,
                updatedAt: DateTime.utc(2025, 1, 1, 0, 0, 0),
                isAnonymous: false,
                displayName: 'Player1',
              ),
            ];
          },
    );

    await tester.pumpWidget(
      MaterialApp(home: LeaderboardScreen(leaderboardService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load leaderboard'), findsOneWidget);
    await tester.tap(find.byKey(const Key('leaderboard-error-retry-button')));
    await tester.pumpAndSettle();

    expect(attempts, greaterThanOrEqualTo(2));
    expect(find.byKey(const Key('leaderboard-scope-summary')), findsOneWidget);
    expect(find.text('Player1'), findsOneWidget);
  });

  testWidgets('changing category filter reloads leaderboard scope', (
    tester,
  ) async {
    final requestedScopes = <String>[];
    final service = LeaderboardService(
      currentUserLoader: () => _FakeUser(uid: 'u1'),
      entriesLoader:
          ({required categoryKey, required difficulty, required limit}) async {
            requestedScopes.add('$categoryKey:$difficulty');
            return [
              LeaderboardEntry(
                uid: 'u1',
                score: 50,
                updatedAt: DateTime.utc(2025, 1, 1),
                isAnonymous: false,
                displayName: categoryKey == 'capital'
                    ? 'CapitalLeader'
                    : 'FlagLeader',
              ),
            ];
          },
    );

    await tester.pumpWidget(
      MaterialApp(home: LeaderboardScreen(leaderboardService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('FlagLeader'), findsOneWidget);
    expect(requestedScopes, contains('flag:easy'));

    await tester.tap(find.byKey(const Key('leaderboard-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Capital Quiz').last);
    await tester.pumpAndSettle();

    expect(find.text('CapitalLeader'), findsOneWidget);
    expect(requestedScopes, contains('capital:easy'));
  });
}

class _FakeUser implements User {
  _FakeUser({required this.uid});

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
