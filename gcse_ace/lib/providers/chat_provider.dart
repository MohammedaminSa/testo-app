import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../services/ai_service.dart';
import 'auth_provider.dart';

/// State for the AI tutor conversation.
class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  /// The conversation, oldest first.
  final List<ChatMessage> messages;

  /// True while the saved history is being fetched.
  final bool isLoading;

  /// True while a message is in flight to the model.
  final bool isSending;

  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    Object? error = _unset,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  static const _unset = Object();
}

/// Drives the AI tutor: loads the saved conversation and sends new messages.
class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      // Defer until after build() returns: reading `state` during build throws.
      Future.microtask(() {
        if (ref.mounted) _loadHistory(user.id);
      });
      return const ChatState(isLoading: true);
    }
    return const ChatState();
  }

  Future<void> _loadHistory(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await AiService.instance.getChatHistory(userId);
      state = state.copyWith(messages: history, isLoading: false);
    } catch (e) {
      debugPrint('Chat history load failed: $e');
      state = state.copyWith(isLoading: false, error: 'Could not load the conversation.');
    }
  }

  /// Clears the conversation locally and on the server.
  Future<void> clear() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      try {
        await AiService.instance.deleteChatHistory(user.id);
      } catch (_) {
        // Clearing is best-effort; the local list still resets.
      }
    }
    state = const ChatState();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      state = state.copyWith(error: 'You must be signed in to chat.');
      return;
    }

    final userMessage = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );

    final priorMessages = List<ChatMessage>.from(state.messages);

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      error: null,
    );

    try {
      final reply = await AiService.instance.sendChatMessage(
        userId: user.id,
        content: trimmed,
        history: priorMessages,
      );
      final assistantMessage = ChatMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}-ai',
        role: 'assistant',
        content: reply,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isSending: false,
      );
    } catch (e) {
      debugPrint('Chat send failed: $e');
      state = state.copyWith(
        isSending: false,
        error: 'Could not reach the AI tutor. Please try again.',
      );
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
