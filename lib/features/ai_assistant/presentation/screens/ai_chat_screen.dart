import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/ai_assistant/data/models/ai_action_model.dart';
import 'package:orbit_app/features/ai_assistant/data/models/chat_message_model.dart';
import 'package:orbit_app/features/ai_assistant/presentation/controllers/chat_controller.dart';
import 'package:orbit_app/features/ai_assistant/presentation/widgets/ai_input_bar.dart';
import 'package:orbit_app/features/ai_assistant/presentation/widgets/ai_suggestion_chips.dart';
import 'package:orbit_app/features/ai_assistant/presentation/widgets/ai_typing_indicator.dart';
import 'package:orbit_app/features/ai_assistant/presentation/widgets/chat_bubble.dart';

/// Main AI Assistant chat screen with a WhatsApp-like design.
///
/// Displays a chat conversation between the user and the ORBIT AI assistant.
/// Features:
/// - Reversed ListView for auto-scroll to the latest message
/// - Suggestion chips when chat is empty
/// - Typing indicator during streaming
/// - Action buttons parsed from assistant responses
/// - RTL/LTR support based on current locale
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize RAG datasource and seed API key on first open.
    Future.microtask(() {
      ref.read(chatProvider.notifier).initializeRag();
      // Inject any completion messages from actions executed while away.
      ref.read(chatProvider.notifier).injectCompletionMessages();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls to the bottom of the chat list.
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // reversed list: 0 is the bottom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage(String text) {
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _handleClearChat() {
    final t = AppLocalizations.of(context);
    final isArabic = t?.isRtl ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          isArabic ? 'مسح المحادثة' : 'Clear Chat',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          isArabic
              ? 'هل تريد مسح جميع الرسائل؟'
              : 'Do you want to clear all messages?',
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t?.translate('cancel') ?? 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatProvider.notifier).clearChat();
            },
            child: Text(
              t?.translate('delete') ?? 'Delete',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _handleActionTap(AiActionModel action) {
    if (!action.isAllowed) return;

    // Only suggest_link actions reach here now (others are auto-executed).
    if (action.type == 'suggest_link') {
      if (action.route != null && action.route!.isNotEmpty) {
        context.push(action.route!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isArabic = t?.isRtl ?? true;
    final messagesAsync = ref.watch(chatProvider);
    final isStreaming = ref.watch(isStreamingProvider);

    // Auto-scroll when messages change.
    ref.listen(chatProvider, (previous, next) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(isArabic),
      body: Column(
        children: [
          // ── Chat body ──────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: AiSuggestionChips(
                        onChipTap: _handleSendMessage,
                      ),
                    ),
                  );
                }

                return _buildMessageList(messages, isStreaming);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      t?.translate('error') ?? 'Error',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextButton(
                      onPressed: () => ref.invalidate(chatProvider),
                      child: Text(
                        t?.translate('retry') ?? 'Retry',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Input bar ──────────────────────────────────────────────
          AiInputBar(
            onSend: _handleSendMessage,
            isStreaming: isStreaming,
          ),
        ],
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isArabic) {
    final t = AppLocalizations.of(context);
    final messages = ref.watch(chatProvider).valueOrNull ?? [];

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySurface,
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            t?.translate('aiAssistantTitle') ??
                (isArabic ? 'مساعد Corbit الذكي' : 'Corbit Smart Assistant'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (messages.isNotEmpty)
          IconButton(
            onPressed: _handleClearChat,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: AppColors.textSecondary,
            ),
            tooltip: isArabic ? 'مسح المحادثة' : 'Clear Chat',
          ),
        const SizedBox(width: AppTheme.spacingXs),
      ],
    );
  }

  // ─── Message list ──────────────────────────────────────────────────────

  Widget _buildMessageList(List<ChatMessageModel> messages, bool isStreaming) {
    // Check if the last assistant message is still empty (streaming just started).
    final showTyping = isStreaming &&
        messages.isNotEmpty &&
        messages.last.isAssistant &&
        messages.last.content.isEmpty;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      itemCount: messages.length + (showTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // In a reversed list, index 0 is the bottom.
        if (showTyping && index == 0) {
          return const AiTypingIndicator();
        }

        final messageIndex = showTyping
            ? messages.length - index
            : messages.length - 1 - index;

        if (messageIndex < 0 || messageIndex >= messages.length) {
          return const SizedBox.shrink();
        }

        final message = messages[messageIndex];

        // Skip empty assistant messages (being streamed — shown as typing).
        if (message.isAssistant && message.content.isEmpty && isStreaming) {
          return const SizedBox.shrink();
        }

        return ChatBubble(
          message: message,
          onActionTap: _handleActionTap,
        );
      },
    );
  }
}
