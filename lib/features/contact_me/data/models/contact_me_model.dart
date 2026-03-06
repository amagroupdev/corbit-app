/// Model for Contact Me settings.
class ContactMeSettings {
  const ContactMeSettings({
    required this.isEnabled,
    required this.rootUrl,
  });

  final bool isEnabled;
  final String rootUrl;

  factory ContactMeSettings.fromJson(Map<String, dynamic> json) {
    return ContactMeSettings(
      isEnabled: json['is_enabled'] as bool? ?? false,
      rootUrl: json['root_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      'root_url': rootUrl,
    };
  }
}

/// Model for a contact reason.
class ContactMeReason {
  const ContactMeReason({
    required this.id,
    required this.title,
    this.isActive = true,
  });

  final int id;
  final String title;
  final bool isActive;

  factory ContactMeReason.fromJson(Map<String, dynamic> json) {
    return ContactMeReason(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactMeReason &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model for a received contact message.
class ContactMeMessage {
  const ContactMeMessage({
    required this.id,
    required this.senderName,
    required this.senderPhone,
    required this.message,
    required this.reasonTitle,
    required this.createdAt,
  });

  final int id;
  final String senderName;
  final String senderPhone;
  final String message;
  final String reasonTitle;
  final DateTime createdAt;

  factory ContactMeMessage.fromJson(Map<String, dynamic> json) {
    return ContactMeMessage(
      id: json['id'] as int? ?? 0,
      senderName: json['sender_name'] as String? ?? '',
      senderPhone: json['sender_phone'] as String? ?? '',
      message: json['message'] as String? ?? '',
      reasonTitle: json['reason_title'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'message': message,
      'reason_title': reasonTitle,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactMeMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
