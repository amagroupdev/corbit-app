import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/ai_assistant/data/models/ai_action_model.dart';
import 'package:orbit_app/features/ai_assistant/data/models/chat_message_model.dart';
import 'package:orbit_app/features/ai_assistant/data/repositories/ai_assistant_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CHAT STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Whether the assistant is currently streaming a response.
final isStreamingProvider = StateProvider<bool>((ref) => false);

/// Whether the RAG datasource has been initialized.
final ragInitializedProvider = StateProvider<bool>((ref) => false);

// ═══════════════════════════════════════════════════════════════════════════
// CHAT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

/// Manages the AI assistant chat conversation state.
///
/// Holds the list of [ChatMessageModel] messages and handles sending
/// user messages, streaming assistant responses, parsing actions,
/// and clearing the conversation.
class ChatNotifier extends AsyncNotifier<List<ChatMessageModel>> {
  @override
  FutureOr<List<ChatMessageModel>> build() {
    return [];
  }

  /// Initializes the RAG datasource and seeds the API key if needed.
  ///
  /// Should be called once when the chat screen opens.
  Future<void> initializeRag() async {
    final isInitialized = ref.read(ragInitializedProvider);
    if (isInitialized) return;

    try {
      final repo = ref.read(aiAssistantRepositoryProvider);
      await repo.ensureApiKey();
      await repo.initialize();
      ref.read(ragInitializedProvider.notifier).state = true;
    } catch (e) {
      // RAG init failure is non-fatal; chat can still work without context.
    }
  }

  /// Sends a user message and streams the assistant response.
  ///
  /// 1. Adds the user message to state immediately.
  /// 2. Adds an empty assistant message as a placeholder.
  /// 3. Streams tokens from the repository and updates the assistant message.
  /// 4. Parses ```action blocks from the final response.
  /// 5. On error, replaces the assistant message with an error notice.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final currentMessages = state.valueOrNull ?? [];

    // ── 1. Add user message ──────────────────────────────────────────────
    final userMessage = ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now(),
    );

    final assistantId = 'assistant_${DateTime.now().millisecondsSinceEpoch}';
    final assistantMessage = ChatMessageModel(
      id: assistantId,
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
    );

    state = AsyncData([...currentMessages, userMessage, assistantMessage]);

    // ── 2. Stream response from repository ───────────────────────────────
    ref.read(isStreamingProvider.notifier).state = true;

    try {
      final repo = ref.read(aiAssistantRepositoryProvider);
      final history = currentMessages; // history before this message

      final buffer = StringBuffer();
      final stream = repo.chat(trimmed, history);

      await for (final token in stream) {
        buffer.write(token);
        _updateAssistantMessage(assistantId, buffer.toString());
      }

      // ── 3. Parse actions from complete response ──────────────────────
      final fullResponse = buffer.toString();
      final actions = repo.parseActions(fullResponse);
      _updateAssistantMessage(assistantId, fullResponse, actions: actions);
    } catch (e) {
      _updateAssistantMessage(
        assistantId,
        '\u0639\u0630\u0631\u0627\u064b\u060c \u062d\u062f\u062b \u062e\u0637\u0623 \u0623\u062b\u0646\u0627\u0621 \u0645\u0639\u0627\u0644\u062c\u0629 \u0637\u0644\u0628\u0643. \u064a\u0631\u062c\u0649 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649.',
      );
    } finally {
      ref.read(isStreamingProvider.notifier).state = false;
    }
  }

  /// Clears the entire chat conversation.
  void clearChat() {
    state = const AsyncData([]);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Updates the content of the assistant message with the given [id].
  void _updateAssistantMessage(
    String id,
    String content, {
    List<AiActionModel>? actions,
  }) {
    final messages = state.valueOrNull ?? [];
    final updated = messages.map((m) {
      if (m.id == id) {
        return m.copyWith(
          content: content,
          actions: actions ?? m.actions,
        );
      }
      return m;
    }).toList();

    state = AsyncData(updated);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, List<ChatMessageModel>>(
  ChatNotifier.new,
);
