/// Models for `POST /messages/dlr-by-number`.
///
/// The endpoint takes a single phone number and returns a flat list of all
/// messages sent to that number with their delivery-receipt (DLR) status
/// and timeline.
///
/// Response shape:
/// ```json
/// {
///   "success": true,
///   "data": [
///     {
///       "number": "+9665XXXXXXXX",
///       "message_uuid": "abc-123",
///       "dlr_status": "delivered",
///       "dlr_history": [
///         {"status": "sent",       "timestamp": "2026-04-30T12:00:00Z"},
///         {"status": "delivered",  "timestamp": "2026-04-30T12:00:03Z"}
///       ]
///     }
///   ]
/// }
/// ```
library;

class DlrHistoryEntry {
  const DlrHistoryEntry({
    required this.status,
    required this.timestamp,
  });

  final String status;
  final DateTime timestamp;

  factory DlrHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DlrHistoryEntry(
      status: (json['status'] as String?)?.trim() ?? 'unknown',
      timestamp: DateTime.tryParse(
            json['timestamp'] as String? ??
                json['created_at'] as String? ??
                json['at'] as String? ??
                '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class DlrReportEntry {
  const DlrReportEntry({
    required this.number,
    required this.messageUuid,
    required this.dlrStatus,
    required this.dlrHistory,
    this.messageBody,
    this.senderName,
    this.sentAt,
  });

  /// E.164 phone number of the recipient.
  final String number;

  /// UUID of the parent message (used to navigate to its receipt report).
  final String messageUuid;

  /// Latest DLR status: `sent`, `delivered`, `failed`, `expired`,
  /// `rejected`, `pending`, etc.
  final String dlrStatus;

  /// Chronological list of status transitions with timestamps.
  final List<DlrHistoryEntry> dlrHistory;

  /// Optional message body returned by the server (some V3 builds include
  /// it for context).
  final String? messageBody;

  /// Optional sender name returned by the server.
  final String? senderName;

  /// Original send timestamp, when available.
  final DateTime? sentAt;

  factory DlrReportEntry.fromJson(Map<String, dynamic> json) {
    final history = (json['dlr_history'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(DlrHistoryEntry.fromJson)
            .toList() ??
        const <DlrHistoryEntry>[];

    return DlrReportEntry(
      number: (json['number'] as String?)?.trim() ??
          (json['phone'] as String?)?.trim() ??
          '',
      messageUuid: (json['message_uuid'] as String?)?.trim() ??
          (json['uuid'] as String?)?.trim() ??
          '',
      dlrStatus: (json['dlr_status'] as String?)?.trim() ??
          (json['status'] as String?)?.trim() ??
          'unknown',
      dlrHistory: history,
      messageBody: json['message_body'] as String? ?? json['message'] as String?,
      senderName: json['sender_name'] as String?,
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'] as String)
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'message_uuid': messageUuid,
      'dlr_status': dlrStatus,
      'dlr_history': dlrHistory.map((e) => e.toJson()).toList(),
      if (messageBody != null) 'message_body': messageBody,
      if (senderName != null) 'sender_name': senderName,
      if (sentAt != null) 'sent_at': sentAt!.toIso8601String(),
    };
  }
}
