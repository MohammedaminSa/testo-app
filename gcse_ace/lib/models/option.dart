class Option {
  final String id;
  final String questionId;
  final String letter;
  final String text;
  final bool isCorrect;

  const Option({
    required this.id,
    required this.questionId,
    required this.letter,
    required this.text,
    required this.isCorrect,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      letter: json['letter'] as String,
      text: json['text'] as String,
      isCorrect: json['is_correct'] as bool,
    );
  }
}
