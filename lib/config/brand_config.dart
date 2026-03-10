/*
 DOC: Config
 Title: Brand Config
 Purpose: Centralizes editable app branding tokens for colors and display naming.
*/
import 'package:flutter/material.dart';

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
  static const appVersionLabel = '1.0.0+1';
  static const logoSemanticLabel = 'Quiznetic logo';
  static const quizQuestionImageSemanticLabel = 'Quiz question image';

  // Current active theme tokens (kept stable until full EIRENYA rollout).
  static const seedColor = Color(0xFF4A596D);
  static const correctAnswerColor = Color(0xFF2E7D32);
  static const wrongAnswerColor = Color(0xFFC62828);
  static const neutralSurfaceColor = Color(0xFFDBDEE2);
  static const appBackgroundColor = Color(0xFFF3F4F5);
  static const webThemeColorHex = '#4A596D';
  static const webBackgroundColorHex = '#F3F4F5';

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
