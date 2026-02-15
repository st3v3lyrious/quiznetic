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
    visualDescription:
        'Three equal vertical bands with blue at the hoist, then white, then red.',
  ),
  FlagQuestion(
    imagePath: 'assets/flags/Japan.png',
    correctAnswer: 'Japan',
    options: ['China', 'South Korea', 'Japan', 'Thailand'],
    visualDescription:
        'White field with one centered red circle and no additional symbols.',
  ),
];
