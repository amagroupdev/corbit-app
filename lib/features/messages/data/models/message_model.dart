/// Data models for the Messages feature of ORBIT SMS V3.
///
/// Covers the unified send endpoint (POST /api/v3/messages/send),
/// message previews, and SMS character counting.

// ─── Message Type Enum ───────────────────────────────────────────────────────

/// All 14 message types supported by the ORBIT SMS V3 gateway.
enum MessageType {
  fromNumbers('from_numbers', 'msg_type_from_numbers', 'msg_type_from_numbers_short'),
  fromGroups('from_groups', 'msg_type_from_groups', 'msg_type_from_groups_short'),
  fromNoor('from_noor', 'msg_type_from_noor', 'msg_type_from_noor_short'),
  customMessages('custom_messages', 'msg_type_custom_messages', 'msg_type_custom_messages_short'),
  absenceLateness('absence_lateness', 'msg_type_absence_lateness', 'msg_type_absence_lateness_short'),
  teacherMessages('teacher_messages', 'msg_type_teacher_messages', 'msg_type_teacher_messages_short'),
  longMessages('long_messages', 'msg_type_long_messages', 'msg_type_long_messages_short'),
  voiceMessages('voice_messages', 'msg_type_voice_messages', 'msg_type_voice_messages_short'),
  fileMessages('file_messages', 'msg_type_file_messages', 'msg_type_file_messages_short'),
  thanksCertifications('thanks_certifications', 'msg_type_thanks_certifications', 'msg_type_thanks_certifications_short'),
  vipCards('vip_cards', 'msg_type_vip_cards', 'msg_type_vip_cards_short'),
  bulkMessages('bulk_messages', 'msg_type_bulk_messages', 'msg_type_bulk_messages_short'),
  attendanceRecords('attendance_records', 'msg_type_attendance_records', 'msg_type_attendance_records_short'),
  certifications('certifications', 'msg_type_certifications', 'msg_type_certifications_short');

  const MessageType(this.value, this.labelKey, this.shortLabelKey);

  /// The API value sent to the server (e.g. 'from_numbers').
  final String value;

  /// Localization key for the full display label.
  final String labelKey;

  /// Localization key for the short tab label.
  final String shortLabelKey;

  /// The archive_type value accepted by POST /archive/list.
  ///
  /// Some message types (from_numbers, from_groups) map to 'general'
  /// because the archive/list endpoint uses different type names than
  /// the send endpoint.
  String get apiValue {
    switch (this) {
      case MessageType.fromNumbers:
      case MessageType.fromGroups:
      case MessageType.fromNoor:
      case MessageType.absenceLateness:
      case MessageType.teacherMessages:
      case MessageType.attendanceRecords:
      case MessageType.certifications:
      case MessageType.thanksCertifications:
      case MessageType.vipCards:
        return 'general';
      case MessageType.customMessages:
        return 'custom_messages';
      case MessageType.longMessages:
        return 'long_messages';
      case MessageType.voiceMessages:
        return 'voice_messages';
      case MessageType.fileMessages:
        return 'file_messages';
      case MessageType.bulkMessages:
        return 'bulk_messages';
    }
  }

  /// Resolves a [MessageType] from its API string value.
  /// Returns [MessageType.fromNumbers] as default if not found.
  static MessageType fromValue(String value) {
    return MessageType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => MessageType.fromNumbers,
    );
  }
}

// ─── Send At Option ──────────────────────────────────────────────────────────

/// Whether a message should be sent immediately or scheduled for later.
enum SendAtOption {
  now('now'),
  later('later');

  const SendAtOption(this.value);
  final String value;

  static SendAtOption fromValue(String value) {
    return SendAtOption.values.firstWhere(
      (o) => o.value == value,
      orElse: () => SendAtOption.now,
    );
  }
}

// ─── Message Status ──────────────────────────────────────────────────────────

/// Status of a sent message.
enum MessageStatus {
  sent('sent', 'msg_status_sent'),
  delivered('delivered', 'msg_status_delivered'),
  pending('pending', 'msg_status_pending'),
  failed('failed', 'msg_status_failed'),
  scheduled('scheduled', 'msg_status_scheduled'),
  rejected('rejected', 'msg_status_rejected'),
  expired('expired', 'msg_status_expired');

