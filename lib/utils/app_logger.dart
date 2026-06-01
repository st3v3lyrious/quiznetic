import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void d(String message) {
    if (kDebugMode) debugPrint(message);
  }

  static void stack(StackTrace? stackTrace) {
    if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
  }
}
