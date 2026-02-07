import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/models/flag_question.dart';

void main() {
  group('FlagQuestion', () {
    test('stores constructor values', () {
      final question = FlagQuestion(
        imagePath: 'assets/flags/france.png',
        correctAnswer: 'France',
        options: const ['France', 'Italy', 'Spain', 'Germany'],
      );

      expect(question.imagePath, equals('assets/flags/france.png'));
      expect(question.correctAnswer, equals('France'));
      expect(
        question.options,
        equals(const ['France', 'Italy', 'Spain', 'Germany']),
      );
    });
  });
}
