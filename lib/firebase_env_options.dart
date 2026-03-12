/*
 DOC: Config
 Title: Firebase Env Options
 Purpose: Provides env-driven FirebaseOptions without relying on a generated FlutterFire file.
*/
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;

/// Runtime [FirebaseOptions] resolved from compile-time env values.
///
/// This file is intentionally maintained by the app, not by FlutterFire CLI.
/// Keep it separate from `lib/firebase_options.dart` so future FlutterFire
/// regeneration cannot overwrite the env-based configuration path.
///
/// Web builds used for CI/e2e still need `FIREBASE_WEB_*` defines. The
/// Playwright workflow injects stub values so validation remains strict for
/// normal builds without requiring production web Firebase credentials.
class AppFirebaseOptions {
  static const _webApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: '',
  );
  static const _webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '',
  );
  static const _webMessagingSenderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
  static const _webProjectId = String.fromEnvironment(
    'FIREBASE_WEB_PROJECT_ID',
    defaultValue: '',
  );
  static const _webAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: '',
  );
  static const _webStorageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
    defaultValue: '',
  );
  static const _webMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
    defaultValue: '',
  );

  static const _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: '',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '',
  );
  static const _androidMessagingSenderId = String.fromEnvironment(
    'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
    defaultValue: String.fromEnvironment(
      'FIREBASE_PROJECT_NUMBER',
      defaultValue: '',
    ),
  );
  static const _androidProjectId = String.fromEnvironment(
    'FIREBASE_ANDROID_PROJECT_ID',
    defaultValue: '',
  );
  static const _androidStorageBucket = String.fromEnvironment(
    'FIREBASE_ANDROID_STORAGE_BUCKET',
    defaultValue: '',
  );

  static const _iosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
    defaultValue: '',
  );
  static const _iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '',
  );
  static const _iosMessagingSenderId = String.fromEnvironment(
    'FIREBASE_IOS_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
  static const _iosProjectId = String.fromEnvironment(
    'FIREBASE_IOS_PROJECT_ID',
    defaultValue: '',
  );
  static const _iosStorageBucket = String.fromEnvironment(
    'FIREBASE_IOS_STORAGE_BUCKET',
    defaultValue: '',
  );
  static const _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: '',
  );

  static FirebaseOptions get currentPlatform {
    return optionsForPlatform(
      targetPlatform: defaultTargetPlatform,
      isWeb: kIsWeb,
    );
  }

  @visibleForTesting
  static FirebaseOptions optionsForPlatform({
    required TargetPlatform targetPlatform,
    required bool isWeb,
    Map<String, String>? overrides,
  }) {
    if (isWeb) {
      _validateRequiredKeys(
        platformLabel: 'web',
        values: {
          'FIREBASE_WEB_API_KEY': _valueFor(
            'FIREBASE_WEB_API_KEY',
            _webApiKey,
            overrides,
          ),
          'FIREBASE_WEB_APP_ID': _valueFor(
            'FIREBASE_WEB_APP_ID',
            _webAppId,
            overrides,
          ),
          'FIREBASE_WEB_MESSAGING_SENDER_ID': _valueFor(
            'FIREBASE_WEB_MESSAGING_SENDER_ID',
            _webMessagingSenderId,
            overrides,
          ),
          'FIREBASE_WEB_PROJECT_ID': _valueFor(
            'FIREBASE_WEB_PROJECT_ID',
            _webProjectId,
            overrides,
          ),
        },
      );
      return FirebaseOptions(
        apiKey: _valueFor('FIREBASE_WEB_API_KEY', _webApiKey, overrides),
        appId: _valueFor('FIREBASE_WEB_APP_ID', _webAppId, overrides),
        messagingSenderId: _valueFor(
          'FIREBASE_WEB_MESSAGING_SENDER_ID',
          _webMessagingSenderId,
          overrides,
        ),
        projectId: _valueFor(
          'FIREBASE_WEB_PROJECT_ID',
          _webProjectId,
          overrides,
        ),
        authDomain: _optionalValue(
          'FIREBASE_WEB_AUTH_DOMAIN',
          _webAuthDomain,
          overrides,
        ),
        storageBucket: _optionalValue(
          'FIREBASE_WEB_STORAGE_BUCKET',
          _webStorageBucket,
          overrides,
        ),
        measurementId: _optionalValue(
          'FIREBASE_WEB_MEASUREMENT_ID',
          _webMeasurementId,
          overrides,
        ),
      );
    }
    switch (targetPlatform) {
      case TargetPlatform.android:
        _validateRequiredKeys(
          platformLabel: 'android',
          values: {
            'FIREBASE_ANDROID_API_KEY': _valueFor(
              'FIREBASE_ANDROID_API_KEY',
              _androidApiKey,
              overrides,
            ),
            'FIREBASE_ANDROID_APP_ID': _valueFor(
              'FIREBASE_ANDROID_APP_ID',
              _androidAppId,
              overrides,
            ),
            'FIREBASE_ANDROID_MESSAGING_SENDER_ID': _valueFor(
              'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
              _androidMessagingSenderId,
              overrides,
            ),
            'FIREBASE_ANDROID_PROJECT_ID': _valueFor(
              'FIREBASE_ANDROID_PROJECT_ID',
              _androidProjectId,
              overrides,
            ),
          },
        );
        return FirebaseOptions(
          apiKey: _valueFor(
            'FIREBASE_ANDROID_API_KEY',
            _androidApiKey,
            overrides,
          ),
          appId: _valueFor('FIREBASE_ANDROID_APP_ID', _androidAppId, overrides),
          messagingSenderId: _valueFor(
            'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
            _androidMessagingSenderId,
            overrides,
          ),
          projectId: _valueFor(
            'FIREBASE_ANDROID_PROJECT_ID',
            _androidProjectId,
            overrides,
          ),
          storageBucket: _optionalValue(
            'FIREBASE_ANDROID_STORAGE_BUCKET',
            _androidStorageBucket,
            overrides,
          ),
        );
      case TargetPlatform.iOS:
        _validateRequiredKeys(
          platformLabel: 'ios',
          values: {
            'FIREBASE_IOS_API_KEY': _valueFor(
              'FIREBASE_IOS_API_KEY',
              _iosApiKey,
              overrides,
            ),
            'FIREBASE_IOS_APP_ID': _valueFor(
              'FIREBASE_IOS_APP_ID',
              _iosAppId,
              overrides,
            ),
            'FIREBASE_IOS_MESSAGING_SENDER_ID': _valueFor(
              'FIREBASE_IOS_MESSAGING_SENDER_ID',
              _iosMessagingSenderId,
              overrides,
            ),
            'FIREBASE_IOS_PROJECT_ID': _valueFor(
              'FIREBASE_IOS_PROJECT_ID',
              _iosProjectId,
              overrides,
            ),
            'FIREBASE_IOS_BUNDLE_ID': _valueFor(
              'FIREBASE_IOS_BUNDLE_ID',
              _iosBundleId,
              overrides,
            ),
          },
        );
        return FirebaseOptions(
          apiKey: _valueFor('FIREBASE_IOS_API_KEY', _iosApiKey, overrides),
          appId: _valueFor('FIREBASE_IOS_APP_ID', _iosAppId, overrides),
          messagingSenderId: _valueFor(
            'FIREBASE_IOS_MESSAGING_SENDER_ID',
            _iosMessagingSenderId,
            overrides,
          ),
          projectId: _valueFor(
            'FIREBASE_IOS_PROJECT_ID',
            _iosProjectId,
            overrides,
          ),
          storageBucket: _optionalValue(
            'FIREBASE_IOS_STORAGE_BUCKET',
            _iosStorageBucket,
            overrides,
          ),
          iosBundleId: _optionalValue(
            'FIREBASE_IOS_BUNDLE_ID',
            _iosBundleId,
            overrides,
          ),
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'AppFirebaseOptions are not configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'AppFirebaseOptions are not configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'AppFirebaseOptions are not configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'AppFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static String _valueFor(
    String key,
    String defaultValue,
    Map<String, String>? overrides,
  ) {
    return overrides?[key] ?? defaultValue;
  }

  static String? _optionalValue(
    String key,
    String defaultValue,
    Map<String, String>? overrides,
  ) {
    final value = _valueFor(key, defaultValue, overrides).trim();
    return value.isEmpty ? null : value;
  }

  static void _validateRequiredKeys({
    required String platformLabel,
    required Map<String, String> values,
  }) {
    final missingKeys = values.entries
        .where((entry) => entry.value.trim().isEmpty)
        .map((entry) => entry.key)
        .toList(growable: false);
    if (missingKeys.isEmpty) return;

    throw StateError(
      'Missing required Firebase env keys for $platformLabel: '
      '${missingKeys.join(', ')}. '
      'Pass them with --dart-define or --dart-define-from-file.',
    );
  }
}
