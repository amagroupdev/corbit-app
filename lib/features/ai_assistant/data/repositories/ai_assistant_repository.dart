import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/ai_assistant/data/datasources/deepseek_datasource.dart';
import 'package:orbit_app/features/ai_assistant/data/datasources/rag_local_datasource.dart';
import 'package:orbit_app/features/ai_assistant/data/models/ai_action_model.dart';
import 'package:orbit_app/features/ai_assistant/data/models/chat_message_model.dart';

/// Repository that combines the DeepSeek LLM with local RAG context
/// to power the AI assistant feature.
///
/// Acts as the single entry point for the presentation layer. Handles:
/// 1. RAG context retrieval (keyword search over local Markdown chunks)
/// 2. System prompt construction (base prompt + RAG context + navigation map)
/// 3. Streaming chat via DeepSeek API
/// 4. Action parsing from assistant responses
class AiAssistantRepository {
  const AiAssistantRepository({
    required DeepSeekDatasource deepSeekDatasource,
    required RagLocalDatasource ragDatasource,
  })  : _deepSeekDatasource = deepSeekDatasource,
        _ragDatasource = ragDatasource;

  final DeepSeekDatasource _deepSeekDatasource;
  final RagLocalDatasource _ragDatasource;

  /// Ensures the DeepSeek API key is stored in secure storage.
  ///
  /// On first launch the key won't exist yet, so we seed it here.
  /// Subsequent calls are no-ops because the datasource checks for
  /// an existing value before writing.
  Future<void> ensureApiKey() async {
    await _deepSeekDatasource.ensureApiKey();
  }

  /// Maximum number of history messages to include in the API request.
  static const int _maxHistoryMessages = 10;

  // ─── Initialise ─────────────────────────────────────────────────────────

  /// Initialises the RAG datasource by loading all local knowledge files.
  ///
  /// Must be called once before [chat] to ensure context is available.
  Future<void> initialize() async {
    try {
      await _ragDatasource.initialize();
    } catch (e) {
      throw Exception('Failed to initialize AI assistant: $e');
    }
  }

  // ─── Chat ───────────────────────────────────────────────────────────────

  /// Sends a user message and returns a [Stream] of response text chunks.
  ///
  /// 1. Searches RAG for relevant context chunks based on [userMessage].
  /// 2. Builds a system prompt with the base prompt, RAG context, and
  ///    the navigation map.
  /// 3. Constructs the messages array: system prompt + last N history
  ///    messages + the new user message.
  /// 4. Calls DeepSeek streaming API and yields text tokens as they arrive.
  Stream<String> chat(
    String userMessage,
    List<ChatMessageModel> history,
  ) async* {
    try {
      // 1. Search RAG for relevant context.
      final ragChunks = _ragDatasource.search(userMessage);
      final navigationMap = _ragDatasource.getNavigationMap();

      // 2. Build system prompt with context.
      final systemPrompt = _buildSystemPrompt(
        basePrompt: _ragDatasource.systemPrompt,
        ragContext: ragChunks
            .map((c) => '## ${c.title}\n${c.content}')
            .join('\n\n'),
        navigationMap: navigationMap,
      );

      // 3. Build messages array (last N history + new user message).
      final messages = <Map<String, String>>[];

      // Take only the last N messages from history.
      final recentHistory = history.length > _maxHistoryMessages
          ? history.sublist(history.length - _maxHistoryMessages)
          : history;

      for (final msg in recentHistory) {
        messages.add({
          'role': msg.role,
          'content': msg.content,
        });
      }

      // Add the new user message.
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // 4. Call DeepSeek streaming API.
      final stream = await _deepSeekDatasource.sendMessageStream(
        systemPrompt,
        messages,
      );

      yield* stream;
    } catch (e) {
      throw Exception('AI chat failed: $e');
    }
  }

  // ─── Action Parsing ─────────────────────────────────────────────────────

  /// Parses ```action code blocks from the AI response text.
  ///
  /// Each action block is expected to contain valid JSON. Only actions
  /// whose [AiActionModel.type] is in the whitelist are returned.
  /// Any unknown or dangerous action types are silently discarded.
  ///
  /// Example response text:
  /// ```
  /// Here's how to navigate:
  /// ```action
  /// {"type": "navigate", "route": "/messages", "label_ar": "الرسائل"}
  /// ```
  /// ```
  List<AiActionModel> parseActions(String responseText) {
    final actions = <AiActionModel>[];

    // Match ```action ... ``` blocks.
    final actionBlockRegex = RegExp(
      r'```action\s*\n([\s\S]*?)```',
      multiLine: true,
    );

    final matches = actionBlockRegex.allMatches(responseText);

    for (final match in matches) {
      final blockContent = match.group(1)?.trim();
      if (blockContent == null || blockContent.isEmpty) continue;

      try {
        final json = jsonDecode(blockContent);

        if (json is Map<String, dynamic>) {
          // Single action object.
          final action = AiActionModel.fromJson(json);
          if (action.isAllowed) {
            actions.add(action);
          }
        } else if (json is List) {
          // Array of action objects.
          for (final item in json) {
            if (item is Map<String, dynamic>) {
              final action = AiActionModel.fromJson(item);
              if (action.isAllowed) {
                actions.add(action);
              }
            }
          }
        }
      } catch (_) {
        // Skip malformed action blocks silently.
      }
    }

    return actions;
  }

  // ─── Private Helpers ────────────────────────────────────────────────────

  /// Constructs the full system prompt by combining the base prompt,
  /// relevant RAG context, and the navigation map.
  String _buildSystemPrompt({
    required String basePrompt,
    required String ragContext,
    required String navigationMap,
  }) {
    final buffer = StringBuffer();

    // Base system prompt.
    if (basePrompt.isNotEmpty) {
      buffer.writeln(basePrompt);
      buffer.writeln();
    }

    // RAG context section.
    if (ragContext.isNotEmpty) {
      buffer.writeln('--- Relevant Context ---');
      buffer.writeln(ragContext);
      buffer.writeln();
    }

    // Navigation map section.
    if (navigationMap.isNotEmpty && navigationMap != '{}') {
      buffer.writeln('--- Navigation Map ---');
      buffer.writeln(navigationMap);
      buffer.writeln();
    }

    return buffer.toString().trim();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepository(
    deepSeekDatasource: ref.watch(deepSeekDatasourceProvider),
    ragDatasource: ref.watch(ragLocalDatasourceProvider),
  );
});
