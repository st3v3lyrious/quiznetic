import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/leaderboard_screen.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';
import 'package:quiznetic_flutter/services/leaderboard_service.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'package:quiznetic_flutter/services/score_service.dart';

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

  testWidgets('refresh action triggers leaderboard reload', (tester) async {
    var loadCalls = 0;
    final service = LeaderboardService(
      currentUserLoader: () => _FakeUser(uid: 'u1'),
      entriesLoader:
          ({required categoryKey, required difficulty, required limit}) async {
            loadCalls++;
            return [
              LeaderboardEntry(
                uid: 'u1',
                score: 50,
                updatedAt: DateTime.utc(2025, 1, 1),
                isAnonymous: false,
                displayName: 'Reloadable',
              ),
            ];
          },
    );

    await tester.pumpWidget(
      MaterialApp(home: LeaderboardScreen(leaderboardService: service)),
    );
    await tester.pumpAndSettle();
    expect(loadCalls, equals(1));

    await tester.tap(find.byKey(const Key('leaderboard-refresh-action')));
    await tester.pumpAndSettle();

    expect(loadCalls, greaterThanOrEqualTo(2));
    expect(find.text('Reloadable'), findsOneWidget);
  });

  testWidgets('loads leaderboard when Firebase availability check throws', (
    tester,
  ) async {
    final service = LeaderboardService(
      currentUserLoader: () => _FakeUser(uid: 'u1'),
      entriesLoader:
          ({required categoryKey, required difficulty, required limit}) async =>
              [
                LeaderboardEntry(
                  uid: 'u1',
                  score: 42,
                  updatedAt: DateTime.utc(2025, 1, 1),
                  isAnonymous: false,
                  displayName: 'NoFirebaseStillLoads',
                ),
              ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LeaderboardScreen(
          leaderboardService: service,
          hasFirebaseApp: () => throw StateError('no-firebase'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NoFirebaseStillLoads'), findsOneWidget);
    expect(find.byKey(const Key('leaderboard-scope-summary')), findsOneWidget);
  });

  testWidgets(
    'repair scope is not marked attempted when local best is invalid',
    (tester) async {
      final scoreRepository = _RepairFakeScoreRepository(initialBest: 0);
      final service = LeaderboardService(
        currentUserLoader: () => _FakeUser(uid: 'u1'),
        entriesLoader:
            ({
              required categoryKey,
              required difficulty,
              required limit,
            }) async => [
              LeaderboardEntry(
                uid: 'u2',
                score: 14,
                updatedAt: DateTime.utc(2025, 1, 1),
                isAnonymous: true,
                displayName: 'Guest-u2',
              ),
            ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardScreen(
            leaderboardService: service,
            scoreRepository: scoreRepository,
            hasFirebaseApp: () => true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(scoreRepository.saveScoreCalls, 0);

      scoreRepository.bestScore = 12;
      await tester.tap(find.byKey(const Key('leaderboard-refresh-action')));
      await tester.pumpAndSettle();

      expect(scoreRepository.saveScoreCalls, 1);
    },
  );
  testWidgets('guest with no local score sees play-to-compete message', (
    tester,
  ) async {
    final scoreRepo = _RepairFakeScoreRepository(initialBest: 0);
    final service = LeaderboardService(
      currentUserLoader: () => _FakeUser(uid: 'guest-1', isAnonymous: true),
      entriesLoader:
          ({required categoryKey, required difficulty, required limit}) async =>
              [
                LeaderboardEntry(
                  uid: 'u1',
                  score: 80,
                  updatedAt: DateTime.utc(2025, 1, 1),
                  isAnonymous: false,
                  displayName: 'Player1',
                ),
              ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LeaderboardScreen(
          leaderboardService: service,
          scoreRepository: scoreRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('leaderboard-not-ranked-card')), findsOneWidget);
    expect(find.text('Play a quiz to see where you rank.'), findsOneWidget);
    expect(
      find.byKey(const Key('leaderboard-create-account-button')),
      findsOneWidget,
    );
  });

  testWidgets('guest with ranking score sees hypothetical rank message', (
    tester,
  ) async {
    final scoreRepo = _RepairFakeScoreRepository(initialBest: 85);
    final service = LeaderboardService(
      currentUserLoader: () => _FakeUser(uid: 'guest-1', isAnonymous: true),
      entriesLoader:
          ({required categoryKey, required difficulty, required limit}) async =>
              [
                LeaderboardEntry(
                  uid: 'u1',
                  score: 80,
                  updatedAt: DateTime.utc(2025, 1, 1),
                  isAnonymous: false,
                  displayName: 'Player1',
                ),
              ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LeaderboardScreen(
          leaderboardService: service,
          scoreRepository: scoreRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('leaderboard-not-ranked-card')), findsOneWidget);
    expect(
      find.text('Your score of 85 would put you at #1.'),
      findsOneWidget,
    );
    expect(find.text('Create an account to claim your spot!'), findsOneWidget);
    expect(
      find.byKey(const Key('leaderboard-create-account-button')),
      findsOneWidget,
    );
  });

  testWidgets('guest outside top 100 sees motivational create-account message', (
    tester,
  ) async {
    final scoreRepo = _RepairFakeScoreRepository(initialBest: 50);
    final service = LeaderboardService(
      currentUserLoader: () => _FakeUser(uid: 'guest-1', isAnonymous: true),
      entriesLoader:
          ({required categoryKey, required difficulty, required limit}) async =>
              _makeEntries(100, 80),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LeaderboardScreen(
          leaderboardService: service,
          scoreRepository: scoreRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('leaderboard-not-ranked-card')), findsOneWidget);
    expect(
      find.text("Your score of 50 isn't in the top 100 yet."),
      findsOneWidget,
    );
    expect(
      find.text('Create an account and keep playing to climb the ranks!'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('leaderboard-create-account-button')),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows not-ranked message for registered user not yet on leaderboard',
    (tester) async {
      final service = LeaderboardService(
        currentUserLoader: () => _FakeUser(uid: 'u-new'),
        entriesLoader:
            ({
              required categoryKey,
              required difficulty,
              required limit,
            }) async => [
              LeaderboardEntry(
                uid: 'u1',
                score: 80,
                updatedAt: DateTime.utc(2025, 1, 1),
                isAnonymous: false,
                displayName: 'Player1',
              ),
            ],
      );

      await tester.pumpWidget(
        MaterialApp(home: LeaderboardScreen(leaderboardService: service)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('You are not ranked in this top list yet.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('leaderboard-create-account-button')),
        findsNothing,
      );
    },
  );
}

List<LeaderboardEntry> _makeEntries(int count, int score) => List.generate(
  count,
  (i) => LeaderboardEntry(
    uid: 'u$i',
    score: score,
    updatedAt: DateTime.utc(2025, 1, 1),
    isAnonymous: false,
    displayName: 'Player$i',
  ),
);

class _FakeUser implements User {
  _FakeUser({required this.uid, this.isAnonymous = false});

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RepairFakeScoreRepository implements ScoreRepository {
  _RepairFakeScoreRepository({required int initialBest})
    : bestScore = initialBest;

  int bestScore;
  int saveScoreCalls = 0;

  @override
  Future<int> getBestScore({
    required String categoryKey,
    required String difficulty,
  }) async => bestScore;

  @override
  Future<List<CategoryScore>> getAllHighScores() async => const [];

  @override
  Future<ScoreSaveResult> saveScore({
    required String categoryKey,
    required String difficulty,
    required int score,
    required int totalQuestions,
  }) async {
    saveScoreCalls++;
    return ScoreSaveResult(
      bestScore: score,
      synced: true,
      queuedForSync: false,
    );
  }

  @override
  Future<int> syncPendingScores({bool forceRetry = false}) async => 0;

  @override
  Future<void> clearLocalData() async {}
}
