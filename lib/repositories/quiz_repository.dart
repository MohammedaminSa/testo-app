import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Loads quiz content (quizzes + questions + options) from Supabase.
class QuizRepository {
  final SupabaseClient _client;

  const QuizRepository(this._client);

  /// Fetches the catalog via the `get_quizzes` RPC, which returns questions
  /// **without** the correct answer — grading happens server-side so answers
  /// can never be read from the API.
  Future<List<Quiz>> fetchQuizzes() async {
    final data = await _client.rpc('get_quizzes');

    return (data as List)
        .map((row) => Quiz.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}