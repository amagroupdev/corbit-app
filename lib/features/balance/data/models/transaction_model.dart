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

  /// Localization key for the status label.
  String get statusLabelKey {
    return switch (status.toLowerCase()) {
      'pending' => 'statusPending',
      'approved' => 'statusApproved',
      'waiting' => 'statusWaiting',
      'rejected' => 'statusRejected_',
      _ => status,
    };
  }

  /// Human-readable status label (uses key-based lookup).
  String get statusLabel => statusLabelKey;

  /// Localization key for the payment method label.
  String get paymentMethodLabelKey {
    return switch (paymentMethod.toLowerCase()) {
      'online' => 'onlinePaymentNoon',
      'bank_transfer' || 'transfare' => 'bankTransfer',
      'stc_pay' => 'stcPay',
      'sadad' => 'sadad',
      _ => paymentMethod,
    };
  }

  /// Human-readable payment method label (uses key-based lookup).
  String get paymentMethodLabel => paymentMethodLabelKey;

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
