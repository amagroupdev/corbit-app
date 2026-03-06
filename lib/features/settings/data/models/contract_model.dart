/// Data model representing a contract in the ORBIT SMS V3 system.
///
/// Maps to the JSON returned by `/settings/contracts` endpoints.
class ContractModel {
  const ContractModel({
    required this.id,
    this.organizationName,
    this.organizationType,
    this.status,
    this.documentUrl,
    this.startDate,
    this.endDate,
    this.notes,
    this.createdAt,
  });

  final int id;
  final String? organizationName;
  final String? organizationType;
  final String? status;
  final String? documentUrl;
  final String? startDate;
  final String? endDate;
  final String? notes;
  final String? createdAt;

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] as int? ?? 0,
      organizationName: json['organization_name'] as String?,
      organizationType: json['organization_type'] as String?,
      status: json['status'] as String?,
      documentUrl: json['document_url'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (organizationName != null) 'organization_name': organizationName,
      if (organizationType != null) 'organization_type': organizationType,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  /// Returns the display-friendly status label in Arabic.
  String get statusLabel {
    return switch (status?.toLowerCase()) {
      'active' => 'نشط',
      'inactive' => 'غير نشط',
      'pending' => 'قيد المراجعة',
      'expired' => 'منتهي',
      'cancelled' => 'ملغي',
      _ => status ?? 'غير محدد',
    };
  }

  /// Returns true if the contract is currently active.
  bool get isActive => status?.toLowerCase() == 'active';

  @override
  String toString() =>
      'ContractModel(id: $id, organization: $organizationName, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContractModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
