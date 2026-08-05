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
