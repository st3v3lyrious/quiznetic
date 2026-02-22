/*
 DOC: Config
 Title: Brand Config
 Purpose: Centralizes editable app branding tokens for colors and display naming.
*/
import 'package:flutter/material.dart';

class BrandConfig {
  static const appName = 'QuizNetic';
  static const tagline = 'Train your world trivia reflexes.';
  static const supportEmail = 'quizneticapp@gmail.com';
  static const appVersionLabel = '1.0.0+1';
  static const logoSemanticLabel = 'QuizNetic logo';
  static const quizQuestionImageSemanticLabel = 'Quiz question image';

  // EIRENYA baseline extracted from the current brand logo palette.
  static const seedColor = Color(0xFF4A596D);
  static const correctAnswerColor = Color(0xFF2E7D32);
  static const wrongAnswerColor = Color(0xFFC62828);
  static const neutralSurfaceColor = Color(0xFFDBDEE2);
  static const appBackgroundColor = Color(0xFFF3F4F5);
  static const webThemeColorHex = '#4A596D';
  static const webBackgroundColorHex = '#F3F4F5';
}
