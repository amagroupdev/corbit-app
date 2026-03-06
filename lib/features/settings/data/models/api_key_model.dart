/// Data model representing an API key in the ORBIT SMS V3 system.
///
/// Maps to the JSON returned by `/settings/api-keys` endpoints.
class ApiKeyModel {
  const ApiKeyModel({
    required this.id,
    this.name,
    this.key,
    this.lastUsedAt,
    this.createdAt,
  });

  final int id;
  final String? name;
  final String? key;
  final String? lastUsedAt;
  final String? createdAt;

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) {
    return ApiKeyModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      key: json['key'] as String? ?? json['api_key'] as String?,
      lastUsedAt: json['last_used_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (key != null) 'key': key,
    };
  }

  /// Returns a masked version of the key for display purposes.
  /// Shows first 8 and last 4 characters: `abc12345...xyz9`
  String get maskedKey {
    if (key == null || key!.length < 16) return key ?? '***';
    return '${key!.substring(0, 8)}...${key!.substring(key!.length - 4)}';
  }

  @override
  String toString() => 'ApiKeyModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiKeyModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
