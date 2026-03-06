/// Data model representing a balance transaction.
///
/// Maps to the JSON returned by the transactions API endpoint.
class TransactionModel {
  const TransactionModel({
    required this.id,
    this.amount = 0,
    this.smsCount = 0,
    this.status = '',
    this.paymentMethod = '',
    this.referenceNumber,
    this.notes,
    this.createdAt,
  });

  /// Unique identifier.
  final int id;

  /// Transaction amount in SAR.
  final double amount;

  /// Number of SMS credits.
  final int smsCount;

  /// Status: pending, approved, waiting, rejected.
  final String status;

  /// Payment method: online, bank_transfer, stc_pay, sadad.
  final String paymentMethod;

  /// External reference number.
  final String? referenceNumber;

  /// Additional notes.
  final String? notes;

  /// When the transaction was created.
  final DateTime? createdAt;

  /// Deserializes a JSON map into a [TransactionModel].
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int? ?? 0,
      amount: _parseDouble(json['amount']) ?? 0,
      smsCount: json['sms_count'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      // API returns 'method', not 'payment_method'.
      paymentMethod: json['payment_method'] as String? ?? json['method'] as String? ?? '',
      referenceNumber: json['reference_number'] as String? ??
          json['invoice_no'] as String? ??
          json['bank'] as String?,
      notes: json['notes'] as String? ?? json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'sms_count': smsCount,
      'status': status,
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Human-readable status label in Arabic.
  String get statusLabel {
    return switch (status.toLowerCase()) {
      'pending' => '\u0642\u064A\u062F \u0627\u0644\u0627\u0646\u062A\u0638\u0627\u0631',
      'approved' => '\u0645\u0648\u0627\u0641\u0642 \u0639\u0644\u064A\u0647',
      'waiting' => '\u0628\u0627\u0646\u062A\u0638\u0627\u0631 \u0627\u0644\u0645\u0631\u0627\u062C\u0639\u0629',
      'rejected' => '\u0645\u0631\u0641\u0648\u0636',
      _ => status,
    };
  }

  /// Human-readable payment method label in Arabic.
  String get paymentMethodLabel {
    return switch (paymentMethod.toLowerCase()) {
      'online' => 'Noon \u062F\u0641\u0639 \u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A',
      'bank_transfer' || 'transfare' => '\u062A\u062D\u0648\u064A\u0644 \u0628\u0646\u0643\u064A',
      'stc_pay' => 'STC Pay',
      'sadad' => '\u0633\u062F\u0627\u062F',
      _ => paymentMethod,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'TransactionModel(id: $id, amount: $amount, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
