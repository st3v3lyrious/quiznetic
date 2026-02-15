import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/data/flag_description_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assetPath = 'assets/metadata/flag_descriptions.json';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<ByteData?> Function(String key) responder = (_) async => null;

  ByteData encodeAsset(String value) {
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.view(bytes.buffer);
  }

  setUp(() async {
    responder = (_) async => null;
    rootBundle.evict(assetPath);
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == null) {
        return null;
      }
      return responder(key);
    });
  });

  tearDown(() async {
    rootBundle.evict(assetPath);
    messenger.setMockMessageHandler('flutter/assets', null);
  });

  test(
    'loads normalized non-empty string descriptions from metadata asset',
    () async {
      responder = (key) async {
        if (key != assetPath) {
          return null;
        }
        return encodeAsset(
          json.encode({
            ' canada ': ' red and white flag with maple leaf ',
            'japan': ' white field with centered red circle ',
            'empty': '   ',
            'bad-type': 42,
            '': 'ignored',
          }),
        );
      };

      final descriptions = await loadFlagDescriptions();

      expect(
        descriptions,
        equals({
          'canada': 'red and white flag with maple leaf',
          'japan': 'white field with centered red circle',
        }),
      );
    },
  );

  test('returns empty map when metadata payload is not a map', () async {
    responder = (key) async {
      if (key != assetPath) {
        return null;
      }
      return encodeAsset(json.encode(['not', 'a', 'map']));
    };

    final descriptions = await loadFlagDescriptions();
    expect(descriptions, isEmpty);
  });

  test('returns empty map when metadata load fails', () async {
    responder = (key) async {
      if (key == assetPath) {
        throw StateError('asset read failed');
      }
      return null;
    };

    final descriptions = await loadFlagDescriptions();
    expect(descriptions, isEmpty);
  });
}
