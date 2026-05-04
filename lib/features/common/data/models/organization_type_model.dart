/// An organization category returned by `GET /common/organization-types`.
///
/// Server response shape (V3):
/// ```json
/// { "id": 3, "name": "جمعية خيرية", "name_en": "Charitable Society" }
/// ```
class OrganizationTypeModel {
  const OrganizationTypeModel({
    required this.id,
    required this.name,
    this.nameEn,
  });

  /// Organization-type primary key.
  final int id;

  /// Localized name (Arabic by default).
  final String name;

  /// Optional English name when available.
  final String? nameEn;

  factory OrganizationTypeModel.fromJson(Map<String, dynamic> json) =>
      OrganizationTypeModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        nameEn: json['name_en'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (nameEn != null) 'name_en': nameEn,
      };

  @override
  String toString() => 'OrganizationTypeModel(id: $id, name: $name)';
}
