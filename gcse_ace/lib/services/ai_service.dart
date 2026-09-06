import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> getExplanation({
    required String question,
    required String correctAnswer,
    String? studentAnswer,
  }) async {
    final response = await _client.functions.invoke(
      'explain-question',
      body: {
        'question': question,
        'correctAnswer': correctAnswer,
        'studentAnswer?': studentAnswer,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to get explanation: ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    return data['explanation'] as String? ?? 'No explanation available.';
  }
}
