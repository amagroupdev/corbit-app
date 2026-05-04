/// Draft data payload models for the V3 Drafts feature.
///
/// `POST /messages/drafts/store` accepts four shapes selected by
/// `message_type`. Each variant carries its own `draft_data` body.
/// The shapes are kept lenient on parsing (defensive `as` casts) so
/// the UI never crashes on partial server responses.
library;

// ─── Message type variants ──────────────────────────────────────────────────

/// The four supported draft message types as expected by the V3 backend
/// at `POST /messages/drafts/store`.
enum DraftMessageType {
  toNumber('to_number', 'draftMsgTypeToNumber'),
  toGroup('to_group', 'draftMsgTypeToGroup'),
  voice('voice', 'draftMsgTypeVoice'),
  vipCard('vip_card', 'draftMsgTypeVipCard');

  const DraftMessageType(this.value, this.labelKey);

  /// API string value sent on the wire (e.g. `to_number`).
  final String value;

  /// Localization key for the user-facing label.
  final String labelKey;

  /// Resolves a [DraftMessageType] from its API value.
  /// Defaults to [toNumber] if unknown.
  static DraftMessageType fromValue(String? value) {
    if (value == null) return DraftMessageType.toNumber;
    return DraftMessageType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => DraftMessageType.toNumber,
    );
  }
}

// ─── Draft data ─────────────────────────────────────────────────────────────

/// Inner `draft_data` block shared by all four variants.
///
/// Not every field applies to every variant — see [DraftMessageType]:
/// - `to_number` uses [numbers] + [senderId] + [msgType] + [messageBody]
/// - `to_group` uses [groupIds] + [numberIds] + [senderId] + [msgType]
/// - `voice` uses [groupIds] + [numberIds] + [voiceId] + [msgType] (= `voice`)
/// - `vip_card` uses [groupIds] + [numberIds] + [cardType] + [templateId]
///
/// Fields that are `null` are omitted from [toJson] so the server only
/// sees the keys that the variant actually carries.
class DraftDataModel {
  const DraftDataModel({
    this.numbers = const [],
    this.groupIds = const [],
    this.numberIds = const [],
    this.senderId,
    this.msgType,
    this.schedule = 'now',
    this.scheduleAt,
    this.templateId,
    this.voiceId,
    this.cardType,
    this.messageBody = '',
  });

  /// Raw phone numbers (E.164 or local) used by `to_number` variant.
  final List<String> numbers;

  /// IDs of contact groups used by all non-`to_number` variants.
  final List<int> groupIds;

  /// IDs of individual saved numbers (within groups).
  final List<int> numberIds;

  /// Active sender id. Null is allowed during draft authoring.
  final int? senderId;

  /// Message channel: typically `sms` or `voice`.
  final String? msgType;

  /// Schedule literal — `now` or `later`.
  final String schedule;

  /// ISO timestamp when [schedule] is `later`.
  final String? scheduleAt;

  /// Optional template id for SMS / VIP card variants.
  final int? templateId;

  /// Optional voice id for the `voice` variant.
  final int? voiceId;

  /// Card type for the `vip_card` variant (e.g. `occasion`).
  final String? cardType;

  /// Free text body. Optional for `vip_card`/`voice` but normally present.
  final String messageBody;

  /// Builds the JSON payload, omitting null/empty fields so the server
  /// receives only the keys its variant expects.
  Map<String, dynamic> toJson() {
    return {
      if (numbers.isNotEmpty) 'numbers': numbers,
      if (groupIds.isNotEmpty) 'group_ids': groupIds,
      if (numberIds.isNotEmpty) 'number_ids': numberIds,
      if (senderId != null) 'sender_id': senderId,
      if (msgType != null) 'msg_type': msgType,
      'schedule': schedule,
      if (scheduleAt != null) 'schedule_at': scheduleAt,
      if (templateId != null) 'template_id': templateId,
      if (voiceId != null) 'voice_id': voiceId,
      if (cardType != null) 'card_type': cardType,
      'message_body': messageBody,
    };
  }

  factory DraftDataModel.fromJson(Map<String, dynamic> json) {
    return DraftDataModel(
      numbers: (json['numbers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      groupIds: (json['group_ids'] as List<dynamic>?)
              ?.map((e) => _parseInt(e) ?? 0)
              .where((e) => e != 0)
              .toList() ??
          const [],
      numberIds: (json['number_ids'] as List<dynamic>?)
              ?.map((e) => _parseInt(e) ?? 0)
              .where((e) => e != 0)
              .toList() ??
          const [],
      senderId: _parseInt(json['sender_id']),
      msgType: json['msg_type'] as String?,
      schedule: json['schedule'] as String? ?? 'now',
      scheduleAt: json['schedule_at'] as String?,
      templateId: _parseInt(json['template_id']),
      voiceId: _parseInt(json['voice_id']),
      cardType: json['card_type'] as String?,
      messageBody: json['message_body'] as String? ?? '',
    );
  }

  DraftDataModel copyWith({
    List<String>? numbers,
    List<int>? groupIds,
    List<int>? numberIds,
    int? senderId,
    String? msgType,
    String? schedule,
    String? scheduleAt,
    int? templateId,
    int? voiceId,
    String? cardType,
    String? messageBody,
    bool clearSenderId = false,
    bool clearTemplateId = false,
    bool clearVoiceId = false,
    bool clearCardType = false,
    bool clearScheduleAt = false,
  }) {
    return DraftDataModel(
      numbers: numbers ?? this.numbers,
      groupIds: groupIds ?? this.groupIds,
      numberIds: numberIds ?? this.numberIds,
      senderId: clearSenderId ? null : (senderId ?? this.senderId),
      msgType: msgType ?? this.msgType,
      schedule: schedule ?? this.schedule,
      scheduleAt: clearScheduleAt ? null : (scheduleAt ?? this.scheduleAt),
      templateId: clearTemplateId ? null : (templateId ?? this.templateId),
      voiceId: clearVoiceId ? null : (voiceId ?? this.voiceId),
      cardType: clearCardType ? null : (cardType ?? this.cardType),
      messageBody: messageBody ?? this.messageBody,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
