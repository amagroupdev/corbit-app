/// Model representing an interactive message/poll sent through the ORBIT platform.
class InteractionModel {
  const InteractionModel({
    required this.id,
    required this.message,
    required this.rootUrl,
    required this.recipientCount,
    required this.replyCount,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String message;
  final String rootUrl;
  final int recipientCount;
  final int replyCount;
  final String status;
  final DateTime createdAt;

  bool get isSent => status == 'sent';

  factory InteractionModel.fromJson(Map<String, dynamic> json) {
    return InteractionModel(
      id: json['id'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      rootUrl: json['root_url'] as String? ?? '',
      recipientCount: json['recipient_count'] as int? ?? 0,
      replyCount: json['reply_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'root_url': rootUrl,
      'recipient_count': recipientCount,
      'reply_count': replyCount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model representing a reply to an interaction.
class InteractionReply {
  const InteractionReply({
    required this.id,
    required this.senderPhone,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final String senderPhone;
  final String message;
  final DateTime createdAt;

  factory InteractionReply.fromJson(Map<String, dynamic> json) {
    return InteractionReply(
      id: json['id'] as int? ?? 0,
      senderPhone: json['sender_phone'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_phone': senderPhone,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
