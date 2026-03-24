/// Data models for the ORBIT SMS V3 Statistics feature.
///
/// Contains [StatisticsType] enum for the three statistics categories,
/// [StatisticsItem] for individual statistics records, and
/// [StatisticsFilter] for querying/filtering statistics data.

// ─────────────────────────────────────────────────────────────────────────────
// Statistics Type Enum
// ─────────────────────────────────────────────────────────────────────────────

/// The three statistics types supported by the API.
enum StatisticsType {
  absenceLateness('absence_lateness', 'stat_type_absence_lateness'),
  customMessages('custom_messages', 'stat_type_custom_messages'),
  teacherMessages('teacher_messages', 'stat_type_teacher_messages');

  const StatisticsType(this.apiValue, this.labelKey);

  /// The value sent to the API in `statistics_type`.
  final String apiValue;

  /// Localization key for the display label.
  final String labelKey;

  /// Parses an API string value into a [StatisticsType].
  static StatisticsType fromApiValue(String value) {
    return StatisticsType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => StatisticsType.absenceLateness,
    );
  }

  /// Returns the available sub-type filter options for this statistics type.
  List<StatisticsSubType> get subTypes {
    return switch (this) {
      StatisticsType.absenceLateness => [
          const StatisticsSubType(apiValue: 'all', labelKey: 'stat_sub_all'),
          const StatisticsSubType(apiValue: 'latency', labelKey: 'stat_sub_lateness'),
          const StatisticsSubType(apiValue: 'absence', labelKey: 'stat_sub_absence'),
        ],
      StatisticsType.customMessages => [
          const StatisticsSubType(apiValue: 'all', labelKey: 'stat_sub_all'),
          const StatisticsSubType(apiValue: 'Academic Weakness', labelKey: 'stat_sub_academic_weakness'),
          const StatisticsSubType(apiValue: 'Behavourial Offence', labelKey: 'stat_sub_behavioural_offence'),
          const StatisticsSubType(apiValue: 'Distinction', labelKey: 'stat_sub_distinction'),
          const StatisticsSubType(apiValue: 'Others', labelKey: 'stat_sub_others'),
        ],
      StatisticsType.teacherMessages => [
          const StatisticsSubType(apiValue: 'all', labelKey: 'stat_sub_all'),
          const StatisticsSubType(apiValue: 'Guidance', labelKey: 'stat_sub_guidance'),
          const StatisticsSubType(apiValue: 'Note', labelKey: 'stat_sub_note'),
        ],
    };
  }

  /// The API filter key name for this type's sub-type filter.
  String get subTypeFilterKey {
    return switch (this) {
      StatisticsType.absenceLateness => 'type',
      StatisticsType.customMessages => 'message_type',
      StatisticsType.teacherMessages => 'message_type',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Statistics Sub-Type
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a sub-type filter option within a [StatisticsType].
class StatisticsSubType {
  const StatisticsSubType({
    required this.apiValue,
    required this.labelKey,
  });

  final String apiValue;
  final String labelKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatisticsSubType &&
          runtimeType == other.runtimeType &&
          apiValue == other.apiValue;

  @override
  int get hashCode => apiValue.hashCode;

  @override
  String toString() => 'StatisticsSubType($apiValue)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Statistics Item
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single statistics record from the API.
class StatisticsItem {
  const StatisticsItem({
    required this.id,
    required this.studentName,
    this.studentNumber,
    this.className,
    this.section,
    required this.type,
    this.subType,
    this.date,
    this.teacherName,
    this.notes,
    this.parentPhone,
    this.messageSent = false,
    this.semester,
    this.groupName,
    this.count = 0,
    this.createdAt,
  });

  /// Record unique identifier.
  final int id;

  /// Student name associated with this record.
  final String studentName;

  /// Student number/ID.
  final String? studentNumber;

  /// Class name (e.g. "Grade 3").
  final String? className;

  /// Section (e.g. "A").
  final String? section;

  /// The statistics type (absence, lateness, custom, teacher).
  final String type;

  /// Sub-type detail (e.g. "Academic Weakness", "Guidance").
  final String? subType;

  /// Date of the event.
  final DateTime? date;

  /// Teacher who reported (for teacher messages).
  final String? teacherName;

  /// Additional notes.
  final String? notes;

  /// Parent's phone number.
  final String? parentPhone;

  /// Whether an SMS was sent for this record.
  final bool messageSent;

  /// Academic semester.
  final String? semester;

  /// Group/class name.
  final String? groupName;

  /// Count (for aggregated statistics).
  final int count;

  /// Record creation timestamp.
  final DateTime? createdAt;

  factory StatisticsItem.fromJson(Map<String, dynamic> json) {
    return StatisticsItem(
      id: _parseInt(json['id']),
      studentName: json['student_name'] as String? ??
          json['name'] as String? ??
          '',
      studentNumber: json['student_number'] as String? ??
          json['student_id'] as String?,
      className: json['class_name'] as String? ??
          json['class'] as String?,
      section: json['section'] as String? ??
          json['division'] as String?,
      type: json['type'] as String? ??
          json['statistics_type'] as String? ??
          '',
      subType: json['sub_type'] as String? ??
          json['message_type'] as String?,
      date: json['date'] != null ? _parseDateTime(json['date']) : null,
      teacherName: json['teacher_name'] as String? ??
          json['teacher'] as String?,
      notes: json['notes'] as String? ??
          json['note'] as String? ??
          json['message'] as String?,
      parentPhone: json['parent_phone'] as String? ??
          json['phone'] as String?,
      messageSent: json['message_sent'] == true ||
          json['message_sent'] == 1 ||
          json['sms_sent'] == true,
      semester: json['semester'] as String? ??
          json['term'] as String?,
      groupName: json['group_name'] as String? ??
          json['group'] as String?,
      count: _parseInt(json['count'] ?? json['total'] ?? 0),
      createdAt: json['created_at'] != null
          ? _parseDateTime(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_name': studentName,
      'student_number': studentNumber,
      'class_name': className,
      'section': section,
      'type': type,
      'sub_type': subType,
      'date': date?.toIso8601String(),
      'teacher_name': teacherName,
      'notes': notes,
      'parent_phone': parentPhone,
      'message_sent': messageSent,
      'semester': semester,
      'group_name': groupName,
      'count': count,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  StatisticsItem copyWith({
    int? id,
    String? studentName,
    String? studentNumber,
    String? className,
    String? section,
    String? type,
    String? subType,
    DateTime? date,
    String? teacherName,
    String? notes,
    String? parentPhone,
    bool? messageSent,
    String? semester,
    String? groupName,
    int? count,
    DateTime? createdAt,
  }) {
    return StatisticsItem(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      studentNumber: studentNumber ?? this.studentNumber,
      className: className ?? this.className,
      section: section ?? this.section,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      date: date ?? this.date,
      teacherName: teacherName ?? this.teacherName,
      notes: notes ?? this.notes,
      parentPhone: parentPhone ?? this.parentPhone,
      messageSent: messageSent ?? this.messageSent,
      semester: semester ?? this.semester,
      groupName: groupName ?? this.groupName,
      count: count ?? this.count,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatisticsItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StatisticsItem(id: $id, student: $studentName, type: $type)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Statistics Filter
// ─────────────────────────────────────────────────────────────────────────────

/// Filter parameters for querying statistics.
class StatisticsFilter {
  const StatisticsFilter({
    this.fromDate,
    this.toDate,
    this.semester,
    this.groupId,
    this.subTypeValue,
  });

  /// Start date for date range filter.
  final DateTime? fromDate;

  /// End date for date range filter.
  final DateTime? toDate;

  /// Academic semester filter.
  final String? semester;

  /// Group/class ID filter.
  final int? groupId;

  /// Sub-type filter value (e.g. "latency", "Academic Weakness", "Guidance").
  final String? subTypeValue;

  /// Returns `true` if no filters are active.
  bool get isEmpty =>
      fromDate == null &&
      toDate == null &&
      (semester == null || semester!.isEmpty) &&
      groupId == null &&
      (subTypeValue == null ||
          subTypeValue!.isEmpty ||
          subTypeValue == 'all');

  /// Returns `true` if any filter is active.
  bool get isNotEmpty => !isEmpty;

  /// Converts to the JSON format expected by the API `filters` field.
  Map<String, dynamic> toJson(StatisticsType statisticsType) {
    final Map<String, dynamic> filters = {};

    if (fromDate != null) {
      filters['from_date'] =
          '${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}';
    }
    if (toDate != null) {
      filters['to_date'] =
          '${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}';
    }
    if (semester != null && semester!.isNotEmpty) {
      filters['semester'] = semester;
    }
    if (groupId != null) {
      filters['group_id'] = groupId;
    }
    if (subTypeValue != null &&
        subTypeValue!.isNotEmpty &&
        subTypeValue != 'all') {
      filters[statisticsType.subTypeFilterKey] = subTypeValue;
    }

    return filters;
  }

  StatisticsFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? semester,
    int? groupId,
    String? subTypeValue,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearSemester = false,
    bool clearGroupId = false,
    bool clearSubType = false,
  }) {
    return StatisticsFilter(
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      semester: clearSemester ? null : (semester ?? this.semester),
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      subTypeValue:
          clearSubType ? null : (subTypeValue ?? this.subTypeValue),
    );
  }

  /// Returns a new [StatisticsFilter] with all fields reset.
  factory StatisticsFilter.empty() => const StatisticsFilter();

  @override
  String toString() => 'StatisticsFilter(from: $fromDate, to: $toDate, '
      'semester: $semester, group: $groupId, subType: $subTypeValue)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Parsing Helpers
// ─────────────────────────────────────────────────────────────────────────────

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
