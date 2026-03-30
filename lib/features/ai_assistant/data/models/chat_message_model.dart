import 'package:orbit_app/features/ai_assistant/data/models/ai_action_model.dart';

/// Model representing a single chat message in the AI assistant conversation.
///
/// Each message has a [role] indicating whether it was sent by the user or
/// the AI assistant, along with the text [content] and an optional list of
/// parsed [actions] (only present in assistant messages).
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.actions = const [],
  });

  /// Unique identifier for this message.
  final String id;

  /// The role of the message sender: `'user'` or `'assistant'`.
  final String role;

  /// The text content of the message.
  final String content;

  /// When this message was created.
  final DateTime timestamp;

  /// Parsed AI actions from the assistant response.
  ///
  /// Only populated for assistant messages that contain ```action blocks.
  final List<AiActionModel> actions;

  /// Convenience getter: `true` when this is a user message.
  bool get isUser => role == 'user';

  /// Convenience getter: `true` when this is an assistant message.
  bool get isAssistant => role == 'assistant';

  // ─── JSON ───────────────────────────────────────────────────────────────

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) =>
                  AiActionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (actions.isNotEmpty)
        'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    List<AiActionModel>? actions,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      actions: actions ?? this.actions,
    );
  }

  @override
  String toString() => 'ChatMessageModel(id: $id, role: $role)';
}
