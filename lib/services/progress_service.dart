import '../core/config.dart';
import '../models/models.dart';

class ProgressService {
  static const String _table = 'quiz_attempts';

  Future<void> saveAttempt(QuizAttempt attempt) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    await supabase.from(_table).insert({
      'user_id': user.id,
      ...attempt.toMap(),
    });
  }

  Future<List<QuizAttempt>> fetchAttempts({int limit = 100}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final data = await supabase
        .from(_table)
        .select()
        .eq('user_id', user.id)
        .order('completed_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((row) => QuizAttempt.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> fetchStats(List<QuizAttempt> attempts) async {
    final totalAttempts = attempts.length;
    if (totalAttempts == 0) {
      return {
        'totalAttempts': 0,
        'avgScore': 0.0,
        'bestScore': 0.0,
        'totalCorrect': 0,
        'totalAnswered': 0,
        'quizzesTaken': 0,
      };
    }

    final totalCorrect =
        attempts.fold<int>(0, (sum, a) => sum + a.correctAnswers);
    final totalAnswered =
        attempts.fold<int>(0, (sum, a) => sum + a.totalQuestions);
    final best = attempts
        .map((a) => a.scorePercent)
        .reduce((a, b) => a > b ? a : b);
    final avg = attempts
            .map((a) => a.scorePercent)
            .reduce((a, b) => a + b) /
        totalAttempts;
    final quizzesTaken = attempts.map((a) => a.quizId).toSet().length;

    return {
      'totalAttempts': totalAttempts,
      'avgScore': avg,
      'bestScore': best,
      'totalCorrect': totalCorrect,
      'totalAnswered': totalAnswered,
      'quizzesTaken': quizzesTaken,
    };
  }
}
