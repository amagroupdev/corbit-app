/// Model representing a Noor import record in the ORBIT platform.
///
/// Noor imports are messages sent via the Noor educational system,
/// using message_type=from_noor through the messages/send endpoint.
class NoorImportModel {
  const NoorImportModel({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.messageBody,
    required this.status,
    required this.createdAt,
    this.className,
    this.grade,
  });

  final int id;
  final String recipientName;
  final String recipientPhone;
  final String messageBody;
  final String status;
  final DateTime createdAt;
  final String? className;
  final String? grade;

  bool get isSent => status == 'sent';
  bool get isPending => status == 'pending';

  factory NoorImportModel.fromJson(Map<String, dynamic> json) {
    return NoorImportModel(
      id: json['id'] as int? ?? 0,
      recipientName: json['recipient_name'] as String? ?? '',
      recipientPhone: json['recipient_phone'] as String? ?? '',
      messageBody: json['message_body'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      className: json['class_name'] as String?,
      grade: json['grade'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'message_body': messageBody,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (className != null) 'class_name': className,
      if (grade != null) 'grade': grade,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoorImportModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
