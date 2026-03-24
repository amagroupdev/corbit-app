/// Data models for the ORBIT SMS V3 Statements & Responses feature.
///
/// Contains [StatementType] enum for the 8 statement categories,
/// [StatementResponseItem] for individual response entries,
/// [StatementFilter] for filtering/searching, and
/// [StatementCountResult] for count responses.

// ─────────────────────────────────────────────────────────────────────────────
// Statement Type Enum
// ─────────────────────────────────────────────────────────────────────────────

/// The 8 statement types supported by the ORBIT SMS V3 API.
enum StatementType {
  all('all', 'statement_type_all'),
  short('short', 'statement_type_short'),
  voice('voice', 'statement_type_voice'),
  long('long', 'statement_type_long'),
  unregistered('unregistered', 'statement_type_unregistered'),
  absence('absence', 'statement_type_absence'),
  tardiness('tardiness', 'statement_type_tardiness'),
  absenceAndTardiness('absence_and_tardiness', 'statement_type_absence_and_tardiness');

  const StatementType(this.apiValue, this.labelKey);

  /// The value sent to the API in the `type` field.
  final String apiValue;

  /// Localization key for the display label.
  final String labelKey;

  /// Parses an API string value into a [StatementType].
  ///
  /// Falls back to [StatementType.all] if the value is unrecognized.
  static StatementType fromApiValue(String value) {
    return StatementType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => StatementType.all,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Statement Response Item
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single statement response from the API.
class StatementResponseItem {
  const StatementResponseItem({
    required this.id,
    required this.responseText,
    required this.name,
    required this.phoneNumber,
    required this.senderAccount,
    required this.sendTime,
    required this.responseTime,
    this.messageBody,
    this.attachmentUrl,
    this.statementType,
  });

  /// Unique response identifier.
  final int id;

  /// The response text content.
  final String responseText;

  /// Name of the respondent.
  final String name;

  /// Phone number of the respondent.
  final String phoneNumber;

  /// Sender account name.
  final String senderAccount;

  /// Timestamp when the original message was sent.
  final DateTime sendTime;

  /// Timestamp when the response was received.
  final DateTime responseTime;

  /// The original message body (if available).
  final String? messageBody;

  /// URL of any attachment (if available).
  final String? attachmentUrl;

  /// The statement type category.
  final StatementType? statementType;

  factory StatementResponseItem.fromJson(Map<String, dynamic> json) {
    return StatementResponseItem(
      id: _parseInt(json['id']),
      responseText: json['response_text'] as String? ??
          json['reply_text'] as String? ??
          json['text'] as String? ??
          '',
      name: json['name'] as String? ??
          json['recipient_name'] as String? ??
          '',
      phoneNumber: json['phone_number'] as String? ??
          json['phone'] as String? ??
          json['mobile'] as String? ??
          '',
      senderAccount: json['sender_account'] as String? ??
          json['sender_name'] as String? ??
          json['sender'] as String? ??
          '',
      sendTime: _parseDateTime(json['send_time'] ?? json['sent_at'] ?? json['created_at']),
      responseTime: _parseDateTime(json['response_time'] ?? json['replied_at'] ?? json['updated_at']),
      messageBody: json['message_body'] as String? ??
          json['message'] as String? ??
          json['body'] as String?,
      attachmentUrl: json['attachment_url'] as String? ??
          json['attachment'] as String? ??
          json['file_url'] as String?,
      statementType: json['type'] != null
          ? StatementType.fromApiValue(json['type'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'response_text': responseText,
      'name': name,
      'phone_number': phoneNumber,
      'sender_account': senderAccount,
      'send_time': sendTime.toIso8601String(),
      'response_time': responseTime.toIso8601String(),
      'message_body': messageBody,
      'attachment_url': attachmentUrl,
      'type': statementType?.apiValue,
    };
  }

  StatementResponseItem copyWith({
    int? id,
    String? responseText,
    String? name,
    String? phoneNumber,
    String? senderAccount,
    DateTime? sendTime,
    DateTime? responseTime,
    String? messageBody,
    String? attachmentUrl,
    StatementType? statementType,
  }) {
    return StatementResponseItem(
      id: id ?? this.id,
      responseText: responseText ?? this.responseText,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      senderAccount: senderAccount ?? this.senderAccount,
      sendTime: sendTime ?? this.sendTime,
      responseTime: responseTime ?? this.responseTime,
      messageBody: messageBody ?? this.messageBody,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      statementType: statementType ?? this.statementType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatementResponseItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'StatementResponseItem(id: $id, name: $name, '
      'phone: $phoneNumber, sender: $senderAccount)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Statement Filter
// ─────────────────────────────────────────────────────────────────────────────

/// Filter parameters for querying the statements list.
class StatementFilter {
  const StatementFilter({
    this.searchQuery,
    this.name,
    this.senderName,
    this.groupId,
    this.fromDate,
    this.toDate,
    this.useHijriDate = false,
  });

  /// General text search query (message text, sender name).
  final String? searchQuery;

  /// Filter by respondent name.
  final String? name;

  /// Filter by sender name.
  final String? senderName;

  /// Filter by group ID.
  final int? groupId;

  /// Start date for date range filter.
  final DateTime? fromDate;

  /// End date for date range filter.
  final DateTime? toDate;

  /// Whether to use Hijri date calendar.
  final bool useHijriDate;

  /// Returns `true` if no filters are active.
  bool get isEmpty =>
      (searchQuery == null || searchQuery!.isEmpty) &&
      (name == null || name!.isEmpty) &&
      (senderName == null || senderName!.isEmpty) &&
      groupId == null &&
      fromDate == null &&
      toDate == null;

  /// Returns `true` if any filter is active.
  bool get isNotEmpty => !isEmpty;

  /// Number of active filters (for badge display).
  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (name != null && name!.isNotEmpty) count++;
    if (senderName != null && senderName!.isNotEmpty) count++;
    if (groupId != null) count++;
    if (fromDate != null) count++;
    if (toDate != null) count++;
    return count;
  }

  /// Converts to the JSON format expected by the API `filters` field.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> filters = {};

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      filters['search'] = searchQuery;
    }
    if (name != null && name!.isNotEmpty) {
      filters['name'] = name;
    }
    if (senderName != null && senderName!.isNotEmpty) {
      filters['sender_name'] = senderName;
    }
    if (groupId != null) {
      filters['group_id'] = groupId;
    }
    if (fromDate != null) {
      filters['from_date'] =
          '${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}';
    }
    if (toDate != null) {
      filters['to_date'] =
          '${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}';
    }
    if (useHijriDate) {
      filters['hijri_date'] = true;
    }

    return filters;
  }

  StatementFilter copyWith({
    String? searchQuery,
    String? name,
    String? senderName,
    int? groupId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? useHijriDate,
    bool clearSearchQuery = false,
    bool clearName = false,
    bool clearSenderName = false,
    bool clearGroupId = false,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) {
    return StatementFilter(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      name: clearName ? null : (name ?? this.name),
      senderName: clearSenderName ? null : (senderName ?? this.senderName),
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      useHijriDate: useHijriDate ?? this.useHijriDate,
    );
  }

  /// Returns a new [StatementFilter] with all fields reset to null.
  factory StatementFilter.empty() => const StatementFilter();

  @override
  String toString() => 'StatementFilter(search: $searchQuery, '
      'name: $name, sender: $senderName, group: $groupId, '
      'from: $fromDate, to: $toDate, hijri: $useHijriDate)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Statement Count Result
// ─────────────────────────────────────────────────────────────────────────────

/// Response model from the statements count endpoint.
class StatementCountResult {
  const StatementCountResult({
    required this.count,
  });

  final int count;

  factory StatementCountResult.fromJson(Map<String, dynamic> json) {
    return StatementCountResult(
      count: _parseInt(json['count'] ?? json['total'] ?? 0),
    );
  }

  @override
  String toString() => 'StatementCountResult(count: $count)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Parsing Helpers
// ─────────────────────────────────────────────────────────────────────────────

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
