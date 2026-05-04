/// A Saudi region returned by `GET /common/regions`.
///
/// Server response shape (V3):
/// ```json
/// { "id": 1, "name": "الرياض", "name_en": "Riyadh" }
/// ```
class RegionModel {
  const RegionModel({
    required this.id,
    required this.name,
    this.nameEn,
  });

  /// Region primary key (matches `region_id` on dependent endpoints).
  final int id;

  /// Localized name (Arabic by default).
  final String name;

  /// Optional English name when available.
  final String? nameEn;

  factory RegionModel.fromJson(Map<String, dynamic> json) => RegionModel(
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
  String toString() => 'RegionModel(id: $id, name: $name)';
}
