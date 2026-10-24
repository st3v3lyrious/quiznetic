// Persists the browser's optional audience-measurement choice, separate from Auth.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'analytics_web/bridge.dart'
    if (dart.library.js_interop) 'analytics_web/bridge_web.dart'
    as web;

class AnalyticsConsent extends ChangeNotifier {
  AnalyticsConsent({
    AnalyticsService? analytics,
    DateTime Function()? now,
    VoidCallback? reload,
  }) : _analytics = analytics ?? AnalyticsService.instance,
       _now = now ?? DateTime.now,
       _reload = reload ?? web.reloadWithoutAnalytics;

  static final instance = AnalyticsConsent();
  static const choiceKey = 'analytics_consent_v1';
  static const timeKey = 'analytics_consent_v1_at';
  static const validity = Duration(days: 180);
  final AnalyticsService _analytics;
  final DateTime Function() _now;
  final VoidCallback _reload;
  bool? choice;
  bool busy = false;
  bool ready = false;
  String? error;

  /// An unavailable/corrupt/expired preference leaves collection disabled.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final at = prefs.getInt(timeKey);
      final elapsed = at == null
          ? null
          : _now().difference(DateTime.fromMillisecondsSinceEpoch(at));
      choice = elapsed != null && !elapsed.isNegative && elapsed < validity
          ? prefs.getBool(choiceKey)
          : null;
      await _analytics.setWebConsent(choice == true);
    } catch (_) {
      choice = null;
      await _analytics.setWebConsent(false);
    }
    ready = true;
    notifyListeners();
  }

  /// Reject first in memory; persist refusal before reloading an opted-in page.
  Future<void> choose(bool accepted) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    final withdrawing = choice == true && !accepted;
    try {
      if (!accepted) await _analytics.setWebConsent(false);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool(choiceKey, accepted) ||
          !await prefs.setInt(timeKey, _now().millisecondsSinceEpoch)) {
        throw StateError('Consent could not be saved');
      }
      if (accepted) await _analytics.setWebConsent(true);
      choice = accepted;
      if (withdrawing) _reload();
    } catch (_) {
      await _analytics.setWebConsent(false);
      choice = null;
      // A failed opt-in must never be restored on the next page load.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(choiceKey);
        await prefs.remove(timeKey);
      } catch (_) {
        /* Storage may be unavailable; collection stays disabled. */
      }
      error =
          'Unable to save your choice. Analytics remains off. Please try again.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
