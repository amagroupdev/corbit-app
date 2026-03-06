/// Model representing an occasion card (greeting card) in the ORBIT platform.
class OccasionCardModel {
  const OccasionCardModel({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.message,
    required this.recipientCount,
    required this.status,
    required this.createdAt,
    this.templateImageUrl,
  });

  final int id;
  final int templateId;
  final String templateName;
  final String message;
  final int recipientCount;
  final String status;
  final DateTime createdAt;
  final String? templateImageUrl;

  bool get isSent => status == 'sent';

  factory OccasionCardModel.fromJson(Map<String, dynamic> json) {
    return OccasionCardModel(
      id: json['id'] as int? ?? 0,
      templateId: json['template_id'] as int? ?? 0,
      templateName: json['template_name'] as String? ?? '',
      message: json['message'] as String? ?? '',
      recipientCount: json['recipient_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      templateImageUrl: json['template_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'template_name': templateName,
      'message': message,
      'recipient_count': recipientCount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'template_image_url': templateImageUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OccasionCardModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model representing an occasion card template.
class OccasionCardTemplateModel {
  const OccasionCardTemplateModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
  });

  final int id;
  final String name;
  final String imageUrl;
  final String category;

  factory OccasionCardTemplateModel.fromJson(Map<String, dynamic> json) {
    return OccasionCardTemplateModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'category': category,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OccasionCardTemplateModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
