import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';
import 'package:quiznetic_flutter/services/leaderboard_service.dart';

void main() {
  group('LeaderboardService', () {
    test(
      'sorts entries, assigns ranks, and resolves current user row',
      () async {
        final service = LeaderboardService(
          currentUserLoader: () => _FakeUser(uid: 'u2'),
          entriesLoader:
              ({
                required categoryKey,
                required difficulty,
                required limit,
              }) async => [
                LeaderboardEntry(
                  uid: 'u1',
                  score: 90,
                  updatedAt: DateTime.utc(2025, 1, 1, 1, 0, 0),
                  isAnonymous: false,
                  displayName: 'Player1',
                ),
                LeaderboardEntry(
                  uid: 'u2',
                  score: 95,
                  updatedAt: DateTime.utc(2025, 1, 1, 2, 0, 0),
                  isAnonymous: true,
                  displayName: 'Guest-u2',
                ),
                LeaderboardEntry(
                  uid: 'u3',
                  score: 95,
                  updatedAt: DateTime.utc(2025, 1, 1, 1, 0, 0),
                  isAnonymous: false,
                  displayName: 'Player3',
                ),
              ],
        );

        final snapshot = await service.load(
          categoryKey: 'flag',
          difficulty: 'easy',
        );

        expect(snapshot.rows.length, 3);
        expect(snapshot.rows.map((row) => row.uid).toList(), [
          'u3',
          'u2',
          'u1',
        ]);
        expect(snapshot.rows.map((row) => row.rank).toList(), [1, 2, 3]);
        expect(snapshot.currentUserUid, 'u2');
        expect(snapshot.currentUserRow?.rank, 2);
        expect(snapshot.currentUserRow?.score, 95);
      },
    );

    test(
      'returns null current-user row when user is not in loaded rows',
      () async {
        final service = LeaderboardService(
          currentUserLoader: () => _FakeUser(uid: 'outside'),
          entriesLoader:
              ({
                required categoryKey,
                required difficulty,
                required limit,
              }) async => [
                LeaderboardEntry(
                  uid: 'u1',
                  score: 40,
                  updatedAt: DateTime.utc(2025, 1, 1, 1, 0, 0),
                  isAnonymous: false,
                  displayName: 'Player1',
                ),
              ],
        );

        final snapshot = await service.load(
          categoryKey: 'capital',
          difficulty: 'expert',
        );

        expect(snapshot.currentUserUid, 'outside');
        expect(snapshot.currentUserRow, isNull);
        expect(snapshot.rows.single.rank, 1);
      },
    );
  });
}

class _FakeUser implements User {
  @override
  final String uid;

  _FakeUser({required this.uid});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
