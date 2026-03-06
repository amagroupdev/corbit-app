/// Model representing a questionnaire in the ORBIT SMS platform.
class QuestionnaireModel {
  const QuestionnaireModel({
    required this.id,
    required this.title,
    required this.status,
    required this.responseCount,
    required this.createdAt,
    this.recipientCount = 0,
    this.notFilledCount = 0,
  });

  /// Unique identifier.
  final int id;

  /// The questionnaire title.
  final String title;

  /// Status: 'sent', 'unsent', 'draft'.
  final String status;

  /// Number of responses received.
  final int responseCount;

  /// When the questionnaire was created.
  final DateTime createdAt;

  /// Number of recipients the questionnaire was sent to.
  final int recipientCount;

  /// Number of recipients who have not responded.
  final int notFilledCount;

  /// Whether the questionnaire has been sent.
  bool get isSent => status == 'sent';

  factory QuestionnaireModel.fromJson(Map<String, dynamic> json) {
    return QuestionnaireModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'unsent',
      responseCount: json['response_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      recipientCount: json['recipient_count'] as int? ?? 0,
      notFilledCount: json['not_filled_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'response_count': responseCount,
      'created_at': createdAt.toIso8601String(),
      'recipient_count': recipientCount,
      'not_filled_count': notFilledCount,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionnaireModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'QuestionnaireModel(id: $id, title: $title, status: $status)';
}