  const MessageStatus(this.value, this.labelKey);
  final String value;

  /// Localization key for the status display label.
  final String labelKey;

  static MessageStatus fromValue(String value) {
    return MessageStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => MessageStatus.pending,
    );
  }
}

// ─── Send Message Request ────────────────────────────────────────────────────

/// Request body for POST /api/v3/messages/send.
class SendMessageRequest {
  const SendMessageRequest({
    required this.messageType,
    required this.senderId,
    required this.messageBody,
    this.sendAtOption = SendAtOption.now,
    this.sendAt,
    this.numbers = const [],
    this.groupIds = const [],
    this.templateId,
  });

  final MessageType messageType;
  final int senderId;
  final String messageBody;
  final SendAtOption sendAtOption;
  final DateTime? sendAt;
  final List<String> numbers;
  final List<int> groupIds;
  final int? templateId;

  Map<String, dynamic> toJson() {
    return {
      'message_type': messageType.value,
      'sender_id': senderId,
      'message_body': messageBody,
      'send_at_option': sendAtOption.value,
      if (sendAt != null) 'send_at': sendAt!.toIso8601String(),
      if (numbers.isNotEmpty) 'numbers': numbers.map(_normalizePhone).toList(),
      if (groupIds.isNotEmpty) 'group_ids': groupIds,
      if (templateId != null) 'template_id': templateId,
    };
  }

