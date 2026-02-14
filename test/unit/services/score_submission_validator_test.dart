import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/score_submission_validator.dart';

void main() {
  group('ScoreSubmissionValidator', () {
    test('accepts supported category/difficulty with bounded score', () {
      final result = ScoreSubmissionValidator.validate(
        categoryKey: 'flag',
        difficulty: 'easy',
        score: 14,
        totalQuestions: 15,
      );

      expect(result.isValid, isTrue);
      expect(result.rejectionCode, isNull);
    });

    test('rejects unsupported category', () {
      final result = ScoreSubmissionValidator.validate(
        categoryKey: 'logo',
        difficulty: 'easy',
        score: 10,
        totalQuestions: 15,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionCode, equals('invalid_category'));
    });

    test('rejects unsupported difficulty', () {
      final result = ScoreSubmissionValidator.validate(
        categoryKey: 'flag',
        difficulty: 'hard',
        score: 10,
        totalQuestions: 15,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionCode, equals('invalid_difficulty'));
    });

    test('rejects mismatched total questions for difficulty', () {
      final result = ScoreSubmissionValidator.validate(
        categoryKey: 'capital',
        difficulty: 'expert',
        score: 40,
        totalQuestions: 30,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionCode, equals('invalid_total_questions'));
    });

    test('rejects score bounds outside 0..totalQuestions', () {
      final negative = ScoreSubmissionValidator.validate(
        categoryKey: 'capital',
        difficulty: 'intermediate',
        score: -1,
        totalQuestions: 30,
      );
      final aboveTotal = ScoreSubmissionValidator.validate(
        categoryKey: 'capital',
        difficulty: 'intermediate',
        score: 31,
        totalQuestions: 30,
      );

      expect(negative.rejectionCode, equals('invalid_score_bounds'));
      expect(aboveTotal.rejectionCode, equals('invalid_score_bounds'));
    });

    test('returns configured total questions per difficulty', () {
      expect(
        ScoreSubmissionValidator.expectedTotalQuestions('easy'),
        equals(15),
      );
      expect(
        ScoreSubmissionValidator.expectedTotalQuestions('intermediate'),
        equals(30),
      );
      expect(
        ScoreSubmissionValidator.expectedTotalQuestions('expert'),
        equals(50),
      );
      expect(
        ScoreSubmissionValidator.expectedTotalQuestions('unknown'),
        isNull,
      );
    });
  });
}
