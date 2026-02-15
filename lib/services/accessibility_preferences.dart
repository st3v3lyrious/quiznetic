/*
 DOC: Service
 Title: Accessibility Preferences
 Purpose: Persists local accessibility options used across screens.
*/
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityPreferences {
  static const String showFlagDescriptionsKey =
      'accessibility_show_flag_descriptions';

  /// Returns whether opt-in flag descriptions are enabled.
  static Future<bool> showFlagDescriptionsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(showFlagDescriptionsKey) ?? false;
  }

  /// Persists the opt-in flag description preference.
  static Future<void> setShowFlagDescriptionsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(showFlagDescriptionsKey, enabled);
  }
}
