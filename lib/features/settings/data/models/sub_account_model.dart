/// Data model representing a sub-account in the ORBIT SMS V3 system.
///
/// Maps to the JSON returned by `/settings/sub-accounts` endpoints.
class SubAccountModel {
  const SubAccountModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.roleId,
    this.senderNames = const [],
    this.isActive = true,
    this.apiAccess = false,
    this.annualBalance,
    this.categoryId,
    this.categoryName,
    this.createdAt,
  });

  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final int? roleId;
  final List<String> senderNames;
  final bool isActive;
  final bool apiAccess;
  final double? annualBalance;
  final int? categoryId;
  final String? categoryName;
  final String? createdAt;

  factory SubAccountModel.fromJson(Map<String, dynamic> json) {
    return SubAccountModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? json['role_name'] as String?,
      roleId: json['role_id'] as int?,
      senderNames: _parseSenderNames(json['sender_names']),
      isActive: json['is_active'] as bool? ?? true,
      apiAccess: json['api_access'] as bool? ?? false,
      annualBalance: _parseDouble(json['annual_balance']),
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (roleId != null) 'role_id': roleId,
      'sender_names': senderNames,
      'is_active': isActive,
      'api_access': apiAccess,
      if (annualBalance != null) 'annual_balance': annualBalance,
      if (categoryId != null) 'category_id': categoryId,
    };
  }

  SubAccountModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    int? roleId,
    List<String>? senderNames,
    bool? isActive,
    bool? apiAccess,
    double? annualBalance,
    int? categoryId,
    String? categoryName,
    String? createdAt,
  }) {
    return SubAccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      roleId: roleId ?? this.roleId,
      senderNames: senderNames ?? this.senderNames,
      isActive: isActive ?? this.isActive,
      apiAccess: apiAccess ?? this.apiAccess,
      annualBalance: annualBalance ?? this.annualBalance,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<String> _parseSenderNames(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  String toString() => 'SubAccountModel(id: $id, name: $name, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubAccountModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model for sub-account categories.
class SubAccountCategoryModel {
  const SubAccountCategoryModel({
    required this.id,
    this.name,
    this.description,
    this.subAccountsCount = 0,
    this.createdAt,
  });

  final int id;
  final String? name;
  final String? description;
  final int subAccountsCount;
  final String? createdAt;

  factory SubAccountCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubAccountCategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      description: json['description'] as String?,
      subAccountsCount: json['sub_accounts_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    };
  }

  @override
  String toString() => 'SubAccountCategoryModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubAccountCategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model for balance reminder settings.
class BalanceReminderModel {
  const BalanceReminderModel({
    this.isEnabled = false,
    this.threshold = 0,
    this.email,
    this.phone,
  });

  final bool isEnabled;
  final int threshold;
  final String? email;
  final String? phone;

  factory BalanceReminderModel.fromJson(Map<String, dynamic> json) {
    return BalanceReminderModel(
      isEnabled: json['is_enabled'] as bool? ?? false,
      threshold: json['threshold'] as int? ?? 0,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      'threshold': threshold,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
  }

  BalanceReminderModel copyWith({
    bool? isEnabled,
    int? threshold,
    String? email,
    String? phone,
  }) {
    return BalanceReminderModel(
      isEnabled: isEnabled ?? this.isEnabled,
      threshold: threshold ?? this.threshold,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
