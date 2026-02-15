import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'package:quiznetic_flutter/services/score_service.dart';
import 'package:quiznetic_flutter/services/score_submission_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalFirstScoreRepository', () {
    test(
      'saveScore updates local best and syncs immediately when remote works',
      () async {
        SharedPreferences.setMockInitialValues({});
        var remoteSaveCalls = 0;

        final repo = LocalFirstScoreRepository(
          currentUserProvider: () => _FakeUser(),
          saveRemoteScore:
              ({
                required categoryKey,
                required difficulty,
                required score,
                required attemptId,
                required totalQuestions,
              }) async {
                remoteSaveCalls++;
              },
          loadRemoteBestScore:
              ({required categoryKey, required difficulty}) async => 0,
          loadRemoteScores: () async => [],
        );

        final result = await repo.saveScore(
          categoryKey: 'flag',
          difficulty: 'easy',
          score: 12,
          totalQuestions: 15,
        );

        expect(result.bestScore, equals(12));
        expect(result.synced, isTrue);
        expect(result.queuedForSync, isFalse);
        expect(remoteSaveCalls, equals(1));

        final best = await repo.getBestScore(
          categoryKey: 'flag',
          difficulty: 'easy',
        );
        expect(best, equals(12));
      },
    );

    test(
      'saveScore queues when remote sync fails and syncPendingScores retries',
      () async {
        SharedPreferences.setMockInitialValues({});
        var shouldFail = true;

        final repo = LocalFirstScoreRepository(
          currentUserProvider: () => _FakeUser(),
          saveRemoteScore:
              ({
                required categoryKey,
                required difficulty,
                required score,
                required attemptId,
                required totalQuestions,
              }) async {
                if (shouldFail) {
                  throw Exception('offline');
                }
              },
          loadRemoteBestScore:
              ({required categoryKey, required difficulty}) async => 0,
          loadRemoteScores: () async => [],
        );

        final first = await repo.saveScore(
          categoryKey: 'flag',
          difficulty: 'easy',
          score: 9,
          totalQuestions: 15,
        );
        expect(first.synced, isFalse);
        expect(first.queuedForSync, isTrue);

        shouldFail = false;
        final syncedCount = await repo.syncPendingScores(forceRetry: true);
        expect(syncedCount, equals(1));
      },
    );

    test(
      'network failures apply backoff before periodic retries run',
      () async {
        SharedPreferences.setMockInitialValues({});
        var shouldFail = true;
        var remoteSaveCalls = 0;
        var now = DateTime(2025, 1, 1, 12, 0, 0);

        final repo = LocalFirstScoreRepository(
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
                if (shouldFail) {
                  throw Exception('network-request-failed');
                }
              },
          loadRemoteBestScore:
              ({required categoryKey, required difficulty}) async => 0,
          loadRemoteScores: () async => [],
        );

        final first = await repo.saveScore(
          categoryKey: 'flag',
          difficulty: 'easy',
          score: 9,
          totalQuestions: 15,
        );
        expect(first.synced, isFalse);
        expect(first.queuedForSync, isTrue);
        expect(remoteSaveCalls, equals(1));

        shouldFail = false;
        final beforeDue = await repo.syncPendingScores();
        expect(beforeDue, equals(0));
        expect(remoteSaveCalls, equals(1));

        now = now.add(const Duration(minutes: 3));
        final afterDue = await repo.syncPendingScores();
        expect(afterDue, equals(1));
        expect(remoteSaveCalls, equals(2));
      },
    );

    test('forceRetry bypasses backoff after offline failures', () async {
      SharedPreferences.setMockInitialValues({});
      var shouldFail = true;
      var remoteSaveCalls = 0;

      final repo = LocalFirstScoreRepository(
        currentUserProvider: () => _FakeUser(),
        saveRemoteScore:
            ({
              required categoryKey,
              required difficulty,
              required score,
              required attemptId,
              required totalQuestions,
            }) async {
              remoteSaveCalls++;
              if (shouldFail) {
                throw Exception('network-request-failed');
              }
            },
        loadRemoteBestScore:
            ({required categoryKey, required difficulty}) async => 0,
        loadRemoteScores: () async => [],
      );

      await repo.saveScore(
        categoryKey: 'flag',
        difficulty: 'easy',
        score: 9,
        totalQuestions: 15,
      );
      expect(remoteSaveCalls, equals(1));

      shouldFail = false;
      final synced = await repo.syncPendingScores(forceRetry: true);
      expect(synced, equals(1));
      expect(remoteSaveCalls, equals(2));
    });

    test('saveScore rejects invalid payload before persisting', () async {
      SharedPreferences.setMockInitialValues({});
      var remoteSaveCalls = 0;

      final repo = LocalFirstScoreRepository(
        currentUserProvider: () => _FakeUser(),
        saveRemoteScore:
            ({
              required categoryKey,
              required difficulty,
              required score,
              required attemptId,
              required totalQuestions,
            }) async {
              remoteSaveCalls++;
            },
        loadRemoteBestScore:
            ({required categoryKey, required difficulty}) async => 0,
        loadRemoteScores: () async => [],
      );

      await expectLater(
        repo.saveScore(
          categoryKey: 'flag',
          difficulty: 'easy',
          score: 10,
          totalQuestions: 30,
        ),
        throwsA(isA<ScoreSubmissionValidationException>()),
      );

      expect(remoteSaveCalls, equals(0));
      final best = await repo.getBestScore(
        categoryKey: 'flag',
        difficulty: 'easy',
      );
      expect(best, equals(0));
    });

    test('syncPendingScores drops invalid pending payloads', () async {
      SharedPreferences.setMockInitialValues({
        'score_attempts_v1': jsonEncode([
          {
            'id': 'invalid-attempt-1',
            'categoryKey': 'flag',
            'difficulty': 'easy',
            'score': 22,
            'totalQuestions': 15,
            'playedAt': DateTime.utc(2025, 1, 1).toIso8601String(),
            'syncState': 'pending',
            'syncAttempts': 0,
            'lastSyncError': null,
            'lastTriedAt': null,
            'nextRetryAt': null,
          },
        ]),
      });
      var remoteSaveCalls = 0;

      final repo = LocalFirstScoreRepository(
        currentUserProvider: () => _FakeUser(),
        saveRemoteScore:
            ({
              required categoryKey,
              required difficulty,
              required score,
              required attemptId,
              required totalQuestions,
            }) async {
              remoteSaveCalls++;
            },
        loadRemoteBestScore:
            ({required categoryKey, required difficulty}) async => 0,
        loadRemoteScores: () async => [],
      );

      final syncedCount = await repo.syncPendingScores(forceRetry: true);
      expect(syncedCount, equals(0));
      expect(remoteSaveCalls, equals(0));

      final prefs = await SharedPreferences.getInstance();
      final rawAttempts = prefs.getString('score_attempts_v1');
      expect(rawAttempts, isNotNull);
      final decoded = jsonDecode(rawAttempts!) as List<dynamic>;
      expect(decoded, isEmpty);
    });

    test(
      'getAllHighScores merges local and remote using max score per key',
      () async {
        SharedPreferences.setMockInitialValues({});

        final repo = LocalFirstScoreRepository(
          currentUserProvider: () => _FakeUser(),
          saveRemoteScore:
              ({
                required categoryKey,
                required difficulty,
                required score,
                required attemptId,
                required totalQuestions,
              }) async {},
          loadRemoteBestScore:
              ({required categoryKey, required difficulty}) async => 0,
          loadRemoteScores: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 14,
            ),
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'expert',
              highScore: 5,
            ),
          ],
        );

        await repo.saveScore(
          categoryKey: 'flag',
          difficulty: 'easy',
          score: 10,
          totalQuestions: 15,
        );

        final scores = await repo.getAllHighScores();
        final easy = scores.firstWhere(
          (s) => s.categoryKey == 'flag' && s.difficulty == 'easy',
        );
        final expert = scores.firstWhere(
          (s) => s.categoryKey == 'flag' && s.difficulty == 'expert',
        );

        expect(easy.highScore, equals(14));
        expect(expert.highScore, equals(5));
      },
    );

    test('getBestScore migrates legacy category-only local key', () async {
      SharedPreferences.setMockInitialValues({'highscore_flag': 11});

      final repo = LocalFirstScoreRepository(
        currentUserProvider: () => null,
        saveRemoteScore:
            ({
              required categoryKey,
              required difficulty,
              required score,
              required attemptId,
              required totalQuestions,
            }) async {},
        loadRemoteBestScore:
            ({required categoryKey, required difficulty}) async => 0,
        loadRemoteScores: () async => [],
      );

      final best = await repo.getBestScore(
        categoryKey: 'flag',
        difficulty: 'easy',
      );
      expect(best, equals(11));
    });
  });
}

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
