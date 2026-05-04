/// Model for `GET /messages/{uuid}/receipt-report`.
///
/// Server returns a comprehensive report combining the original message,
/// a sending summary (totals, units, cost) and a DLR summary (counts per
/// status), plus a per-recipient breakdown.
///
/// Response shape:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "message": { "uuid": "...", "body": "...", "sender_name": "..." },
///     "sending_summary": { "total_recipients": 100, "total_sms": 102, "cost": 51.0 },
///     "dlr_summary": { "delivered": 95, "failed": 3, "pending": 2 },
///     "numbers": [
///       { "number": "+9665XXXXXXXX", "dlr_status": "delivered", ... }
///     ]
///   }
/// }
/// ```
library;

import 'package:orbit_app/features/messages/data/models/dlr_report_model.dart';

/// Inner block describing the message itself.
class ReceiptReportMessage {
  const ReceiptReportMessage({
    required this.uuid,
    required this.body,
    required this.senderName,
    this.messageType,
    this.createdAt,
    this.scheduledAt,
  });

  final String uuid;
  final String body;
  final String senderName;
  final String? messageType;
  final DateTime? createdAt;
  final DateTime? scheduledAt;

  factory ReceiptReportMessage.fromJson(Map<String, dynamic> json) {
    return ReceiptReportMessage(
      uuid: (json['uuid'] as String?)?.trim() ?? '',
      body: (json['body'] as String?)?.trim() ??
          (json['message_body'] as String?)?.trim() ??
          (json['message'] as String?)?.trim() ??
          '',
      senderName: (json['sender_name'] as String?)?.trim() ?? '',
      messageType: json['message_type'] as String? ?? json['type'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
    );
  }
}

/// Counts and totals describing the send batch as a whole.
class ReceiptReportSendingSummary {
  const ReceiptReportSendingSummary({
    required this.totalRecipients,
    required this.totalSms,
    required this.cost,
  });

  final int totalRecipients;
  final int totalSms;
  final double cost;

  factory ReceiptReportSendingSummary.fromJson(Map<String, dynamic> json) {
    int readInt(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) {
          final parsed = int.tryParse(v);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    double readDouble(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is num) return v.toDouble();
        if (v is String) {
          final parsed = double.tryParse(v);
          if (parsed != null) return parsed;
        }
      }
      return 0.0;
    }

    return ReceiptReportSendingSummary(
      totalRecipients: readInt(const [
        'total_recipients',
        'recipients',
        'numbers_count',
        'recipient_count',
      ]),
      totalSms: readInt(const [
        'total_sms',
        'sms_count',
        'segments',
        'message_count',
      ]),
      cost: readDouble(const [
        'cost',
        'total_cost',
        'price',
        'cost_estimate',
      ]),
    );
  }
}

/// Counts of recipients per DLR status.
class ReceiptReportDlrSummary {
  const ReceiptReportDlrSummary({
    required this.delivered,
    required this.failed,
    required this.pending,
    required this.sent,
    required this.expired,
    required this.rejected,
    required this.unknown,
  });

  final int delivered;
  final int failed;
  final int pending;
  final int sent;
  final int expired;
  final int rejected;
  final int unknown;

  int get total =>
      delivered + failed + pending + sent + expired + rejected + unknown;

  factory ReceiptReportDlrSummary.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final v = json[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return ReceiptReportDlrSummary(
      delivered: read('delivered'),
      failed: read('failed'),
      pending: read('pending'),
      sent: read('sent'),
      expired: read('expired'),
      rejected: read('rejected'),
      unknown: read('unknown'),
    );
  }
}

class ReceiptReportModel {
  const ReceiptReportModel({
    required this.message,
    required this.sendingSummary,
    required this.dlrSummary,
    required this.numbers,
  });

  final ReceiptReportMessage message;
  final ReceiptReportSendingSummary sendingSummary;
  final ReceiptReportDlrSummary dlrSummary;

  /// Per-recipient DLR rows. Reuses [DlrReportEntry] for parity with the
  /// `dlr-by-number` endpoint.
  final List<DlrReportEntry> numbers;

  factory ReceiptReportModel.fromJson(Map<String, dynamic> json) {
    final messageJson = (json['message'] as Map<String, dynamic>?) ?? json;
    final sendingJson = (json['sending_summary'] as Map<String, dynamic>?) ??
        (json['summary'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final dlrJson = (json['dlr_summary'] as Map<String, dynamic>?) ??
        (json['dlr'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final numbers = (json['numbers'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(DlrReportEntry.fromJson)
            .toList() ??
        const <DlrReportEntry>[];

    return ReceiptReportModel(
      message: ReceiptReportMessage.fromJson(messageJson),
      sendingSummary: ReceiptReportSendingSummary.fromJson(sendingJson),
      dlrSummary: ReceiptReportDlrSummary.fromJson(dlrJson),
      numbers: numbers,
    );
  }
}
