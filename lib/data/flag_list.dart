/*
 DOC: DataSource
 Title: Flag List
 Purpose: Contains static sample flag question data.
*/
import '../models/flag_question.dart';

final List<FlagQuestion> flagQuestions = [
  FlagQuestion(
    imagePath: 'assets/flags/France.png',
    correctAnswer: 'France',
    options: ['France', 'Italy', 'Germany', 'Spain'],
  ),
  FlagQuestion(
    imagePath: 'assets/flags/Japan.png',
    correctAnswer: 'Japan',
    options: ['China', 'South Korea', 'Japan', 'Thailand'],
  ),
];
