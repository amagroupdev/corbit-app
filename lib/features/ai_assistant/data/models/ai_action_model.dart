/// Model representing an AI-suggested action parsed from the assistant response.
///
/// Actions are embedded in ```action code blocks within the AI response text.
/// Each action has a [type] that determines what the app should do when the
/// user taps the action chip.
///
/// **Security**: Only whitelisted action types are allowed. Any action with
/// an unknown or dangerous type (delete, update, send, modify) is rejected.
class AiActionModel {
  const AiActionModel({
    required this.type,
    this.route,
    this.labelAr,
    this.labelEn,
    this.name,
    this.content,
  });

  /// The action type. Must be one of [allowedTypes].
  final String type;

  /// Navigation route path (for 'navigate' actions).
  final String? route;

  /// Arabic label displayed on the action chip.
  final String? labelAr;

  /// English label displayed on the action chip.
  final String? labelEn;

  /// Name parameter (e.g. group name, template name).
  final String? name;

  /// Content parameter (e.g. template body text).
  final String? content;

  // ─── Whitelist ──────────────────────────────────────────────────────────

  /// The ONLY action types the AI is allowed to suggest.
  ///
  /// NEVER allow: delete, update, send, modify, or any other type.
  static const Set<String> allowedTypes = {
    'navigate',
    'suggest_link',
    'create_group',
    'create_template',
  };

  /// Returns `true` if this action's [type] is in the whitelist.
  bool get isAllowed => allowedTypes.contains(type);

  // ─── JSON ───────────────────────────────────────────────────────────────

  factory AiActionModel.fromJson(Map<String, dynamic> json) {
    return AiActionModel(
      type: json['type'] as String? ?? '',
      route: json['route'] as String?,
      labelAr: json['label_ar'] as String?,
      labelEn: json['label_en'] as String?,
      name: json['name'] as String?,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (route != null) 'route': route,
      if (labelAr != null) 'label_ar': labelAr,
      if (labelEn != null) 'label_en': labelEn,
      if (name != null) 'name': name,
      if (content != null) 'content': content,
    };
  }

  @override
  String toString() => 'AiActionModel(type: $type, route: $route)';
}
