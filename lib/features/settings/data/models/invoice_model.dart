/// Data model representing an invoice in the ORBIT SMS V3 system.
///
/// Maps to the JSON returned by `/settings/invoices` endpoints.
class InvoiceModel {
  const InvoiceModel({
    required this.id,
    this.number,
    this.amount,
    this.tax,
    this.totalAmount,
    this.date,
    this.dueDate,
    this.status,
    this.items = const [],
    this.paymentMethod,
    this.notes,
    this.createdAt,
  });

  final int id;
  final String? number;
  final double? amount;
  final double? tax;
  final double? totalAmount;
  final String? date;
  final String? dueDate;
  final String? status;
  final List<InvoiceItemModel> items;
  final String? paymentMethod;
  final String? notes;
  final String? createdAt;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String? ?? json['invoice_number'] as String?,
      amount: _parseDouble(json['amount']),
      tax: _parseDouble(json['tax']),
      totalAmount: _parseDouble(json['total_amount'] ?? json['total']),
      date: json['date'] as String? ?? json['invoice_date'] as String?,
      dueDate: json['due_date'] as String?,
      status: json['status'] as String?,
      items: _parseItems(json['items']),
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (number != null) 'number': number,
      if (amount != null) 'amount': amount,
      if (tax != null) 'tax': tax,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
    };
  }

  /// Returns the display-friendly status label in Arabic.
  String get statusLabel {
    return switch (status?.toLowerCase()) {
      'paid' => 'مدفوعة',
      'unpaid' => 'غير مدفوعة',
      'pending' => 'قيد الانتظار',
      'overdue' => 'متأخرة',
      'cancelled' => 'ملغاة',
      'refunded' => 'مستردة',
      _ => status ?? 'غير محدد',
    };
  }

  /// Returns true if the invoice status is considered a completed payment.
  bool get isPaid => status?.toLowerCase() == 'paid';

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<InvoiceItemModel> _parseItems(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((e) => InvoiceItemModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  String toString() =>
      'InvoiceModel(id: $id, number: $number, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// An individual line item within an invoice.
class InvoiceItemModel {
  const InvoiceItemModel({
    this.id,
    this.description,
    this.quantity,
    this.unitPrice,
    this.total,
  });

  final int? id;
  final String? description;
  final int? quantity;
  final double? unitPrice;
  final double? total;

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'] as int?,
      description: json['description'] as String?,
      quantity: json['quantity'] as int?,
      unitPrice: _parseDouble(json['unit_price'] ?? json['price']),
      total: _parseDouble(json['total']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
