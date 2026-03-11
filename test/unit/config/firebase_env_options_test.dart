import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/firebase_env_options.dart';

void main() {
  group('AppFirebaseOptions', () {
    test('throws a clear error when required Android keys are missing', () {
      expect(
        () => AppFirebaseOptions.optionsForPlatform(
          targetPlatform: TargetPlatform.android,
          isWeb: false,
          overrides: const <String, String>{
            'FIREBASE_ANDROID_API_KEY': '',
            'FIREBASE_ANDROID_APP_ID': '',
            'FIREBASE_ANDROID_MESSAGING_SENDER_ID': '',
            'FIREBASE_ANDROID_PROJECT_ID': '',
          },
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Missing required Firebase env keys for android'),
          ),
        ),
      );
    });

    test('throws a clear error when required iOS keys are missing', () {
      expect(
        () => AppFirebaseOptions.optionsForPlatform(
          targetPlatform: TargetPlatform.iOS,
          isWeb: false,
          overrides: const <String, String>{
            'FIREBASE_IOS_API_KEY': 'api-key',
            'FIREBASE_IOS_APP_ID': 'app-id',
            'FIREBASE_IOS_MESSAGING_SENDER_ID': 'sender-id',
            'FIREBASE_IOS_PROJECT_ID': 'project-id',
            'FIREBASE_IOS_BUNDLE_ID': '',
          },
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('FIREBASE_IOS_BUNDLE_ID'),
          ),
        ),
      );
    });

    test(
      'returns validated Android options when required keys are present',
      () {
        final options = AppFirebaseOptions.optionsForPlatform(
          targetPlatform: TargetPlatform.android,
          isWeb: false,
          overrides: const <String, String>{
            'FIREBASE_ANDROID_API_KEY': 'api-key',
            'FIREBASE_ANDROID_APP_ID': 'app-id',
            'FIREBASE_ANDROID_MESSAGING_SENDER_ID': 'sender-id',
            'FIREBASE_ANDROID_PROJECT_ID': 'project-id',
            'FIREBASE_ANDROID_STORAGE_BUCKET': 'bucket',
          },
        );

        expect(options.apiKey, 'api-key');
        expect(options.appId, 'app-id');
        expect(options.messagingSenderId, 'sender-id');
        expect(options.projectId, 'project-id');
        expect(options.storageBucket, 'bucket');
      },
    );
  });
}
