/// Model representing a support ticket as returned by the V3 endpoints
/// `POST /support-tickets/list` and `POST /support-tickets`.
class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.title,
    this.status = 'open',
    this.message,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;

  /// Server-side status (e.g. `open`, `pending`, `closed`). Defaults to
  /// `open` so that screens always have a renderable badge.
  final String status;

  /// Optional ticket body (the Postman collection accepts only `title`,
  /// but the list response sometimes echoes a body field).
  final String? message;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOpen => status.toLowerCase() == 'open' || status.toLowerCase() == 'pending';
  bool get isClosed => status.toLowerCase() == 'closed' || status.toLowerCase() == 'resolved';

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: _parseInt(json['id']) ?? 0,
      title: (json['title'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'open',
      message: json['message'] as String? ?? json['body'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'message': message,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportTicketModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
