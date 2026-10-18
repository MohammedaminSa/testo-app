/// A single message in an AI tutor conversation.
///
/// `role` is either `user` or `assistant`. Messages are persisted in the
/// `chat_messages` table so a conversation survives an app restart.
class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
