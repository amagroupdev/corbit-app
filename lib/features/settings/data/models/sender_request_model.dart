/// Data model representing a sender name request in the ORBIT SMS V3 system.
///
/// Maps to the JSON returned by `/settings/senders` endpoints.
class SenderRequestModel {
  const SenderRequestModel({
    required this.id,
    this.name,
    this.organizationName,
    this.organizationType,
    this.status,
    this.rejectionReason,
    this.commercialRegisterUrl,
    this.documentUrl,
    this.paymentStatus,
    this.paymentUrl,
    this.price,
    this.createdAt,
  });

  final int id;
  final String? name;
  final String? organizationName;
  final String? organizationType;
  final String? status;
  final String? rejectionReason;
  final String? commercialRegisterUrl;
  final String? documentUrl;
  final String? paymentStatus;
  final String? paymentUrl;
  final double? price;
  final String? createdAt;

  factory SenderRequestModel.fromJson(Map<String, dynamic> json) {
    return SenderRequestModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? json['sender_name'] as String?,
      organizationName: json['organization_name'] as String?,
      organizationType: json['organization_type'] as String?,
      status: json['status'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      commercialRegisterUrl: json['commercial_register_url'] as String?,
      documentUrl: json['document_url'] as String?,
      paymentStatus: json['payment_status'] as String?,
      paymentUrl: json['payment_url'] as String?,
      price: _parseDouble(json['price']),
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (organizationName != null) 'organization_name': organizationName,
      if (organizationType != null) 'organization_type': organizationType,
      if (status != null) 'status': status,
    };
  }

  /// Returns the display-friendly status label in Arabic.
  String get statusLabel {
    return switch (status?.toLowerCase()) {
      'pending' => 'قيد المراجعة',
      'approved' => 'مقبول',
      'rejected' => 'مرفوض',
      'active' => 'نشط',
      'inactive' => 'غير نشط',
      'payment_pending' => 'بانتظار الدفع',
      _ => status ?? 'غير محدد',
    };
  }

  /// Returns true if the request is in a pending state.
  bool get isPending => status?.toLowerCase() == 'pending';

  /// Returns true if the request has been approved.
  bool get isApproved => status?.toLowerCase() == 'approved' || status?.toLowerCase() == 'active';

  /// Returns true if the request has been rejected.
  bool get isRejected => status?.toLowerCase() == 'rejected';

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'SenderRequestModel(id: $id, name: $name, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SenderRequestModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
