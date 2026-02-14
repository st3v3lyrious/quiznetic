/*
 DOC: Config
 Title: Brand Config
 Purpose: Centralizes editable app branding tokens for colors and display naming.
*/
import 'package:flutter/material.dart';

class BrandConfig {
  static const appName = 'QuizNetic';
  static const tagline = 'Train your world trivia reflexes.';
  static const supportEmail = 'support@quiznetic.app';
  static const appVersionLabel = '1.0.0+1';
  static const logoSemanticLabel = 'QuizNetic logo';
  static const quizQuestionImageSemanticLabel = 'Quiz question image';

  // Update these tokens when final brand colors are ready.
  static const seedColor = Color(0xFF6A1B9A);
  static const correctAnswerColor = Color(0xFF2E7D32);
  static const wrongAnswerColor = Color(0xFFC62828);
  static const neutralSurfaceColor = Color(0xFFE0E0E0);
  static const webThemeColorHex = '#6A1B9A';
  static const webBackgroundColorHex = '#FFFFFF';
}
