class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String topic;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.topic,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    final optionRows =
        ((map['options'] as List?) ?? const []).cast<Map<String, dynamic>>();
    optionRows
        .sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    return Question(
      id: map['id'] as String? ?? '',
      text: map['text'] as String,
      options: optionRows.map((o) => o['text'] as String).toList(),
      correctIndex: optionRows.indexWhere((o) => o['is_correct'] == true),
      explanation: map['explanation'] as String? ?? '',
      topic: map['topic'] as String? ?? 'General',
    );
  }

  /// Serializes back to a DB-shaped map so a paper can be persisted
  /// (resume) and rebuilt with [Question.fromMap].
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'options': [
        for (var i = 0; i < options.length; i++)
          {
            'position': i + 1,
            'text': options[i],
            'is_correct': i == correctIndex,
          },
      ],
      'explanation': explanation,
      'topic': topic,
    };
  }
}

class Quiz {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final List<String> tags;
  final int? timeLimitSeconds;
  final int? paperSize;
  final List<Question> questions;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    this.category = 'General',
    this.difficulty = 'Beginner',
    this.tags = const [],
    this.timeLimitSeconds,
    this.paperSize,
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
      category: map['category'] as String? ?? 'General',
      difficulty: map['difficulty'] as String? ?? 'Beginner',
      tags: ((map['tags'] as List?) ?? const []).cast<String>(),
      timeLimitSeconds: map['time_limit_seconds'] as int?,
      paperSize: map['paper_size'] as int?,
      questions: questionRows.map(Question.fromMap).toList(),
    );
  }

  /// Serializes back to a DB-shaped map so a quiz list can be cached
  /// offline and rebuilt with [Quiz.fromMap].
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'tags': tags,
      'time_limit_seconds': timeLimitSeconds,
      'paper_size': paperSize,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }
}

class Profile {
  final String id;
  final String displayName;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.displayName,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      displayName: map['display_name'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// One question's result within an attempt: what the user picked vs the
/// correct answer. Powers the review screen and weak-area tracking.
class QuestionAnswer {
  final String questionId;
  final String questionText;
  final String topic;
  final int? selectedIndex;
  final int correctIndex;
  final String selectedText;
  final String correctText;
  final bool isCorrect;
  final String explanation;

  const QuestionAnswer({
    required this.questionId,
    required this.questionText,
    required this.topic,
    required this.selectedIndex,
    required this.correctIndex,
    required this.selectedText,
    required this.correctText,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuestionAnswer.fromMap(Map<String, dynamic> map) {
    return QuestionAnswer(
      questionId: map['question_id'] as String? ?? '',
      questionText: map['question_text'] as String? ?? '',
      topic: map['topic'] as String? ?? 'General',
      selectedIndex: map['selected_index'] as int?,
      correctIndex: map['correct_index'] as int? ?? 0,
      selectedText: map['selected_text'] as String? ?? '',
      correctText: map['correct_text'] as String? ?? '',
      isCorrect: map['is_correct'] == true,
      explanation: map['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'topic': topic,
      'selected_index': selectedIndex,
      'correct_index': correctIndex,
      'selected_text': selectedText,
      'correct_text': correctText,
      'is_correct': isCorrect,
      'explanation': explanation,
    };
  }
}

/// Everything QuizScreen returns when an attempt ends.
class QuizResult {
  final int correctCount;
  final int totalQuestions;
  final double scorePercent;
  final List<String> questionsOrder;
  final List<QuestionAnswer> answers;

  const QuizResult({
    required this.correctCount,
    required this.totalQuestions,
    required this.scorePercent,
    required this.questionsOrder,
    required this.answers,
  });
}

class QuizAttempt {
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final List<String> questionsOrder;
  final List<QuestionAnswer> answers;
  final DateTime completedAt;

  const QuizAttempt({
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    this.questionsOrder = const [],
    this.answers = const [],
    required this.completedAt,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      quizId: map['quiz_id'] as String? ?? '',
      quizTitle: map['quiz_title'] as String? ?? 'Quiz',
      totalQuestions: map['total_questions'] as int? ?? 0,
      correctAnswers: map['correct_answers'] as int? ?? 0,
      scorePercent: (map['score_percent'] as num?)?.toDouble() ?? 0,
      questionsOrder: ((map['questions_order'] as List?) ?? const [])
          .cast<String>(),
      answers: ((map['answers'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(QuestionAnswer.fromMap)
          .toList(),
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
      'questions_order': questionsOrder,
      'answers': answers.map((a) => a.toMap()).toList(),
      'completed_at': completedAt.toUtc().toIso8601String(),
    };
  }
}
