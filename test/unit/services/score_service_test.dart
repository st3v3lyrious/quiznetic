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
  });
}
