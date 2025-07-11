import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../models/flag_question.dart';

/// Loads every file under assets/flags/ and builds basic FlagQuestion objects.
/// 1) Read AssetManifest, filter for assets/flags/
/// 2) Build a “bare” FlagQuestion (no options yet)
Future<List<FlagQuestion>> loadAllFlags() async {
  // 1) Load the generated manifest
  final manifestJson = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = json.decode(manifestJson);

  // 2) Filter for your flags folder
  final flagPaths =
      manifestMap.keys
          .where((path) => path.startsWith('assets/flags/'))
          .toList();

  // 3) Build your questions
  return flagPaths.map((path) {
    // Derive the “country name” from the file name:
    // e.g. assets/flags/united_states.png → United States
    final fileName = path.split('/').last.split('.').first;
    final correctAnswer = fileName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    // For now, we’ll just set options = [correctAnswer] and fill in others later
    return FlagQuestion(
      imagePath: path,
      correctAnswer: correctAnswer,
      options: [], // you can randomize a few others from this list below
    );
  }).toList();
}

/// Given all flags, shuffle and build full quizzes with 4 options each.
List<FlagQuestion> prepareQuiz(List<FlagQuestion> all) {
  final rand = Random();
  final pool = List<FlagQuestion>.from(all)..shuffle(rand);

  return pool.map((q) {
    // pick 3 wrong answers
    final wrongs =
        all.where((f) => f.correctAnswer != q.correctAnswer).toList()
          ..shuffle(rand);

    final opts = <String>[
      q.correctAnswer,
      wrongs[0].correctAnswer,
      wrongs[1].correctAnswer,
      wrongs[2].correctAnswer,
    ]..shuffle(rand);

    return FlagQuestion(
      imagePath: q.imagePath,
      correctAnswer: q.correctAnswer,
      options: opts,
    );
  }).toList();
}
