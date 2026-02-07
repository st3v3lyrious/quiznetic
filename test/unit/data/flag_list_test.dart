import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/data/flag_list.dart';

void main() {
  group('flagQuestions', () {
    test('contains seed questions', () {
      expect(flagQuestions, isNotEmpty);
    });

    test('each question has 4 options including the correct answer', () {
      for (final question in flagQuestions) {
        expect(question.options.length, equals(4));
        expect(question.options, contains(question.correctAnswer));
      }
    });
  });
}
