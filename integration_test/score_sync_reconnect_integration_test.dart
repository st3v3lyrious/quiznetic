import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'package:quiznetic_flutter/services/score_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Score sync reconnect integration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('queues offline score and flushes it after reconnect', (
      tester,
    ) async {
      var now = DateTime(2025, 1, 1, 9, 0, 0);
      var networkOnline = false;
      var remoteSaveCalls = 0;

      LocalFirstScoreRepository buildRepository() {
        return LocalFirstScoreRepository(
          currentUserProvider: () => _FakeUser(),
          nowProvider: () => now,
          saveRemoteScore:
              ({
                required categoryKey,
                required difficulty,
                required score,
                required attemptId,
                required totalQuestions,
              }) async {
                remoteSaveCalls++;
                if (!networkOnline) {
                  throw Exception('network-request-failed');
                }
              },
          loadRemoteBestScore:
              ({required categoryKey, required difficulty}) async => 0,
          loadRemoteScores: () async => <CategoryScore>[],
        );
      }

      final firstRepo = buildRepository();
      final saveResult = await firstRepo.saveScore(
        categoryKey: 'flag',
        difficulty: 'easy',
        score: 12,
        totalQuestions: 15,
      );

      expect(saveResult.synced, isFalse);
      expect(saveResult.queuedForSync, isTrue);
      expect(remoteSaveCalls, equals(1));

      networkOnline = true;

      // Simulate a restart/crash-recovery path by creating a new repository
      // instance that loads pending attempts from local persistence.
      final restartedRepo = buildRepository();
      final synced = await restartedRepo.syncPendingScores(forceRetry: true);
      expect(synced, equals(1));

      final best = await restartedRepo.getBestScore(
        categoryKey: 'flag',
        difficulty: 'easy',
      );
      expect(best, equals(12));
    });

    testWidgets(
      'non-forced retry waits for cooldown but forced retry bypasses it',
      (tester) async {
        var now = DateTime(2025, 1, 1, 12, 0, 0);
        var networkOnline = false;
        var remoteSaveCalls = 0;

        final repository = LocalFirstScoreRepository(
          currentUserProvider: () => _FakeUser(),
          nowProvider: () => now,
          saveRemoteScore:
              ({
                required categoryKey,
                required difficulty,
                required score,
                required attemptId,
                required totalQuestions,
              }) async {
                remoteSaveCalls++;
                if (!networkOnline) {
                  throw Exception('network-request-failed');
                }
              },
          loadRemoteBestScore:
              ({required categoryKey, required difficulty}) async => 0,
          loadRemoteScores: () async => <CategoryScore>[],
        );

        await repository.saveScore(
          categoryKey: 'flag',
          difficulty: 'easy',
          score: 8,
          totalQuestions: 15,
        );
        expect(remoteSaveCalls, equals(1));

        networkOnline = true;

        final nonForced = await repository.syncPendingScores();
        expect(nonForced, equals(0));
        expect(remoteSaveCalls, equals(1));

        final forced = await repository.syncPendingScores(forceRetry: true);
        expect(forced, equals(1));
        expect(remoteSaveCalls, equals(2));
      },
    );
  });
}

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
