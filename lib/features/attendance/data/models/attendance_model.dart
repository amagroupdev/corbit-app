/// Model representing an attendance record in the ORBIT platform.
///
/// Attendance records track student presence/absence and are sent
/// via the messages/send endpoint with message_type=attendance_records.
class AttendanceModel {
  const AttendanceModel({
    required this.id,
    required this.studentName,
    required this.studentPhone,
    required this.status,
    required this.date,
    required this.createdAt,
    this.className,
    this.notes,
  });

  final int id;
  final String studentName;
  final String studentPhone;
  final String status; // 'present', 'absent', 'late', 'excused'
  final DateTime date;
  final DateTime createdAt;
  final String? className;
  final String? notes;

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isLate => status == 'late';
  bool get isExcused => status == 'excused';

  String get statusLabel {
    return switch (status) {
      'present' => '\u062D\u0627\u0636\u0631', // حاضر
      'absent' => '\u063A\u0627\u0626\u0628', // غائب
      'late' => '\u0645\u062A\u0623\u062E\u0631', // متأخر
      'excused' => '\u0645\u0639\u062A\u0630\u0631', // معتذر
      _ => status,
    };
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as int? ?? 0,
      studentName: json['student_name'] as String? ?? '',
      studentPhone: json['student_phone'] as String? ?? '',
      status: json['status'] as String? ?? 'absent',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      className: json['class_name'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_name': studentName,
      'student_phone': studentPhone,
      'status': status,
      'date': date.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
      if (className != null) 'class_name': className,
      if (notes != null) 'notes': notes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
