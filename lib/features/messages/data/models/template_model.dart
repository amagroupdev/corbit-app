/// Model representing a reusable SMS message template.
///
/// Templates allow users to save frequently-used message bodies and
/// quickly insert them when composing a new message.
class TemplateModel {
  const TemplateModel({
    required this.id,
    required this.name,
    required this.body,
    required this.createdAt,
  });

  /// Unique identifier of the template.
  final int id;

  /// Short descriptive name for the template (e.g. "Welcome Message").
  final String name;

  /// The full message body text of the template.
  /// May contain variables like {student_name}, {customer_name}.
  final String body;

  /// When this template was created.
  final DateTime createdAt;

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      body: json['body'] as String? ?? json['template'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'body': body,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TemplateModel copyWith({
    int? id,
    String? name,
    String? body,
    DateTime? createdAt,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TemplateModel(id: $id, name: $name)';
}
