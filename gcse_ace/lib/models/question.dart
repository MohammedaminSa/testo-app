class Question {
  final String id;
  final String paperId;
  final int orderNumber;
  final String text;
  final int marks;
  final String questionType;
  final String? correctAnswer;
  final String? explanation;

  const Question({
    required this.id,
    required this.paperId,
    required this.orderNumber,
    required this.text,
    required this.marks,
    required this.questionType,
    this.correctAnswer,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      paperId: json['paper_id'] as String,
      orderNumber: json['order_number'] as int,
      text: json['text'] as String,
      marks: json['marks'] as int,
      questionType: json['question_type'] as String,
      correctAnswer: json['correct_answer'] as String?,
      explanation: json['explanation'] as String?,
    );
  }
}
