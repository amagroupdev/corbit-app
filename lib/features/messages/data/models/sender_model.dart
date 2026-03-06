/// Model representing an SMS sender name registered with the gateway.
///
/// Sender names are pre-approved by the telecom operator and linked to
/// the user's account. They appear as the "From" field on the recipient's
/// phone.
class SenderModel {
  const SenderModel({
    required this.id,
    required this.name,
    required this.status,
  });

  /// Unique identifier of the sender name.
  final int id;

  /// The sender name string (e.g. "ORBIT", "MyCompany").
  final String name;

  /// Approval status: 'active', 'pending', 'rejected'.
  final String status;

  /// Whether this sender name can be used for sending messages.
  bool get isActive => status == 'active' || status == 'approved';

  factory SenderModel.fromJson(Map<String, dynamic> json) {
    return SenderModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SenderModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SenderModel(id: $id, name: $name, status: $status)';
}
