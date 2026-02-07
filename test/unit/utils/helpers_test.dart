import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/utils/helpers.dart';

void main() {
  group('toUpperCase', () {
    test('returns Unknown when input is empty', () {
      expect(toUpperCase(''), equals('Unknown'));
    });

    test('capitalizes only the first character when input is lowercase', () {
      expect(toUpperCase('france'), equals('France'));
    });

    test('keeps already-capitalized values unchanged', () {
      expect(toUpperCase('Japan'), equals('Japan'));
    });
  });
}
