import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quiznetic_flutter/main.dart';

void main() {
  test('QuizNetic can be instantiated', () {
    expect(const QuizNetic(), isA<StatelessWidget>());
  });
}
