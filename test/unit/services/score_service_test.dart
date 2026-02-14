import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/score_service.dart';

void main() {
  group('ScoreService helper logic', () {
    test('shouldUpdateBestScore returns true only for higher values', () {
      expect(
        ScoreService.shouldUpdateBestScore(previousBest: 10, newScore: 11),
        isTrue,
      );
      expect(
        ScoreService.shouldUpdateBestScore(previousBest: 10, newScore: 10),
        isFalse,
      );
      expect(
        ScoreService.shouldUpdateBestScore(previousBest: 10, newScore: 9),
        isFalse,
      );
    });

    test('parseCategoryScore extracts category and difficulty from doc id', () {
      final parsed = ScoreService.parseCategoryScore(
        docId: 'flag_easy',
        data: {'bestScore': 17},
      );

      expect(parsed.categoryKey, equals('flag'));
      expect(parsed.difficulty, equals('easy'));
      expect(parsed.highScore, equals(17));
    });

    test('parseCategoryScore falls back to unknown difficulty', () {
      final parsed = ScoreService.parseCategoryScore(
        docId: 'flag',
        data: {'bestScore': 9},
      );

      expect(parsed.categoryKey, equals('flag'));
      expect(parsed.difficulty, equals('unknown'));
      expect(parsed.highScore, equals(9));
    });

    test('leaderboardDisplayName prefers explicit display name', () {
      final name = ScoreService.leaderboardDisplayName(
        uid: 'abcdef123',
        isAnonymous: false,
        displayName: 'Alice',
        email: 'alice@example.com',
      );

      expect(name, equals('Alice'));
    });

    test('leaderboardDisplayName falls back to email local-part', () {
      final name = ScoreService.leaderboardDisplayName(
        uid: 'abcdef123',
        isAnonymous: false,
        displayName: null,
        email: 'alice@example.com',
      );

      expect(name, equals('alice'));
    });

    test('leaderboardDisplayName renders guest token for anonymous users', () {
      final name = ScoreService.leaderboardDisplayName(
        uid: 'abcdef123',
        isAnonymous: true,
        displayName: null,
        email: null,
      );

      expect(name, equals('Guest-abcdef'));
    });

    test('normalizeAttemptId keeps explicit id', () {
      final id = ScoreService.normalizeAttemptId('  attempt-123  ');
      expect(id, equals('attempt-123'));
    });

    test('normalizeAttemptId generates fallback id when missing', () {
      final id = ScoreService.normalizeAttemptId(
        null,
        now: DateTime.utc(2025, 1, 1, 0, 0, 0),
      );

      expect(id, equals('auto-1735689600000000'));
    });

    test('shouldFallbackToDirectWrite returns true for rollout codes', () {
      expect(ScoreService.shouldFallbackToDirectWrite('not-found'), isTrue);
      expect(ScoreService.shouldFallbackToDirectWrite('unimplemented'), isTrue);
      expect(ScoreService.shouldFallbackToDirectWrite('unavailable'), isTrue);
      expect(
        ScoreService.shouldFallbackToDirectWrite('deadline-exceeded'),
        isTrue,
      );
    });

    test('shouldFallbackToDirectWrite returns false for hard failures', () {
      expect(
        ScoreService.shouldFallbackToDirectWrite('permission-denied'),
        isFalse,
      );
      expect(
        ScoreService.shouldFallbackToDirectWrite('invalid-argument'),
        isFalse,
      );
      expect(ScoreService.shouldFallbackToDirectWrite('unknown'), isFalse);
    });
  });
}
