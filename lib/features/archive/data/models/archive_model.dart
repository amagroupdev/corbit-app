/// Data models for the ORBIT SMS V3 Archive feature.
///
/// Contains [ArchiveType] enum for the 10 archive categories,
/// [ArchiveItem] for individual archived messages, [ArchiveFilter]
/// for filtering/searching the archive, and [ArchiveCountResult]
/// for count responses.

// ─────────────────────────────────────────────────────────────────────────────
// Archive Type Enum
// ─────────────────────────────────────────────────────────────────────────────

/// The 10 archive types supported by the ORBIT SMS V3 API.
enum ArchiveType {
  general('general', 'archive_type_general', false),
  customMessages('custom_messages', 'archive_type_custom_messages', true),
  absenceLateness('absence_lateness', 'archive_type_absence_lateness', true),
  teacherMessages('teacher_messages', 'archive_type_teacher_messages', true),
  longMessages('long_messages', 'archive_type_long_messages', false),
  voiceMessages('voice_messages', 'archive_type_voice_messages', false),
  fileMessages('file_messages', 'archive_type_file_messages', false),
  thanksCertifications('thanks_certifications', 'archive_type_thanks_certifications', true),
  vipCards('vip_cards', 'archive_type_vip_cards', true),
  bulkMessages('bulk_messages', 'archive_type_bulk_messages', false);

  const ArchiveType(this.apiValue, this.labelKey, this.isSchoolOnly);

  /// The value sent to the API in the `archive_type` field.
  final String apiValue;

  /// Localization key for the display label.
  final String labelKey;

  /// Whether this archive type is only available for school accounts (userTypeId == 2).
  final bool isSchoolOnly;

  /// Returns archive types filtered by user type.
  /// School-only types are excluded when [userTypeId] is not 2.
  static List<ArchiveType> forUserType(int? userTypeId) {
    if (userTypeId == 2) return values;
    return values.where((t) => !t.isSchoolOnly).toList();
  }

