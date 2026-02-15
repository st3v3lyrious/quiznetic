/*
 DOC: Model
 Title: Flag Question
 Purpose: Defines the data model for a single flag question.
*/
class FlagQuestion {
  final String imagePath;
  final String correctAnswer;
  final List<String> options;
  final String? visualDescription;

  FlagQuestion({
    required this.imagePath,
    required this.correctAnswer,
    required this.options,
    this.visualDescription,
  });
}
