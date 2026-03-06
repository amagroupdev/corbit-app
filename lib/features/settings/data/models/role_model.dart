/// Data model representing a role in the ORBIT SMS V3 system.
///
/// Roles define sets of permissions that can be assigned to sub-accounts.
/// Maps to the JSON returned by `/settings/roles` endpoints.
class RoleModel {
  const RoleModel({
    required this.id,
    this.name,
    this.description,
    this.permissions = const [],
    this.usersCount = 0,
    this.createdAt,
  });

  final int id;
  final String? name;
  final String? description;
  final List<int> permissions;
  final int usersCount;
  final String? createdAt;

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      description: json['description'] as String?,
      permissions: _parsePermissionIds(json['permissions']),
      usersCount: json['users_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      'permissions': permissions,
    };
  }

  RoleModel copyWith({
    int? id,
    String? name,
    String? description,
    List<int>? permissions,
    int? usersCount,
    String? createdAt,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      usersCount: usersCount ?? this.usersCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<int> _parsePermissionIds(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) {
        if (e is int) return e;
        if (e is Map<String, dynamic>) return e['id'] as int? ?? 0;
        return 0;
      }).toList();
    }
    return [];
  }

  @override
  String toString() => 'RoleModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
