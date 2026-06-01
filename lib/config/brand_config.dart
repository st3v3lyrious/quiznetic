/*
 DOC: Config
 Title: Brand Config
 Purpose: Centralizes editable app branding tokens for colors and display naming.
*/
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class EirenyaPalette {
  EirenyaPalette._();

  // Source swatches from the provided EIRENYA palette reference.
  static const blueSerenity = Color(0xFF4A90E2); // Bleu Sérénité
  static const deepNightBlue = Color(0xFF001B2A); // Bleu Nuit Profond
  static const spiritualGold = Color(0xFFF5C542); // Doré Spirituel
  static const softLightYellow = Color(0xFFFFD87A); // Jaune Lumière Douce
  static const offWhite = Color(0xFFF9F9F6); // Blanc cassé
  static const linenBeige = Color(0xFFE6DDC6); // Beige Lin
  static const pearlGray = Color(0xFFD3D3D3); // Gris Perle
}

class BrandConfig {
  static const appName = 'Quiznetic';
  static const tagline = 'Train your world trivia reflexes.';
  static const supportEmail = 'quizneticapp@gmail.com';
  static const logoSemanticLabel = 'Quiznetic logo';
  static const quizQuestionImageSemanticLabel = 'Quiz question image';

  static String _appVersionLabel = '';
  static String get appVersionLabel => _appVersionLabel;

  static Future<void> initVersion() async {
    final info = await PackageInfo.fromPlatform();
    _appVersionLabel = '${info.version}+${info.buildNumber}';
  }

  // Active theme tokens for the current EIRENYA rollout.
  static const seedColor = EirenyaPalette.blueSerenity;
  static const correctAnswerColor = Color(0xFF2E7D32);
  static const wrongAnswerColor = Color(0xFFC62828);
  static const neutralSurfaceColor = EirenyaPalette.linenBeige;
  static const appBackgroundColor = EirenyaPalette.offWhite;
  static const webThemeColorHex = '#4A90E2';
  static const webBackgroundColorHex = '#F9F9F6';

  // Suggested semantic mapping for the upcoming EIRENYA visual refresh.
  static const eirenyaPrimary = EirenyaPalette.blueSerenity;
  static const eirenyaOnPrimary = Colors.white;
  static const eirenyaPrimaryDark = EirenyaPalette.deepNightBlue;
  static const eirenyaAccent = EirenyaPalette.spiritualGold;
  static const eirenyaAccentSoft = EirenyaPalette.softLightYellow;
  static const eirenyaBackground = EirenyaPalette.offWhite;
  static const eirenyaSurface = EirenyaPalette.linenBeige;
  static const eirenyaNeutral = EirenyaPalette.pearlGray;

  static const eirenyaPrimaryHex = '#4A90E2';
  static const eirenyaPrimaryDarkHex = '#001B2A';
  static const eirenyaAccentHex = '#F5C542';
  static const eirenyaAccentSoftHex = '#FFD87A';
  static const eirenyaBackgroundHex = '#F9F9F6';
  static const eirenyaSurfaceHex = '#E6DDC6';
  static const eirenyaNeutralHex = '#D3D3D3';
}
