/// A Saudi city / governorate returned by `GET /common/cities`.
///
/// Server response shape (V3):
/// ```json
/// { "id": 12, "name": "جدة", "name_en": "Jeddah", "region_id": 2 }
/// ```
///
/// Note: the V3 server reads from the `governorates` table — the
/// previous static `city_id` validation was removed (Postman: "city_id removed").
class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.regionId,
  });

  /// City primary key.
  final int id;

  /// Localized name (Arabic by default).
  final String name;

  /// Optional English name when available.
  final String? nameEn;

  /// Foreign key linking the city to its [RegionModel.id].
  final int? regionId;

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        nameEn: json['name_en'] as String?,
        regionId: json['region_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (nameEn != null) 'name_en': nameEn,
        if (regionId != null) 'region_id': regionId,
      };

  @override
  String toString() =>
      'CityModel(id: $id, name: $name, regionId: $regionId)';
}
