/*
 DOC: Service
 Title: Score Submission Validator
 Purpose: Validates score payloads against accepted quiz scopes and bounds.
*/
import 'package:flutter/foundation.dart';

@immutable
class ScoreSubmissionValidationResult {
  final bool isValid;
  final String? rejectionCode;
  final String? message;

  const ScoreSubmissionValidationResult._({
    required this.isValid,
    this.rejectionCode,
    this.message,
  });

  const ScoreSubmissionValidationResult.valid() : this._(isValid: true);

  const ScoreSubmissionValidationResult.invalid({
    required String rejectionCode,
    required String message,
  }) : this._(isValid: false, rejectionCode: rejectionCode, message: message);
}

class ScoreSubmissionValidationException implements Exception {
  final String rejectionCode;
  final String message;

  ScoreSubmissionValidationException({
    required this.rejectionCode,
    required this.message,
  });

  @override
  String toString() {
    return 'ScoreSubmissionValidationException('
        'rejectionCode: $rejectionCode, message: $message)';
  }
}

class ScoreSubmissionValidator {
  static const Set<String> allowedCategoryKeys = {'flag', 'capital'};
  static const Map<String, int> questionCountByDifficulty = {
    'easy': 15,
    'intermediate': 30,
    'expert': 50,
  };

  /// Returns the expected quiz question count for [difficulty].
  static int? expectedTotalQuestions(String difficulty) {
    return questionCountByDifficulty[difficulty];
  }

  /// Validates a score payload against supported category/difficulty bounds.
  static ScoreSubmissionValidationResult validate({
    required String categoryKey,
    required String difficulty,
    required int score,
    required int totalQuestions,
  }) {
    if (!allowedCategoryKeys.contains(categoryKey)) {
      return const ScoreSubmissionValidationResult.invalid(
        rejectionCode: 'invalid_category',
        message: 'Unsupported quiz category.',
      );
    }

    final expectedTotal = expectedTotalQuestions(difficulty);
    if (expectedTotal == null) {
      return const ScoreSubmissionValidationResult.invalid(
        rejectionCode: 'invalid_difficulty',
        message: 'Unsupported quiz difficulty.',
      );
    }

    if (totalQuestions != expectedTotal) {
      return ScoreSubmissionValidationResult.invalid(
        rejectionCode: 'invalid_total_questions',
        message:
            'Difficulty "$difficulty" expects $expectedTotal questions, got '
            '$totalQuestions.',
      );
    }

    if (score < 0 || score > totalQuestions) {
      return ScoreSubmissionValidationResult.invalid(
        rejectionCode: 'invalid_score_bounds',
        message: 'Score must be between 0 and $totalQuestions.',
      );
    }

    return const ScoreSubmissionValidationResult.valid();
  }
}
