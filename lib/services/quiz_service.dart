import '../core/config.dart';
import '../models/models.dart';

class QuizService {
  Future<List<Quiz>> fetchQuizzes() async {
    final data = await supabase
        .from('quizzes')
        .select('*, questions(*, options(*))')
        .order('id');

    return (data as List)
        .map((row) => Quiz.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}