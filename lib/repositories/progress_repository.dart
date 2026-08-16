import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Reads/writes quiz attempts for the signed-in user.
class ProgressRepository {
  final SupabaseClient _client;

  const ProgressRepository(this._client);

  Future<void> saveAttempt(QuizAttempt attempt) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    await _client.from('quiz_attempts').insert({
      'user_id': user.id,
      ...attempt.toMap(),
    });
  }

  Future<List<QuizAttempt>> fetchAttempts({int limit = 100}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('quiz_attempts')
        .select()
        .eq('user_id', user.id)
        .order('completed_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((row) => QuizAttempt.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Pure aggregation over an attempt list: averages, best score, and the
  /// topics with the most wrong answers (weak-area tracking).
  static Map<String, dynamic> computeStats(List<QuizAttempt> attempts) {
    final totalAttempts = attempts.length;
    if (totalAttempts == 0) {
      return {
        'totalAttempts': 0,
        'avgScore': 0.0,
        'bestScore': 0.0,
        'totalCorrect': 0,
        'totalAnswered': 0,
        'quizzesTaken': 0,
        'weakTopics': <String>[],
        'weakTopicCount': 0,
      };
    }

    final totalCorrect =
        attempts.fold<int>(0, (sum, a) => sum + a.correctAnswers);
    final totalAnswered =
        attempts.fold<int>(0, (sum, a) => sum + a.totalQuestions);
    final best = attempts
        .map((a) => a.scorePercent)
        .reduce((a, b) => a > b ? a : b);
    final avg = attempts.map((a) => a.scorePercent).reduce((a, b) => a + b) /
        totalAttempts;
    final quizzesTaken = attempts.map((a) => a.quizId).toSet().length;

    // Weak-area tracking: topics with the most wrong answers across history.
    final topicMisses = <String, int>{};
    for (final a in attempts) {
      for (final ans in a.answers) {
        if (!ans.isCorrect && ans.topic.isNotEmpty) {
          topicMisses[ans.topic] = (topicMisses[ans.topic] ?? 0) + 1;
        }
      }
    }
    final weakTopics = topicMisses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalWrong = weakTopics.fold<int>(0, (sum, e) => sum + e.value);

    return {
      'totalAttempts': totalAttempts,
      'avgScore': avg,
      'bestScore': best,
      'totalCorrect': totalCorrect,
      'totalAnswered': totalAnswered,
      'quizzesTaken': quizzesTaken,
      'weakTopics': weakTopics.map((e) => e.key).take(5).toList(),
      'weakTopicCount': totalWrong,
    };
  }
}