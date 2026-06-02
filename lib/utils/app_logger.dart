import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void d(String message) {
    if (kDebugMode) debugPrint(message);
  }

  // Always logs — use sparingly, only for errors that must be visible in
  // production device logs (e.g. unexpected Firestore failures).
  static void e(String message) {
    debugPrint('[ERROR] $message');
  }

  static void stack(StackTrace? stackTrace) {
    if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
  }
}
