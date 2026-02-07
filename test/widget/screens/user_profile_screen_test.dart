import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';
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
    expect(find.text('No high scores yet'), findsOneWidget);
    expect(
      find.text('Play a quiz to save your first best score.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('profile-empty-refresh-button')),
      findsOneWidget,
    );
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
    expect(find.text('Flag Quiz (Easy)'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('orders profile scores deterministically by difficulty labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(
          scoreLoader: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'expert',
              highScore: 40,
            ),
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 20,
            ),
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'intermediate',
              highScore: 30,
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    final titles = tiles.map((tile) => (tile.title as Text).data).toList();

    expect(
      titles,
      equals([
        'Flag Quiz (Easy)',
        'Flag Quiz (Intermediate)',
        'Flag Quiz (Expert)',
      ]),
    );
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
    expect(find.text('Could not load your profile'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(find.byKey(const Key('profile-error-retry-button')), findsOneWidget);
  });

  testWidgets('empty-state refresh reloads profile data', (tester) async {
    var callCount = 0;
    final loaderResults = [
      <CategoryScore>[],
      [CategoryScore(categoryKey: 'flag', difficulty: 'easy', highScore: 18)],
    ];

    Future<List<CategoryScore>> loader() async {
      final index = callCount < loaderResults.length
          ? callCount
          : loaderResults.length - 1;
      callCount++;
      return loaderResults[index];
    }

    await tester.pumpWidget(
      MaterialApp(home: UserProfileScreen(scoreLoader: loader)),
    );

    await tester.pumpAndSettle();
    expect(find.text('No high scores yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-empty-refresh-button')));
    await tester.pumpAndSettle();

    expect(callCount, greaterThanOrEqualTo(2));
    expect(find.text('High Scores'), findsOneWidget);
    expect(find.text('Flag Quiz (Easy)'), findsOneWidget);
  });

  testWidgets('error-state retry reloads profile data', (tester) async {
    var callCount = 0;

    Future<List<CategoryScore>> loader() async {
      callCount++;
      if (callCount == 1) {
        throw Exception('boom');
      }
      return [
        CategoryScore(categoryKey: 'flag', difficulty: 'easy', highScore: 22),
      ];
    }

    await tester.pumpWidget(
      MaterialApp(home: UserProfileScreen(scoreLoader: loader)),
    );

    await tester.pumpAndSettle();
    expect(find.text('Could not load your profile'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-error-retry-button')));
    await tester.pumpAndSettle();

    expect(callCount, greaterThanOrEqualTo(2));
    expect(find.text('High Scores'), findsOneWidget);
    expect(find.text('Flag Quiz (Easy)'), findsOneWidget);
  });

  testWidgets('shows guest conversion CTA text for top-20 profile band', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(
          scoreLoader: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 86,
            ),
          ],
          authService: AuthService(
            currentUserProvider: () =>
                _FakeUser(uid: 'guest_profile_1', isAnonymous: true),
          ),
          leaderboardBandService: LeaderboardBandService(
            entriesLoader:
                ({
                  required categoryKey,
                  required difficulty,
                  required limit,
                }) async => _seededEntries(count: 30),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('guest-profile-conversion-cta')),
      findsOneWidget,
    );
    expect(
      find.text('Your best score is in the top 20 as a guest.'),
      findsOneWidget,
    );
    expect(find.text('Create an account to compete globally.'), findsOneWidget);
  });

  testWidgets('hides guest conversion CTA for non-anonymous users', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(
          scoreLoader: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 95,
            ),
          ],
          authService: AuthService(
            currentUserProvider: () =>
                _FakeUser(uid: 'account_profile_1', isAnonymous: false),
          ),
          leaderboardBandService: LeaderboardBandService(
            entriesLoader:
                ({
                  required categoryKey,
                  required difficulty,
                  required limit,
                }) async => _seededEntries(count: 30),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guest-profile-conversion-cta')), findsNothing);
    expect(find.text('Create an account to compete globally.'), findsNothing);
  });

  testWidgets('uses the strongest leaderboard band across profile categories', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(
          scoreLoader: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 95, // top 10 candidate
            ),
            CategoryScore(
              categoryKey: 'logo',
              difficulty: 'easy',
              highScore: 0, // outside top 100 candidate
            ),
          ],
          authService: AuthService(
            currentUserProvider: () =>
                _FakeUser(uid: 'guest_profile_2', isAnonymous: true),
          ),
          leaderboardBandService: LeaderboardBandService(
            entriesLoader:
                ({
                  required categoryKey,
                  required difficulty,
                  required limit,
                }) async => _seededEntries(count: 100),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('guest-profile-conversion-cta')),
      findsOneWidget,
    );
    expect(
      find.text('Your best score is in the top 10 as a guest.'),
      findsOneWidget,
    );
    expect(
      find.text('Your best score is climbing the rankings as a guest.'),
      findsNothing,
    );
  });

  testWidgets('create account CTA routes guests to upgrade screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {UpgradeAccountScreen.routeName: (_) => const _UpgradeProbe()},
        home: UserProfileScreen(
          scoreLoader: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 86,
            ),
          ],
          authService: AuthService(
            currentUserProvider: () =>
                _FakeUser(uid: 'guest-profile-route', isAnonymous: true),
          ),
          leaderboardBandService: LeaderboardBandService(
            entriesLoader:
                ({
                  required categoryKey,
                  required difficulty,
                  required limit,
                }) async => _seededEntries(count: 30),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('guest-profile-conversion-cta-action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('upgrade-screen'), findsOneWidget);
  });

  testWidgets(
    'hides guest profile CTA after successful account upgrade returns',
    (tester) async {
      User currentUser = _FakeUser(
        uid: 'guest-profile-live',
        isAnonymous: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            UpgradeAccountScreen.routeName: (_) => _UpgradeCompleteProbe(
              onComplete: () {
                currentUser = _FakeUser(
                  uid: 'account-profile-live',
                  isAnonymous: false,
                );
              },
            ),
          },
          home: UserProfileScreen(
            scoreLoader: () async => [
              CategoryScore(
                categoryKey: 'flag',
                difficulty: 'easy',
                highScore: 86,
              ),
            ],
            authService: AuthService(currentUserProvider: () => currentUser),
            leaderboardBandService: LeaderboardBandService(
              entriesLoader:
                  ({
                    required categoryKey,
                    required difficulty,
                    required limit,
                  }) async => _seededEntries(count: 30),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('guest-profile-conversion-cta')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('guest-profile-conversion-cta-action')),
      );
      await tester.pumpAndSettle();

      expect(find.text('complete-upgrade'), findsOneWidget);
      await tester.tap(find.text('complete-upgrade'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('guest-profile-conversion-cta')),
        findsNothing,
      );
    },
  );
}

class _UpgradeProbe extends StatelessWidget {
  const _UpgradeProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('upgrade-screen'));
  }
}

class _UpgradeCompleteProbe extends StatelessWidget {
  final VoidCallback onComplete;

  const _UpgradeCompleteProbe({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            onComplete();
            Navigator.of(context).pop();
          },
          child: const Text('complete-upgrade'),
        ),
      ),
    );
  }
}

List<LeaderboardEntry> _seededEntries({required int count}) {
  return List.generate(count, (index) {
    final rank = index + 1;
    return LeaderboardEntry(
      uid: 'u$rank',
      score: 101 - rank,
      updatedAt: DateTime.utc(2025, 1, 1, 0, rank, 0),
      isAnonymous: false,
      displayName: 'User$rank',
    );
  });
}

class _FakeUser implements User {
  _FakeUser({required this.uid, required this.isAnonymous});

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  String? get displayName => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
