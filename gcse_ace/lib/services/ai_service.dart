import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';

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
        'studentAnswer': studentAnswer,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to get explanation: ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    return data['explanation'] as String? ?? 'No explanation available.';
  }

  /// The current user's saved conversation, oldest first.
  Future<List<ChatMessage>> getChatHistory(String userId) async {
    final data = await _client
        .from('chat_messages')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    return (data as List).map((json) => ChatMessage.fromJson(json)).toList();
  }

  /// Deletes the current user's saved conversation.
  Future<void> deleteChatHistory(String userId) async {
    await _client.from('chat_messages').delete().eq('user_id', userId);
  }

  /// Sends [content] to the `chat` edge function, persisting both the user's
  /// message and the assistant's reply.
  ///
  /// [history] is the prior conversation used to give the model context. It is
  /// capped on the server so very long chats stay within token limits.
  Future<String> sendChatMessage({
    required String userId,
    required String content,
    List<ChatMessage> history = const [],
  }) async {
    final historyPayload = history
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    await _client.from('chat_messages').insert({
      'user_id': userId,
      'role': 'user',
      'content': content,
    });

    final response = await _client.functions.invoke(
      'chat',
      body: {
        'messages': [
          ...historyPayload,
          {'role': 'user', 'content': content},
        ],
      },
    );

    if (response.status != 200) {
      throw Exception('Chat request failed: ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    final reply = data['reply'] as String? ?? 'Sorry, I could not answer that.';

    await _client.from('chat_messages').insert({
      'user_id': userId,
      'role': 'assistant',
      'content': reply,
    });

    return reply;
  }
}
