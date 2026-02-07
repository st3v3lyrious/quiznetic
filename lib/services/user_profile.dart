/*
 DOC: Service
 Title: User Profile
 Purpose: Stores and retrieves local profile/high-score preferences.
*/
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  /// Returns the stored high score for [categoryKey], or 0 if none.
  static Future<int> getHighScore(String categoryKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('highscore_$categoryKey') ?? 0;
  }

  /// Saves [score] as the new high score for [categoryKey].
  /// It will only store if [score] is higher than the existing value.
  static Future<void> setHighScore(String categoryKey, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getInt('highscore_$categoryKey') ?? 0;
    if (score > old) {
      await prefs.setInt('highscore_$categoryKey', score);
    }
  }
}
