/// Dynamic-text placeholder served by `GET /messages/dynamic-texts`.
///
/// The server returns a list of variable tokens (e.g. `{student_name}`,
/// `{group}`, `{link}`, `{number_name}`) along with a localized label and
/// optional description so the UI can render a friendly picker.
///
/// The response shape is:
/// ```json
/// {
///   "success": true,
///   "data": [
///     { "key": "student_name", "label": "اسم الطالب", "description": "..." },
///     { "key": "group", "label": "اسم المجموعة" }
///   ]
/// }
/// ```
class DynamicTextModel {
  const DynamicTextModel({
    required this.key,
    required this.label,
    this.description,
  });

  /// The variable key used in the message body — inserted as `{key}`.
  final String key;

  /// Human-readable label for the picker (already localized by the server
  /// based on the request `Accept-Language` header).
  final String label;

  /// Optional helper text describing what the variable resolves to.
  final String? description;

  /// The token as it should appear inside the message body, e.g. `{key}`.
  String get token => '{$key}';

  factory DynamicTextModel.fromJson(Map<String, dynamic> json) {
    return DynamicTextModel(
      key: (json['key'] as String?)?.trim() ??
          (json['name'] as String?)?.trim() ??
          (json['variable'] as String?)?.trim() ??
          '',
      label: (json['label'] as String?)?.trim() ??
          (json['name'] as String?)?.trim() ??
          (json['title'] as String?)?.trim() ??
          (json['key'] as String? ?? ''),
      description: (json['description'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }
}
