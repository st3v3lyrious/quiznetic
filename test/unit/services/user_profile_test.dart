import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('returns 0 when no high score is stored', () async {
      SharedPreferences.setMockInitialValues({});

      final highScore = await UserProfile.getHighScore('flag');
      expect(highScore, equals(0));
    });

    test('stores a higher high score', () async {
      SharedPreferences.setMockInitialValues({'highscore_flag': 3});

      await UserProfile.setHighScore('flag', 8);
      final highScore = await UserProfile.getHighScore('flag');
      expect(highScore, equals(8));
    });

    test('does not overwrite with a lower score', () async {
      SharedPreferences.setMockInitialValues({'highscore_flag': 10});

      await UserProfile.setHighScore('flag', 4);
      final highScore = await UserProfile.getHighScore('flag');
      expect(highScore, equals(10));
    });
  });
}
