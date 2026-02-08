import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/data/flag_loader.dart';
import 'package:quiznetic_flutter/models/flag_question.dart';

void main() {
  group('prepareQuiz', () {
    final all = <FlagQuestion>[
      FlagQuestion(
        imagePath: 'assets/flags/France.png',
        correctAnswer: 'France',
        options: const [],
      ),
      FlagQuestion(
        imagePath: 'assets/flags/Japan.png',
        correctAnswer: 'Japan',
        options: const [],
      ),
      FlagQuestion(
        imagePath: 'assets/flags/Canada.png',
        correctAnswer: 'Canada',
        options: const [],
      ),
      FlagQuestion(
        imagePath: 'assets/flags/Brazil.png',
        correctAnswer: 'Brazil',
        options: const [],
      ),
      FlagQuestion(
        imagePath: 'assets/flags/Spain.png',
        correctAnswer: 'Spain',
        options: const [],
      ),
    ];

    test('returns the same number of questions as the input', () {
      final quiz = prepareQuiz(all);
      expect(quiz.length, equals(all.length));
    });

    test(
      'creates 4 options per question and always includes the correct answer',
      () {
        final quiz = prepareQuiz(all);

        for (final question in quiz) {
          expect(question.options.length, equals(4));
          expect(question.options, contains(question.correctAnswer));
        }
      },
    );

    test('creates unique options for each generated question', () {
      final quiz = prepareQuiz(all);

      for (final question in quiz) {
        final unique = question.options.toSet();
        expect(unique.length, equals(4));
      }
    });
  });
}
