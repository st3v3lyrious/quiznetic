import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/crash_reporting_service.dart';

void main() {
  group('CrashReportingService', () {
    test(
      'initialize enables collection and forwards Flutter fatal errors',
      () async {
        bool? collectionEnabled;
        FlutterErrorDetails? capturedFlutterError;
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (_) {};
        addTearDown(() {
          FlutterError.onError = previousOnError;
        });

        final service = CrashReportingService(
          enabled: true,
          setCollectionEnabled: (enabled) async {
            collectionEnabled = enabled;
          },
          recordError: (error, stackTrace, {fatal = false}) async {},
          recordFlutterFatalError: (details) {
            capturedFlutterError = details;
          },
        );

        await service.initialize();

        expect(collectionEnabled, isTrue);

        final details = FlutterErrorDetails(
          exception: Exception('framework-boom'),
          stack: StackTrace.current,
        );
        FlutterError.onError?.call(details);

        expect(capturedFlutterError, isNotNull);
        expect(
          capturedFlutterError!.exceptionAsString(),
          contains('framework-boom'),
        );
      },
    );

    test(
      'initialize leaves FlutterError handler unchanged when disabled',
      () async {
        final originalHandler = FlutterError.onError;
        var originalHandlerCalled = false;
        FlutterError.onError = (_) {
          originalHandlerCalled = true;
        };

        addTearDown(() {
          FlutterError.onError = originalHandler;
        });

        bool? collectionEnabled;
        final service = CrashReportingService(
          enabled: false,
          setCollectionEnabled: (enabled) async {
            collectionEnabled = enabled;
          },
          recordError: (error, stackTrace, {fatal = false}) async {},
          recordFlutterFatalError: (_) {},
        );

        await service.initialize();
        expect(collectionEnabled, isFalse);

        final details = FlutterErrorDetails(exception: Exception('no-rewire'));
        FlutterError.onError?.call(details);
        expect(originalHandlerCalled, isTrue);
      },
    );

    test('recordUnhandledError no-ops when disabled', () async {
      var didRecord = false;
      final service = CrashReportingService(
        enabled: false,
        setCollectionEnabled: (_) async {},
        recordError: (error, stackTrace, {fatal = false}) async {
          didRecord = true;
        },
        recordFlutterFatalError: (_) {},
      );

      await service.recordUnhandledError(
        Exception('zone-boom'),
        StackTrace.current,
        fatal: true,
      );

      expect(didRecord, isFalse);
    });

    test('recordUnhandledError writes fatal errors when enabled', () async {
      Object? recordedError;
      StackTrace? recordedStack;
      bool? recordedFatal;
      final service = CrashReportingService(
        enabled: true,
        setCollectionEnabled: (_) async {},
        recordError: (error, stackTrace, {fatal = false}) async {
          recordedError = error;
          recordedStack = stackTrace;
          recordedFatal = fatal;
        },
        recordFlutterFatalError: (_) {},
      );

      final error = Exception('fatal-zone-error');
      final stackTrace = StackTrace.current;
      await service.recordUnhandledError(error, stackTrace, fatal: true);

      expect(recordedError, same(error));
      expect(recordedStack, same(stackTrace));
      expect(recordedFatal, isTrue);
    });
  });
}
