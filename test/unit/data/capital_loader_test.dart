import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/data/capital_loader.dart';
import 'package:quiznetic_flutter/models/flag_question.dart';

void main() {
  group('normalizeCountryKey', () {
    test('normalizes mixed separators and casing for lookups', () {
      expect(normalizeCountryKey('United-States'), equals('united states'));
      expect(
        normalizeCountryKey('Bosnia-and-Herzegovina'),
        equals('bosnia and herzegovina'),
      );
      expect(normalizeCountryKey('Cote-dIvoire'), equals('cote divoire'));
    });
  });

  group('prepareCapitalQuiz', () {
    final all = <FlagQuestion>[
      FlagQuestion(
        imagePath: 'assets/flags/france.png',
        correctAnswer: 'Paris',
        options: const [],
      ),
      FlagQuestion(
        imagePath: 'assets/flags/japan.png',
        correctAnswer: 'Tokyo',
        options: const [],
      ),
      FlagQuestion(
        imagePath: 'assets/flags/canada.png',
        correctAnswer: 'Ottawa',
        options: const [],
      ),
      FlagQuestion(
        imagePath: 'assets/flags/brazil.png',
        correctAnswer: 'Brasilia',
        options: const [],
      ),
      FlagQuestion(
        imagePath: 'assets/flags/spain.png',
        correctAnswer: 'Madrid',
        options: const [],
      ),
    ];

    test('returns the same number of questions as the input', () {
      final quiz = prepareCapitalQuiz(all);
      expect(quiz.length, equals(all.length));
    });

    test(
      'creates 4 options per question and always includes the correct capital',
      () {
        final quiz = prepareCapitalQuiz(all);

        for (final question in quiz) {
          expect(question.options.length, equals(4));
          expect(question.options, contains(question.correctAnswer));
        }
      },
    );

    test('creates unique options for each generated question', () {
      final quiz = prepareCapitalQuiz(all);

      for (final question in quiz) {
        final unique = question.options.toSet();
        expect(unique.length, equals(4));
      }
    });

    test('returns empty quiz when fewer than four questions are provided', () {
      final shortQuiz = prepareCapitalQuiz(all.take(3).toList());
      expect(shortQuiz, isEmpty);
    });
  });
}
