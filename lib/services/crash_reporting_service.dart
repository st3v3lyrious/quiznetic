/*
 DOC: Service
 Title: Crash Reporting Service
 Purpose: Configures and records runtime crashes via Firebase Crashlytics.
*/
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:quiznetic_flutter/config/app_config.dart';

typedef CrashSetCollectionEnabled = Future<void> Function(bool enabled);
typedef CrashRecordError =
    Future<void> Function(Object error, StackTrace stackTrace, {bool fatal});
typedef CrashRecordFlutterFatalError =
    void Function(FlutterErrorDetails details);

class CrashReportingService {
  CrashReportingService({
    bool? enabled,
    CrashSetCollectionEnabled? setCollectionEnabled,
    CrashRecordError? recordError,
    CrashRecordFlutterFatalError? recordFlutterFatalError,
  }) : _enabled = enabled ?? AppConfig.enableCrashReporting,
       _setCollectionEnabled =
           setCollectionEnabled ??
           FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled,
       _recordError = recordError ?? FirebaseCrashlytics.instance.recordError,
       _recordFlutterFatalError =
           recordFlutterFatalError ??
           FirebaseCrashlytics.instance.recordFlutterFatalError;

  final bool _enabled;
  final CrashSetCollectionEnabled _setCollectionEnabled;
  final CrashRecordError _recordError;
  final CrashRecordFlutterFatalError _recordFlutterFatalError;

  /// Configures Crashlytics collection and Flutter framework error handling.
  Future<void> initialize() async {
    await _setCollectionEnabled(_enabled);
    if (!_enabled) return;

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _recordFlutterFatalError(details);
      previousOnError?.call(details);
    };
  }

  /// Records an unhandled error (zone/platform level) as fatal by default.
  Future<void> recordUnhandledError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = true,
  }) async {
    if (!_enabled) {
      debugPrint('Unhandled error captured while crash reporting is disabled');
      return;
    }
    await _recordError(error, stackTrace, fatal: fatal);
  }
}
