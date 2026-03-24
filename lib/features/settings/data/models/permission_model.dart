/// Data model representing a permission in the ORBIT SMS V3 system.
///
/// Permissions are grouped by category and can be assigned to roles.
/// Maps to the JSON returned by `/settings/roles/permissions`.
class PermissionModel {
  const PermissionModel({
    required this.id,
    this.name,
    this.displayName,
    this.group,
  });

  final int id;
  final String? name;
  final String? displayName;
  final String? group;

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      displayName: json['display_name'] as String? ?? json['name'] as String?,
      group: json['group'] as String? ?? json['group_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (group != null) 'group': group,
    };
  }

  @override
  String toString() => 'PermissionModel(id: $id, name: $name, group: $group)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Groups permissions by their category for display in the role editor.
class PermissionGroup {
  const PermissionGroup({
    required this.name,
    required this.permissions,
  });

  final String name;
  final List<PermissionModel> permissions;

  /// Organizes a flat list of permissions into groups.
  static List<PermissionGroup> groupPermissions(List<PermissionModel> all) {
    final Map<String, List<PermissionModel>> grouped = {};
    for (final permission in all) {
      final groupName = permission.group ?? 'permission_group_general';
      grouped.putIfAbsent(groupName, () => []).add(permission);
    }
    return grouped.entries
        .map((e) => PermissionGroup(name: e.key, permissions: e.value))
        .toList();
  }
}
