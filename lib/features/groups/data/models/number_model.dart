/// Data model representing a phone number within a group.
///
/// Maps to the JSON structure returned by the numbers API endpoints.
class NumberModel {
  const NumberModel({
    required this.id,
    required this.groupId,
    this.name = '',
    required this.number,
    this.identifier,
    this.createdAt,
  });

  /// Unique identifier.
  final int id;

  /// The ID of the group this number belongs to.
  final int groupId;

  /// Contact name associated with this number.
  final String name;

  /// The phone number string.
  final String number;

  /// Optional extra identifier (e.g. national ID, employee ID).
  final String? identifier;

  /// When this number was created.
  final DateTime? createdAt;

  /// Deserializes a JSON map into a [NumberModel].
  factory NumberModel.fromJson(Map<String, dynamic> json) {
    return NumberModel(
      id: json['id'] as int? ?? 0,
      groupId: json['group_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      number: json['number'] as String? ?? '',
      identifier: json['identifier'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Serializes this model to a JSON map suitable for API requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'number': number,
      if (identifier != null) 'identifier': identifier,
    };
  }

  /// Creates a copy with optional field overrides.
  NumberModel copyWith({
    int? id,
    int? groupId,
    String? name,
    String? number,
    String? identifier,
    DateTime? createdAt,
  }) {
    return NumberModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      number: number ?? this.number,
      identifier: identifier ?? this.identifier,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'NumberModel(id: $id, groupId: $groupId, name: $name, number: $number)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumberModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
