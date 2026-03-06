/// Data model representing a contact group.
///
/// Maps to the JSON structure returned by the groups API endpoints.
class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    this.numbersCount = 0,
    this.createdAt,
    this.deletedAt,
  });

  /// Unique identifier.
  final int id;

  /// Group display name.
  final String name;

  /// Number of phone numbers in this group.
  final int numbersCount;

  /// When the group was created.
  final DateTime? createdAt;

  /// Non-null when the group has been soft-deleted (trashed).
  final DateTime? deletedAt;

  /// Whether this group is currently in the trash.
  bool get isTrashed => deletedAt != null;

  /// Deserializes a JSON map into a [GroupModel].
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      numbersCount: json['numbers_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
    );
  }

  /// Serializes this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'numbers_count': numbersCount,
      'created_at': createdAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Creates a copy with optional field overrides.
  GroupModel copyWith({
    int? id,
    String? name,
    int? numbersCount,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      numbersCount: numbersCount ?? this.numbersCount,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() =>
      'GroupModel(id: $id, name: $name, numbersCount: $numbersCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
