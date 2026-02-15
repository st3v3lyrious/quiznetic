/*
 DOC: Service
 Title: Analytics Service
 Purpose: Configures Firebase Analytics and logs core product events/screen views.
*/
import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:quiznetic_flutter/config/app_config.dart';

typedef AnalyticsSetCollectionEnabled = Future<void> Function(bool enabled);
typedef AnalyticsLogEvent =
    Future<void> Function({
      required String name,
      Map<String, Object>? parameters,
    });
typedef AnalyticsLogScreenView =
    Future<void> Function({String? screenName, String? screenClass});
typedef CrashBreadcrumbLogger = void Function(String message);

class AnalyticsService {
  AnalyticsService({
    bool? enabled,
    AnalyticsSetCollectionEnabled? setCollectionEnabled,
    AnalyticsLogEvent? logEvent,
    AnalyticsLogScreenView? logScreenView,
    CrashBreadcrumbLogger? logCrashBreadcrumb,
  }) : _enabled = enabled ?? AppConfig.enableAnalytics,
       _setCollectionEnabled =
           setCollectionEnabled ?? _defaultSetCollectionEnabled,
       _logEvent = logEvent ?? _defaultLogEvent,
       _logScreenView = logScreenView ?? _defaultLogScreenView,
       _logCrashBreadcrumb = logCrashBreadcrumb ?? _defaultLogCrashBreadcrumb;

  static final AnalyticsService instance = AnalyticsService();

  final bool _enabled;
  final AnalyticsSetCollectionEnabled _setCollectionEnabled;
  final AnalyticsLogEvent _logEvent;
  final AnalyticsLogScreenView _logScreenView;
  final CrashBreadcrumbLogger _logCrashBreadcrumb;

  static Future<void> _defaultSetCollectionEnabled(bool enabled) {
    return FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  }

  static Future<void> _defaultLogEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    return FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  static Future<void> _defaultLogScreenView({
    String? screenName,
    String? screenClass,
  }) {
    return FirebaseAnalytics.instance.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  static void _defaultLogCrashBreadcrumb(String message) {
    FirebaseCrashlytics.instance.log(message);
  }

  /// Configures collection toggle for Analytics.
  Future<void> initialize() async {
    try {
      await _setCollectionEnabled(_enabled);
    } catch (e, stackTrace) {
      debugPrint('Analytics initialize failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Logs a product event and mirrors it as a Crashlytics breadcrumb.
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
    bool includeCrashBreadcrumb = true,
  }) async {
    if (!_enabled) return;

    final normalizedName = _normalizeToken(
      name,
      fallback: 'unknown_event',
      maxLength: 40,
    );
    final normalizedParams = _normalizeParameters(parameters);

    try {
      await _logEvent(
        name: normalizedName,
        parameters: normalizedParams.isEmpty ? null : normalizedParams,
      );
      if (includeCrashBreadcrumb) {
        _logCrashBreadcrumb('analytics:$normalizedName');
      }
    } catch (e, stackTrace) {
      debugPrint('Analytics logEvent failed for "$normalizedName": $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Logs a screen view and mirrors it as a Crashlytics breadcrumb.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_enabled) return;

    final normalizedScreenName = _normalizeToken(
      screenName,
      fallback: 'unknown_screen',
      maxLength: 100,
    );
    final normalizedScreenClass = _normalizeToken(
      screenClass ?? normalizedScreenName,
      fallback: normalizedScreenName,
      maxLength: 100,
    );

    try {
      await _logScreenView(
        screenName: normalizedScreenName,
        screenClass: normalizedScreenClass,
      );
      _logCrashBreadcrumb('screen_view:$normalizedScreenName');
    } catch (e, stackTrace) {
      debugPrint(
        'Analytics logScreenView failed for "$normalizedScreenName": $e',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Map<String, Object> _normalizeParameters(Map<String, Object?>? raw) {
    if (raw == null || raw.isEmpty) return const {};

    final normalized = <String, Object>{};
    for (final entry in raw.entries) {
      final key = _normalizeToken(entry.key, fallback: 'param', maxLength: 40);
      final value = entry.value;
      if (value == null) continue;
      if (value is num) {
        normalized[key] = value;
        continue;
      }
      if (value is bool) {
        normalized[key] = value ? 1 : 0;
        continue;
      }
      final asString = value.toString();
      normalized[key] = asString.length > 100
          ? asString.substring(0, 100)
          : asString;
    }

    return normalized;
  }

  static String _normalizeToken(
    String raw, {
    required String fallback,
    required int maxLength,
  }) {
    final cleaned = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final withPrefix = cleaned.isEmpty
        ? fallback
        : RegExp(r'^[a-z]').hasMatch(cleaned)
        ? cleaned
        : 'x_$cleaned';

    if (withPrefix.length <= maxLength) return withPrefix;
    return withPrefix.substring(0, maxLength);
  }
}

class AnalyticsNavigationObserver extends NavigatorObserver {
  AnalyticsNavigationObserver({AnalyticsService? analyticsService})
    : _analyticsService = analyticsService ?? AnalyticsService.instance;

  final AnalyticsService _analyticsService;
  String? _lastTrackedRouteName;

  void _track(Route<dynamic>? route) {
    final rawName = route?.settings.name;
    if (rawName == null || rawName.trim().isEmpty) return;
    if (rawName == _lastTrackedRouteName) return;

    _lastTrackedRouteName = rawName;
    unawaited(
      _analyticsService.logScreenView(
        screenName: rawName,
        screenClass: route.runtimeType.toString(),
      ),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _track(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _track(newRoute);
  }
}
