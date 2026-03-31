import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/storage/secure_storage.dart';
import 'package:orbit_app/features/ai_assistant/data/models/ai_action_model.dart';
import 'package:orbit_app/features/ai_assistant/data/models/chat_message_model.dart';
import 'package:orbit_app/features/ai_assistant/data/repositories/ai_assistant_repository.dart';
import 'package:orbit_app/features/ai_assistant/domain/ai_action_executor.dart';
import 'package:orbit_app/shared/widgets/ai_completion_overlay.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CHAT STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Whether the assistant is currently streaming a response.
final isStreamingProvider = StateProvider<bool>((ref) => false);

/// Whether the RAG datasource has been initialized.
final ragInitializedProvider = StateProvider<bool>((ref) => false);

/// Tracks how many messages a guest user has sent.
final guestMessageCountProvider = StateProvider<int>((ref) => 0);

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
  FutureOr<List<ChatMessageModel>> build() async {
    final storage = ref.read(secureStorageProvider);
    if (await storage.isGuestMode()) {
      return [
        ChatMessageModel(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          content: 'مرحباً بك في مساعد Corbit الذكي! 👋\n\n'
              'أنا مساعدك الشخصي في تطبيق Corbit، وأقدر أساعدك بأشياء كثيرة:\n\n'
              '• **التنقل في التطبيق** - قول لي "وديني للإعدادات" أو أي صفحة تبيها\n'
              '• **إنشاء مجموعات** - قول "سوي لي مجموعة" وبسويها لك\n'
              '• **إضافة جهات اتصال** - أقدر أضيف جهات اتصالك لأي مجموعة\n'
              '• **الإجابة على أسئلتك** - عن خدمات Corbit وطريقة استخدام التطبيق\n\n'
              'جرّب تكلمني وشوف كيف أشتغل! عندك **5 رسائل** تجريبية.',
          timestamp: DateTime.now(),
        ),
      ];
    }
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
      print('[AI] RAG init error: $e');
    }
  }

  /// Injects any pending completion messages into chat history.
  ///
  /// Called when the chat screen opens so the user sees what the AI did
  /// while they were on other pages.
  void injectCompletionMessages() {
    final history = ref.read(aiCompletionHistoryProvider);
    if (history.isEmpty) return;

    final currentMessages = state.valueOrNull ?? [];
    final newMessages = <ChatMessageModel>[];

    for (final entry in history) {
      final message = entry['message'] as String;
      final isSuccess = entry['isSuccess'] as bool? ?? true;
      final timestamp = entry['timestamp'] as DateTime;
      final emoji = isSuccess ? '🎉' : '⚠️';
      final footer = isSuccess
          ? 'أي شيء تبيه قولي بس وأبشر بسعدك!'
          : 'جرب مرة ثانية أو تواصل مع الدعم';
      newMessages.add(ChatMessageModel(
        id: 'completion_${timestamp.millisecondsSinceEpoch}',
        role: 'assistant',
        content: '$emoji **$message**\n\n$footer',
        timestamp: timestamp,
      ));
    }

    if (newMessages.isNotEmpty) {
      state = AsyncData([...currentMessages, ...newMessages]);
      // Clear the history after injecting
      ref.read(aiCompletionHistoryProvider.notifier).state = [];
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

    // Guest mode: check message limit
    final storage = ref.read(secureStorageProvider);
    final isGuest = await storage.isGuestMode();
    if (isGuest) {
      final count = ref.read(guestMessageCountProvider);
      if (count >= 5) {
        // Show farewell message
        final currentMessages = state.valueOrNull ?? [];
        final userMessage = ChatMessageModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          role: 'user',
          content: trimmed,
          timestamp: DateTime.now(),
        );
        final farewellMessage = ChatMessageModel(
          id: 'farewell_${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          content: 'شكراً لتجربتك مساعد Corbit الذكي! 🌟\n\n'
              'أتمنى إن التجربة عجبتك وشفت كيف أقدر أساعدك في إدارة رسائلك ومجموعاتك.\n\n'
              'للاستمتاع بكامل المزايا بدون حدود، سجّل حسابك في Corbit وابدأ رحلتك معنا.\n\n'
              'أشوفك قريب! 💙',
          timestamp: DateTime.now(),
        );
        state = AsyncData([...currentMessages, userMessage, farewellMessage]);
        return;
      }
      // Increment counter
      ref.read(guestMessageCountProvider.notifier).state = count + 1;
    }

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

      // Separate auto-execute from display-only actions
      final autoActions =
          actions.where((a) => a.type != 'suggest_link').toList();
      final chipActions =
          actions.where((a) => a.type == 'suggest_link').toList();

      // Update message first (show the text to user)
      _updateAssistantMessage(assistantId, fullResponse, actions: chipActions);

      // Then auto-execute actions (will navigate away from chat)
      if (autoActions.isNotEmpty) {
        // Small delay so user can read the response
        await Future.delayed(const Duration(milliseconds: 1200));
        final executor = ref.read(aiActionExecutorProvider);
        for (final action in autoActions) {
          await executor.execute(action);
        }
      }
    } catch (e) {
      print('[AI] Chat error: $e');
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
