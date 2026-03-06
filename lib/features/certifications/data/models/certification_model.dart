/// Model representing a certification record in the ORBIT platform.
class CertificationModel {
  const CertificationModel({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.status,
    required this.createdAt,
    this.profileName,
  });

  final int id;
  final String recipientName;
  final String recipientPhone;
  final String status;
  final DateTime createdAt;
  final String? profileName;

  bool get isSent => status == 'sent';

  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      id: json['id'] as int? ?? 0,
      recipientName: json['recipient_name'] as String? ?? '',
      recipientPhone: json['recipient_phone'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      profileName: json['profile_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (profileName != null) 'profile_name': profileName,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model for Noor system profile used in certification sending.
class NoorProfile {
  const NoorProfile({
    required this.id,
    required this.name,
    required this.type,
  });

  final int id;
  final String name;
  final String type;

  factory NoorProfile.fromJson(Map<String, dynamic> json) {
    return NoorProfile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }
}
