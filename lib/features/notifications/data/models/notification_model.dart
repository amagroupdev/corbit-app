/// Model representing a push notification record in the ORBIT platform.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.message,
    required this.senderName,
    required this.recipientCount,
    required this.sentAt,
    required this.status,
  });

  /// Unique identifier.
  final int id;

  /// The notification message body.
  final String message;

  /// Name of the sender.
  final String senderName;

  /// Number of recipients.
  final int recipientCount;

  /// When the notification was sent.
  final DateTime sentAt;

  /// Status: 'sent', 'pending', 'failed'.
  final String status;

  /// Whether the notification was successfully sent.
  bool get isSent => status == 'sent';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      recipientCount: json['recipient_count'] as int? ?? 0,
      sentAt: DateTime.tryParse(json['sent_at'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'sender_name': senderName,
      'recipient_count': recipientCount,
      'sent_at': sentAt.toIso8601String(),
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NotificationModel(id: $id, status: $status, recipients: $recipientCount)';
}
