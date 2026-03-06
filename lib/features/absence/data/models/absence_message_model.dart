/// Model representing an absence/tardiness message in the ORBIT SMS platform.
///
/// These messages are sent to parents/guardians to notify them about
/// student absence or tardiness.
class AbsenceMessageModel {
  const AbsenceMessageModel({
    required this.id,
    required this.senderName,
    required this.messageType,
    required this.status,
    required this.sendTime,
    required this.recipientCount,
    this.receiveTime,
    this.classification,
  });

  /// Unique identifier.
  final int id;

  /// Name of the sender (e.g. school name or sender ID).
  final String senderName;

  /// Type of message: 'absence' or 'tardiness'.
  final String messageType;

  /// Status: 'accepted', 'rejected', 'expired', 'under_review',
  /// 'sent', 'failed', 'pending'.
  final String status;

  /// When the message was sent.
  final DateTime sendTime;

  /// When the message was received (may be null for pending/failed).
  final DateTime? receiveTime;

  /// Number of recipients.
  final int recipientCount;

  /// Message classification (optional category).
  final String? classification;

  /// Whether the message is an absence type.
  bool get isAbsence => messageType == 'absence';

  /// Whether the message is a tardiness type.
  bool get isTardiness => messageType == 'tardiness';

  /// Arabic label for the message type.
  String get messageTypeLabel {
    return switch (messageType) {
      'absence' => '\u063A\u064A\u0627\u0628', // غياب
      'tardiness' => '\u062A\u0623\u062E\u0631', // تأخر
      _ => messageType,
    };
  }

  /// Arabic label for the status.
  String get statusLabel {
    return switch (status) {
      'accepted' || 'sent' => '\u0645\u0642\u0628\u0648\u0644\u0629', // مقبولة
      'rejected' || 'failed' => '\u0645\u0631\u0641\u0648\u0636\u0629', // مرفوضة
      'expired' => '\u0645\u0646\u062A\u0647\u064A', // منتهي
      'under_review' || 'pending' => '\u062A\u062D\u062A \u0627\u0644\u0645\u0631\u0627\u062C\u0639\u0629', // تحت المراجعة
      _ => status,
    };
  }

  factory AbsenceMessageModel.fromJson(Map<String, dynamic> json) {
    return AbsenceMessageModel(
      id: json['id'] as int? ?? 0,
      senderName: json['sender_name'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'absence',
      status: json['status'] as String? ?? 'pending',
      sendTime: DateTime.tryParse(json['send_time'] as String? ?? '') ??
          DateTime.now(),
      receiveTime: json['receive_time'] != null
          ? DateTime.tryParse(json['receive_time'] as String? ?? '')
          : null,
      recipientCount: json['recipient_count'] as int? ?? 0,
      classification: json['classification'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_name': senderName,
      'message_type': messageType,
      'status': status,
      'send_time': sendTime.toIso8601String(),
      if (receiveTime != null) 'receive_time': receiveTime!.toIso8601String(),
      'recipient_count': recipientCount,
      if (classification != null) 'classification': classification,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AbsenceMessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AbsenceMessageModel(id: $id, senderName: $senderName, '
      'messageType: $messageType, status: $status)';
}
