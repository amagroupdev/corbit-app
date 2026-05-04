/// A single transfer record between sub-accounts.
class SubaccountTransferModel {
  const SubaccountTransferModel({
    required this.id,
    required this.fromUsername,
    required this.toUsername,
    required this.amount,
    required this.createdAt,
    this.note,
    this.status,
  });

  final int id;
  final String fromUsername;
  final String toUsername;
  final double amount;
  final String createdAt;
  final String? note;
  final String? status;

  factory SubaccountTransferModel.fromJson(Map<String, dynamic> json) {
    return SubaccountTransferModel(
      id: _parseInt(json['id']) ?? 0,
      fromUsername: (json['from_username'] ??
              json['from'] ??
              json['from_user'] ??
              '')
          .toString(),
      toUsername:
          (json['to_username'] ?? json['to'] ?? json['to_user'] ?? '')
              .toString(),
      amount: _parseDouble(json['amount']) ?? 0.0,
      createdAt: (json['created_at'] ?? json['date'] ?? '').toString(),
      note: json['note']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'from_username': fromUsername,
        'to_username': toUsername,
        'amount': amount,
        'created_at': createdAt,
        if (note != null) 'note': note,
        if (status != null) 'status': status,
      };

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

/// Aggregate report for sub-account transfers.
class SubaccountTransferReportModel {
  const SubaccountTransferReportModel({
    this.totalTransfers = 0,
    this.totalAmount = 0,
    this.uniqueRecipients = 0,
    this.raw = const {},
  });

  final int totalTransfers;
  final double totalAmount;
  final int uniqueRecipients;
  final Map<String, dynamic> raw;

  factory SubaccountTransferReportModel.fromJson(Map<String, dynamic> json) {
    return SubaccountTransferReportModel(
      totalTransfers: _parseInt(
              json['total_transfers'] ?? json['count'] ?? json['total']) ??
          0,
      totalAmount: _parseDouble(
              json['total_amount'] ?? json['amount'] ?? json['sum']) ??
          0.0,
      uniqueRecipients:
          _parseInt(json['unique_recipients'] ?? json['recipients']) ?? 0,
      raw: json,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
