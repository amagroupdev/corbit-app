/// Model representing a promotional banner returned by the V3 endpoints
/// `GET /banners/login` and `GET /banners/dashboard`.
///
/// The API shape (per the Postman master collection) is:
/// ```json
/// {
///   "id": 1,
///   "title": "...",
///   "image_url": "https://...",
///   "link_url": "https://...",
///   "sort_order": 0
/// }
/// ```
///
/// All fields except [id] and [imageUrl] are optional/safe-defaulted so the
/// model survives schema drift between the Login (no-auth) and Dashboard
/// (auth) variants.
class BannerModel {
  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.linkUrl,
    this.sortOrder = 0,
  });

  final int id;
  final String imageUrl;
  final String title;
  final String? linkUrl;
  final int sortOrder;

  bool get hasLink => linkUrl != null && linkUrl!.trim().isNotEmpty;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: _parseInt(json['id']) ?? 0,
      imageUrl: (json['image_url'] as String?) ??
          (json['image'] as String?) ??
          '',
      title: (json['title'] as String?) ?? '',
      linkUrl: (json['link_url'] as String?) ?? (json['link'] as String?),
      sortOrder: _parseInt(json['sort_order']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title': title,
      'link_url': linkUrl,
      'sort_order': sortOrder,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BannerModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
