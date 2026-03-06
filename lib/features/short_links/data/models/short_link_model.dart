/// Model representing a shortened URL created through the ORBIT platform.
class ShortLinkModel {
  const ShortLinkModel({
    required this.id,
    required this.originalUrl,
    required this.shortUrl,
    required this.clickCount,
    required this.createdAt,
  });

  /// Unique identifier.
  final int id;

  /// The original full-length URL.
  final String originalUrl;

  /// The shortened URL.
  final String shortUrl;

  /// Total number of clicks on the short link.
  final int clickCount;

  /// When this short link was created.
  final DateTime createdAt;

  factory ShortLinkModel.fromJson(Map<String, dynamic> json) {
    return ShortLinkModel(
      id: json['id'] as int? ?? 0,
      originalUrl: json['original_url'] as String? ?? '',
      shortUrl: json['short_url'] as String? ?? '',
      clickCount: json['click_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_url': originalUrl,
      'short_url': shortUrl,
      'click_count': clickCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortLinkModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ShortLinkModel(id: $id, shortUrl: $shortUrl, clicks: $clickCount)';
}