  /// Ensures phone numbers are in E.164 format (+966XXXXXXXXX).
  static String _normalizePhone(String number) {
    var n = number.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (n.startsWith('00')) n = '+${n.substring(2)}';
    if (n.startsWith('05')) n = '+966${n.substring(1)}';
    if (n.startsWith('5') && n.length == 9) n = '+966$n';
    if (n.startsWith('966') && !n.startsWith('+')) n = '+$n';
    if (!n.startsWith('+')) n = '+$n';
    return n;
  }

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) {
    return SendMessageRequest(
      messageType: MessageType.fromValue(json['message_type'] as String? ?? 'from_numbers'),
      senderId: json['sender_id'] as int? ?? 0,
      messageBody: json['message_body'] as String? ?? '',
      sendAtOption: SendAtOption.fromValue(json['send_at_option'] as String? ?? 'now'),
      sendAt: json['send_at'] != null ? DateTime.tryParse(json['send_at'] as String) : null,
      numbers: (json['numbers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      groupIds: (json['group_ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      templateId: json['template_id'] as int?,
    );
  }

  SendMessageRequest copyWith({
    MessageType? messageType,
    int? senderId,
    String? messageBody,
    SendAtOption? sendAtOption,
    DateTime? sendAt,
    List<String>? numbers,
    List<int>? groupIds,
    int? templateId,
  }) {
    return SendMessageRequest(
      messageType: messageType ?? this.messageType,
      senderId: senderId ?? this.senderId,
      messageBody: messageBody ?? this.messageBody,
      sendAtOption: sendAtOption ?? this.sendAtOption,
      sendAt: sendAt ?? this.sendAt,
      numbers: numbers ?? this.numbers,
      groupIds: groupIds ?? this.groupIds,
      templateId: templateId ?? this.templateId,
    );
  }
}

// ─── Message Preview ─────────────────────────────────────────────────────────

/// Preview / cost estimate returned before actually sending.
class MessagePreview {
  const MessagePreview({
    required this.messageCount,
    required this.recipientCount,
    required this.costEstimate,
  });

  /// Number of SMS segments required for the message body.
  final int messageCount;

  /// Total number of recipients (unique numbers + group members).
  final int recipientCount;

  /// Estimated cost in the account's balance units.
  final double costEstimate;

  factory MessagePreview.fromJson(Map<String, dynamic> json) {
    return MessagePreview(
      messageCount: json['message_count'] as int? ?? 0,
      recipientCount: json['recipient_count'] as int? ?? 0,
      costEstimate: (json['cost_estimate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_count': messageCount,
      'recipient_count': recipientCount,
      'cost_estimate': costEstimate,
    };
  }
}

// ─── SMS Count Result ────────────────────────────────────────────────────────

/// Result of SMS segment calculation for a given message body.
class SmsCountResult {
  const SmsCountResult({
    required this.smsCount,
    required this.characterCount,
  });

  /// Number of SMS segments the message will be split into.
  final int smsCount;

  /// Total character count of the message body.
  final int characterCount;

  factory SmsCountResult.fromJson(Map<String, dynamic> json) {
    return SmsCountResult(
      smsCount: json['sms_count'] as int? ?? 0,
      characterCount: json['character_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sms_count': smsCount,
      'character_count': characterCount,
    };
  }

  /// Calculates SMS count locally without an API call.
  ///
  /// GSM 7-bit encoding: 160 chars for single SMS, 153 per segment for multi.
  /// Unicode (Arabic): 70 chars for single SMS, 67 per segment for multi.
  factory SmsCountResult.calculate(String message) {
    if (message.isEmpty) {
      return const SmsCountResult(smsCount: 0, characterCount: 0);
    }

    final characterCount = message.length;
    final bool isUnicode = _containsUnicode(message);

    final int singleLimit = isUnicode ? 70 : 160;
    final int multiLimit = isUnicode ? 67 : 153;

    int smsCount;
    if (characterCount <= singleLimit) {
      smsCount = 1;
    } else {
      smsCount = (characterCount / multiLimit).ceil();
    }

    return SmsCountResult(
      smsCount: smsCount,
      characterCount: characterCount,
    );
  }

  /// Returns `true` if the text contains non-GSM-7 characters (e.g. Arabic).
  static bool _containsUnicode(String text) {
    // GSM 7-bit basic character set covers ASCII printables plus a few extras.
    // Any character outside this range triggers Unicode encoding.
    final gsm7Regex = RegExp(
      r'^[@£\$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞ\x1BÆæßÉ !"#¤%&' "'"
      r'()*+,\-./0-9:;<=>?¡A-ZÄÖÑܧ¿a-zäöñüà\^{}\[~\]|€]*\$',
    );
    return !gsm7Regex.hasMatch(text);
  }
}

// ─── Sent Message Model ──────────────────────────────────────────────────────

/// Represents a sent message record returned from the archive / message list.
class SentMessageModel {
  const SentMessageModel({
    required this.id,
    required this.messageType,
    required this.senderName,
    required this.messageBody,
    required this.recipientCount,
    required this.status,
    required this.createdAt,
    this.scheduledAt,
    this.deliveredCount,
    this.failedCount,
    this.cost,
  });

  final int id;
  final MessageType messageType;
  final String senderName;
  final String messageBody;
  final int recipientCount;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final int? deliveredCount;
  final int? failedCount;
  final double? cost;

  factory SentMessageModel.fromJson(Map<String, dynamic> json) {
    // Extract delivery stats from dlr_statistics if present.
    final dlr = json['dlr_statistics'] as Map<String, dynamic>?;

    return SentMessageModel(
      id: json['id'] as int? ?? 0,
      messageType: MessageType.fromValue(
        json['message_type'] as String? ?? json['type'] as String? ?? 'from_numbers',
      ),
      senderName: json['sender_name'] as String? ?? '',
      // API /archive/list returns 'message', not 'message_body'.
      messageBody: json['message_body'] as String? ?? json['message'] as String? ?? '',
      // API /archive/list returns 'numbers_count', not 'recipient_count'.
      recipientCount: json['recipient_count'] as int? ?? json['numbers_count'] as int? ?? 0,
      status: MessageStatus.fromValue(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.tryParse(
        json['created_at'] as String? ?? json['sent_at'] as String? ?? '',
      ) ?? DateTime.now(),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      deliveredCount: json['delivered_count'] as int? ?? dlr?['delivered'] as int?,
      failedCount: json['failed_count'] as int? ?? dlr?['failed'] as int?,
      cost: (json['cost'] as num?)?.toDouble() ?? (json['sms_count'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_type': messageType.value,
      'sender_name': senderName,
      'message_body': messageBody,
      'recipient_count': recipientCount,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (deliveredCount != null) 'delivered_count': deliveredCount,
      if (failedCount != null) 'failed_count': failedCount,
      if (cost != null) 'cost': cost,
    };
  }
}
