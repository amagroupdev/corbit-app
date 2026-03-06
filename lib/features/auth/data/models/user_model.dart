/// Data model representing an authenticated user in the ORBIT SMS V3 system.
///
/// Maps directly to the JSON structure returned by the API's user endpoints.
/// Supports both full and partial hydration (some fields may be null depending
/// on the endpoint).
class UserModel {
  const UserModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.username,
    this.userTypeId,
    this.gender,
    this.cityId,
    this.regionId,
    this.profilePhotoUrl,
    this.organizationName,
    this.ministerialNumber,
    this.isActive,
    this.isVerified,
    this.createdAt,
  });

  /// Unique user identifier.
  final int id;

  /// User's full display name.
  final String? name;

  /// Email address.
  final String? email;

  /// Mobile phone number (including country code, e.g. +966XXXXXXXXX).
  final String? phone;

  /// Unique login username.
  final String? username;

  /// Account type identifier:
  /// 1 = Individual, 2 = School, 3 = Company, 4 = Government.
  final int? userTypeId;

  /// Gender: 'male' or 'female'.
  final String? gender;

  /// City identifier for the user's address.
  final int? cityId;

  /// Region / province identifier.
  final int? regionId;

  /// Absolute URL to the user's profile photo, if uploaded.
  final String? profilePhotoUrl;

  /// Organization / company name (for non-individual accounts).
  final String? organizationName;

  /// Ministerial number (for school / government accounts).
  final String? ministerialNumber;

  /// Whether the account is currently active.
  final bool? isActive;

  /// Whether the phone number has been verified via OTP.
  final bool? isVerified;

  /// ISO-8601 timestamp of account creation.
  final String? createdAt;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [UserModel] from a JSON map returned by the API.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      username: json['username'] as String?,
      userTypeId: json['user_type_id'] as int?,
      gender: json['gender'] as String?,
      cityId: json['city_id'] as int?,
      regionId: json['region_id'] as int?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      organizationName: json['organization_name'] as String?,
      ministerialNumber: json['ministerial_number'] as String?,
      isActive: json['is_active'] as bool?,
      isVerified: json['is_verified'] as bool?,
      createdAt: json['created_at'] as String?,
    );
  }

  /// Converts this model to a JSON map suitable for API requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (username != null) 'username': username,
      if (userTypeId != null) 'user_type_id': userTypeId,
      if (gender != null) 'gender': gender,
      if (cityId != null) 'city_id': cityId,
      if (regionId != null) 'region_id': regionId,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (organizationName != null) 'organization_name': organizationName,
      if (ministerialNumber != null) 'ministerial_number': ministerialNumber,
      if (isActive != null) 'is_active': isActive,
      if (isVerified != null) 'is_verified': isVerified,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// Human-readable label for the account type.
  String get userTypeLabel {
    return switch (userTypeId) {
      1 => 'فرد',
      2 => 'مدرسة',
      3 => 'شركة',
      4 => 'جهة حكومية',
      _ => 'غير محدد',
    };
  }

  /// Creates a copy of this model with the given fields replaced.
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? username,
    int? userTypeId,
    String? gender,
    int? cityId,
    int? regionId,
    String? profilePhotoUrl,
    String? organizationName,
    String? ministerialNumber,
    bool? isActive,
    bool? isVerified,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      userTypeId: userTypeId ?? this.userTypeId,
      gender: gender ?? this.gender,
      cityId: cityId ?? this.cityId,
      regionId: regionId ?? this.regionId,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      organizationName: organizationName ?? this.organizationName,
      ministerialNumber: ministerialNumber ?? this.ministerialNumber,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, username: $username)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
