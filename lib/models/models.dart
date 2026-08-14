class Question {
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const Question({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    final optionRows =
        ((map['options'] as List?) ?? const []).cast<Map<String, dynamic>>();
    optionRows
        .sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    return Question(
      text: map['text'] as String,
      options: optionRows.map((o) => o['text'] as String).toList(),
      correctIndex: optionRows.indexWhere((o) => o['is_correct'] == true),
      explanation: map['explanation'] as String? ?? '',
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    final questionRows =
        ((map['questions'] as List?) ?? const []).cast<Map<String, dynamic>>();
    questionRows
        .sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    return Quiz(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      questions: questionRows.map(Question.fromMap).toList(),
    );
  }
}

class QuizAttempt {
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final DateTime completedAt;

  const QuizAttempt({
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    required this.completedAt,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      quizId: map['quiz_id'] as String? ?? '',
      quizTitle: map['quiz_title'] as String? ?? 'Quiz',
      totalQuestions: map['total_questions'] as int? ?? 0,
      correctAnswers: map['correct_answers'] as int? ?? 0,
      scorePercent: (map['score_percent'] as num?)?.toDouble() ?? 0,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quiz_id': quizId,
      'quiz_title': quizTitle,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'score_percent': scorePercent,
      'completed_at': completedAt.toUtc().toIso8601String(),
    };
  }
}
