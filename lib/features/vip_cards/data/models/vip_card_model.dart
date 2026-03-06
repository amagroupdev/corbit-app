/// Model representing a VIP card sent through the ORBIT platform.
class VipCardModel {
  const VipCardModel({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.cardNumber,
    required this.status,
    required this.createdAt,
    this.expiresAt,
  });

  final int id;
  final String recipientName;
  final String recipientPhone;
  final String cardNumber;
  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;

  bool get isSent => status == 'sent';
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory VipCardModel.fromJson(Map<String, dynamic> json) {
    return VipCardModel(
      id: json['id'] as int? ?? 0,
      recipientName: json['recipient_name'] as String? ?? '',
      recipientPhone: json['recipient_phone'] as String? ?? '',
      cardNumber: json['card_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'card_number': cardNumber,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VipCardModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
