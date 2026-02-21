/*
 DOC: Service
 Title: Entitlement Service
 Purpose: Persists and exposes monetization entitlements (ex: remove ads).
*/
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef BoolValueLoader = Future<bool?> Function(String key);
typedef BoolValueSaver = Future<void> Function(String key, bool value);

class EntitlementService {
  EntitlementService({
    BoolValueLoader? loadBoolValue,
    BoolValueSaver? saveBoolValue,
    bool initialRemoveAds = false,
  }) : _loadBoolValue = loadBoolValue ?? _defaultLoadBoolValue,
       _saveBoolValue = saveBoolValue ?? _defaultSaveBoolValue,
       _hasRemoveAdsNotifier = ValueNotifier<bool>(initialRemoveAds);

  static final EntitlementService instance = EntitlementService();

  static const String removeAdsEntitlementKey = 'entitlement_remove_ads';

  final BoolValueLoader _loadBoolValue;
  final BoolValueSaver _saveBoolValue;
  final ValueNotifier<bool> _hasRemoveAdsNotifier;

  bool _initialized = false;

  static Future<bool?> _defaultLoadBoolValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static Future<void> _defaultSaveBoolValue(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  ValueListenable<bool> get hasRemoveAdsListenable => _hasRemoveAdsNotifier;

  bool get hasRemoveAds => _hasRemoveAdsNotifier.value;

  /// Loads persisted entitlement values into memory.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final persisted = await _loadBoolValue(removeAdsEntitlementKey);
      _hasRemoveAdsNotifier.value = persisted ?? false;
    } catch (e, stackTrace) {
      debugPrint('EntitlementService initialize failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _hasRemoveAdsNotifier.value = false;
    }
  }

  /// Persists and updates the remove-ads entitlement.
  Future<void> setRemoveAds(bool enabled) async {
    _hasRemoveAdsNotifier.value = enabled;
    try {
      await _saveBoolValue(removeAdsEntitlementKey, enabled);
    } catch (e, stackTrace) {
      debugPrint('EntitlementService setRemoveAds failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
