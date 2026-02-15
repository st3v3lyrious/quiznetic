import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _minCoverage = 0.70;
const _minWordsPerDescription = 5;

const _forbiddenPlaceholderTerms = <String>[
  'todo',
  'tbd',
  'coming soon',
  'unavailable',
  'placeholder',
];

const _descriptionCueTerms = <String>[
  'stripe',
  'band',
  'cross',
  'circle',
  'star',
  'triangle',
  'canton',
  'emblem',
  'symbol',
  'diamond',
  'sun',
  'moon',
  'disc',
  'border',
  'field',
  'coat of arms',
  'shield',
  'script',
  'dragon',
  'sword',
  'trigram',
];

void main() {
  group('flag description metadata', () {
    final metadataFile = File('assets/metadata/flag_descriptions.json');
    final flagsDir = Directory('assets/flags');

    Map<String, String> loadDescriptions() {
      expect(metadataFile.existsSync(), isTrue);
      final decoded =
          json.decode(metadataFile.readAsStringSync()) as Map<String, dynamic>;

      final result = <String, String>{};
      for (final entry in decoded.entries) {
        expect(
          entry.value,
          isA<String>(),
          reason: 'Metadata value for "${entry.key}" must be a string.',
        );
        result[entry.key] = (entry.value as String);
      }
      return result;
    }

    Set<String> loadAssetKeys() {
      expect(flagsDir.existsSync(), isTrue);
      return flagsDir
          .listSync()
          .whereType<File>()
          .map((file) => file.path.split(Platform.pathSeparator).last)
          .where((name) => name.contains('.'))
          .map((name) => name.split('.').first)
          .map(_normalizeKey)
          .toSet();
    }

    test('entries are normalized and contain meaningful descriptions', () {
      final descriptions = loadDescriptions();
      expect(descriptions, isNotEmpty);

      for (final entry in descriptions.entries) {
        final key = entry.key;
        final value = entry.value.trim();

        expect(key.trim(), equals(key), reason: 'Metadata key has padding.');
        expect(key, equals(_normalizeKey(key)), reason: 'Metadata key format.');
        expect(value, isNotEmpty, reason: 'Empty description for "$key".');

        final wordCount = value
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        expect(
          wordCount,
          greaterThanOrEqualTo(_minWordsPerDescription),
          reason: 'Description for "$key" is too short.',
        );

        final lower = value.toLowerCase();
        for (final forbidden in _forbiddenPlaceholderTerms) {
          expect(
            lower.contains(forbidden),
            isFalse,
            reason:
                'Description for "$key" contains placeholder text ("$forbidden").',
          );
        }

        final hasCue = _descriptionCueTerms.any(lower.contains);
        expect(
          hasCue,
          isTrue,
          reason:
              'Description for "$key" should include at least one structural cue term.',
        );
      }
    });

    test('coverage stays above minimum baseline and metadata keys are valid', () {
      final descriptions = loadDescriptions();
      final assetKeys = loadAssetKeys();

      final orphanKeys =
          descriptions.keys.where((k) => !assetKeys.contains(k)).toList()
            ..sort();
      expect(
        orphanKeys,
        isEmpty,
        reason: 'Metadata keys without matching flag asset: $orphanKeys',
      );

      final coveredCount = assetKeys.where(descriptions.containsKey).length;
      final coverage = coveredCount / assetKeys.length;
      expect(
        coverage,
        greaterThanOrEqualTo(_minCoverage),
        reason:
            'Flag description coverage ${(coverage * 100).toStringAsFixed(2)}% '
            'is below required ${(100 * _minCoverage).toStringAsFixed(0)}%.',
      );
    });
  });
}

String _normalizeKey(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
