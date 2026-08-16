import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Loads quiz content (quizzes + questions + options) from Supabase.
class QuizRepository {
  final SupabaseClient _client;

  const QuizRepository(this._client);

  Future<List<Quiz>> fetchQuizzes() async {
    final data = await _client
        .from('quizzes')
        .select('*, questions(*, options(*))')
        .order('id');

    return (data as List)
        .map((row) => Quiz.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}