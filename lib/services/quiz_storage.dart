import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// A quiz attempt that was interrupted before finishing. Persisted locally
/// so the user can resume after the app is killed mid-attempt.
class InProgressQuiz {
  final List<Question> paper;
  final int currentIndex;
  final List<SubmittedAnswer> answers;
  final int? timeLimitSeconds;

  const InProgressQuiz({
    required this.paper,
    required this.currentIndex,
    required this.answers,
    this.timeLimitSeconds,
  });
}

/// Persists an in-progress quiz to device storage (shared_preferences).
/// One entry per quiz id, so only the most recent attempt can be resumed.
class QuizStorage {
  static String _key(String quizId) => 'in_progress_quiz_$quizId';

  static Future<void> save({
    required String quizId,
    required List<Question> paper,
    required int currentIndex,
    required List<SubmittedAnswer> answers,
    int? timeLimitSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(quizId),
      jsonEncode({
        'paper': paper.map((q) => q.toMap()).toList(),
        'current_index': currentIndex,
        'answers': answers.map((a) => a.toMap()).toList(),
        'time_limit_seconds': timeLimitSeconds,
      }),
    );
  }

  static Future<InProgressQuiz?> load(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(quizId));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final paper = ((map['paper'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Question.fromMap)
          .toList();
      if (paper.isEmpty) return null;
      return InProgressQuiz(
        paper: paper,
        currentIndex: map['current_index'] as int? ?? 0,
        answers: ((map['answers'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(SubmittedAnswer.fromMap)
            .toList(),
        timeLimitSeconds: map['time_limit_seconds'] as int?,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(quizId));
  }
}