  /// Parses an API string value into an [ArchiveType].
  ///
  /// Falls back to [ArchiveType.general] if the value is unrecognized.
  static ArchiveType fromApiValue(String value) {
    return ArchiveType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => ArchiveType.general,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Send At Filter
// ─────────────────────────────────────────────────────────────────────────────

/// Filter options for the `send_at` field.
enum SendAtFilter {
  all('', 'archive_send_at_all'),
  now('now', 'archive_send_at_now'),
  later('later', 'archive_send_at_later'),
  api('api', 'archive_send_at_api');

  const SendAtFilter(this.apiValue, this.labelKey);

  final String apiValue;
  final String labelKey;

  static SendAtFilter fromApiValue(String value) {
    return SendAtFilter.values.firstWhere(
      (f) => f.apiValue == value,
      orElse: () => SendAtFilter.all,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Status
// ─────────────────────────────────────────────────────────────────────────────

/// Status of an archived message.
enum ArchiveMessageStatus {
  sent('sent', 'archive_status_sent'),
  delivered('delivered', 'archive_status_delivered'),
  pending('pending', 'archive_status_pending'),
  failed('failed', 'archive_status_failed'),
  rejected('rejected', 'archive_status_rejected'),
  scheduled('scheduled', 'archive_status_scheduled'),
  cancelled('cancelled', 'archive_status_cancelled'),
  expired('expired', 'archive_status_expired'),
  unknown('unknown', 'archive_status_unknown');

  const ArchiveMessageStatus(this.apiValue, this.labelKey);

  final String apiValue;
  final String labelKey;

  static ArchiveMessageStatus fromApiValue(String? value) {
    if (value == null || value.isEmpty) return ArchiveMessageStatus.unknown;
    return ArchiveMessageStatus.values.firstWhere(
      (s) => s.apiValue == value.toLowerCase(),
      orElse: () => ArchiveMessageStatus.unknown,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Archive Item
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single archived message from the API.
class ArchiveItem {
  const ArchiveItem({
    required this.id,
    required this.senderName,
    required this.recipientNumber,
    required this.messageBody,
    required this.status,
    required this.sentAt,
    required this.archiveType,
    this.recipientName,
    this.senderNumber,
    this.messageCount = 1,
    this.cost,
    this.createdAt,
    this.scheduledAt,
    this.cancelledAt,
  });

  /// Unique message identifier.
  final int id;

  /// Name of the sender (account or sub-account).
  final String senderName;

  /// Phone number of the recipient.
  final String recipientNumber;

  /// Optional recipient display name.
  final String? recipientName;

  /// Sender phone number / ID.
  final String? senderNumber;

  /// The message text body.
  final String messageBody;

  /// Current delivery status.
  final ArchiveMessageStatus status;

  /// Timestamp when the message was sent (or scheduled).
  final DateTime sentAt;

  /// The archive category this message belongs to.
  final ArchiveType archiveType;

  /// Number of SMS segments used.
  final int messageCount;

  /// Cost in points/credits.
  final double? cost;

  /// Record creation timestamp.
  final DateTime? createdAt;

  /// Scheduled send time (for deferred messages).
  final DateTime? scheduledAt;

  /// Cancellation time (if message was cancelled).
  final DateTime? cancelledAt;

  factory ArchiveItem.fromJson(Map<String, dynamic> json) {
    return ArchiveItem(
      id: _parseInt(json['id']),
      senderName: json['sender_name'] as String? ??
          json['sender'] as String? ??
          '',
      recipientNumber: json['recipient_number'] as String? ??
          json['recipient'] as String? ??
          json['phone'] as String? ??
          (json['numbers_count'] != null ? '${json['numbers_count']} مستلم' : ''),
      recipientName: json['recipient_name'] as String?,
      senderNumber: json['sender_number'] as String? ??
          json['sender_id']?.toString(),
      messageBody: json['message_body'] as String? ??
          json['message'] as String? ??
          json['body'] as String? ??
          '',
      status: ArchiveMessageStatus.fromApiValue(
        json['status'] as String? ?? '',
      ),
      sentAt: _parseDateTime(json['sent_at'] ?? json['send_at'] ?? json['created_at']),
      archiveType: ArchiveType.fromApiValue(
        json['archive_type'] as String? ?? 'general',
      ),
      messageCount: _parseInt(json['message_count'] ?? json['sms_count'] ?? 1),
      cost: _parseDouble(json['cost'] ?? json['price']),
      createdAt: json['created_at'] != null
          ? _parseDateTime(json['created_at'])
          : null,
      scheduledAt: json['scheduled_at'] != null
          ? _parseDateTime(json['scheduled_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? _parseDateTime(json['cancelled_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_name': senderName,
      'recipient_number': recipientNumber,
      'recipient_name': recipientName,
      'sender_number': senderNumber,
      'message_body': messageBody,
      'status': status.apiValue,
      'sent_at': sentAt.toIso8601String(),
      'archive_type': archiveType.apiValue,
      'message_count': messageCount,
      'cost': cost,
      'created_at': createdAt?.toIso8601String(),
      'scheduled_at': scheduledAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  ArchiveItem copyWith({
    int? id,
    String? senderName,
    String? recipientNumber,
    String? recipientName,
    String? senderNumber,
    String? messageBody,
    ArchiveMessageStatus? status,
    DateTime? sentAt,
    ArchiveType? archiveType,
    int? messageCount,
    double? cost,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? cancelledAt,
  }) {
    return ArchiveItem(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      recipientNumber: recipientNumber ?? this.recipientNumber,
      recipientName: recipientName ?? this.recipientName,
      senderNumber: senderNumber ?? this.senderNumber,
      messageBody: messageBody ?? this.messageBody,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      archiveType: archiveType ?? this.archiveType,
      messageCount: messageCount ?? this.messageCount,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArchiveItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ArchiveItem(id: $id, sender: $senderName, '
      'recipient: $recipientNumber, status: ${status.apiValue})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Archive Filter
// ─────────────────────────────────────────────────────────────────────────────

/// Filter parameters for querying the archive list.
class ArchiveFilter {
  const ArchiveFilter({
    this.sendAt,
    this.senderIds,
    this.fromDate,
    this.toDate,
    this.phoneNumber,
    this.selectedAccounts,
    this.archiveIds,
    this.searchQuery,
  });

  /// Filter by send type: now, later, api.
  final SendAtFilter? sendAt;

  /// Filter by specific sender account IDs.
  final List<int>? senderIds;

  /// Start date for date range filter.
  final DateTime? fromDate;

  /// End date for date range filter.
  final DateTime? toDate;

  /// Filter by recipient phone number.
  final String? phoneNumber;

  /// Filter by selected sub-account IDs.
  final List<int>? selectedAccounts;

  /// Filter by specific archive entry IDs.
  final List<int>? archiveIds;

  /// Local text search query (client-side filtering).
  final String? searchQuery;

  /// Returns `true` if no filters are active.
  bool get isEmpty =>
      sendAt == null &&
      (senderIds == null || senderIds!.isEmpty) &&
      fromDate == null &&
      toDate == null &&
      (phoneNumber == null || phoneNumber!.isEmpty) &&
      (selectedAccounts == null || selectedAccounts!.isEmpty) &&
      (archiveIds == null || archiveIds!.isEmpty) &&
      (searchQuery == null || searchQuery!.isEmpty);

  /// Returns `true` if any filter is active.
  bool get isNotEmpty => !isEmpty;

  /// Number of active filters (for badge display).
  int get activeFilterCount {
    int count = 0;
    if (sendAt != null && sendAt != SendAtFilter.all) count++;
    if (senderIds != null && senderIds!.isNotEmpty) count++;
    if (fromDate != null) count++;
    if (toDate != null) count++;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) count++;
    if (selectedAccounts != null && selectedAccounts!.isNotEmpty) count++;
    return count;
  }

  /// Converts to the JSON format expected by the API `filters` field.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> filters = {};

    if (sendAt != null && sendAt != SendAtFilter.all) {
      filters['send_at'] = sendAt!.apiValue;
    }
    if (senderIds != null && senderIds!.isNotEmpty) {
      filters['sender_ids'] = senderIds;
    }
    if (fromDate != null) {
      filters['from_date'] =
          '${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}';
    }
    if (toDate != null) {
      filters['to_date'] =
          '${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}';
    }
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      filters['full_phone_number'] = phoneNumber;
    }
    if (selectedAccounts != null && selectedAccounts!.isNotEmpty) {
      filters['selected_accounts'] = selectedAccounts;
    }
    if (archiveIds != null && archiveIds!.isNotEmpty) {
      filters['archive_ids'] = archiveIds;
    }

    return filters;
  }

  ArchiveFilter copyWith({
    SendAtFilter? sendAt,
    List<int>? senderIds,
    DateTime? fromDate,
    DateTime? toDate,
    String? phoneNumber,
    List<int>? selectedAccounts,
    List<int>? archiveIds,
    String? searchQuery,
    bool clearSendAt = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearPhoneNumber = false,
    bool clearSearchQuery = false,
  }) {
    return ArchiveFilter(
      sendAt: clearSendAt ? null : (sendAt ?? this.sendAt),
      senderIds: senderIds ?? this.senderIds,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      phoneNumber:
          clearPhoneNumber ? null : (phoneNumber ?? this.phoneNumber),
      selectedAccounts: selectedAccounts ?? this.selectedAccounts,
      archiveIds: archiveIds ?? this.archiveIds,
      searchQuery:
          clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  /// Returns a new [ArchiveFilter] with all fields reset to null.
  factory ArchiveFilter.empty() => const ArchiveFilter();

  @override
  String toString() => 'ArchiveFilter(sendAt: $sendAt, '
      'senderIds: $senderIds, fromDate: $fromDate, toDate: $toDate, '
      'phone: $phoneNumber, accounts: $selectedAccounts)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Archive Count Result
// ─────────────────────────────────────────────────────────────────────────────

/// Response model from the archive count endpoint.
class ArchiveCountResult {
  const ArchiveCountResult({
    required this.count,
    this.totalCost,
  });

  final int count;
  final double? totalCost;

  factory ArchiveCountResult.fromJson(Map<String, dynamic> json) {
    return ArchiveCountResult(
      count: _parseInt(json['count'] ?? json['total'] ?? 0),
      totalCost: _parseDouble(json['total_cost'] ?? json['cost']),
    );
  }

  @override
  String toString() => 'ArchiveCountResult(count: $count, cost: $totalCost)';
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

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
