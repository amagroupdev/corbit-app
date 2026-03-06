import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/attendance/data/models/attendance_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for attendance record operations.
///
/// Attendance records are sent via the messages/send endpoint with
/// message_type=attendance_records. This repository handles sending
/// and retrieving the archive.
class AttendanceRepository {
  const AttendanceRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Sends attendance records via the messages send endpoint.
  Future<void> sendAttendance({
    required int senderId,
    required String messageBody,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.messagesSend,
        data: {
          'message_type': 'attendance_records',
          'sender_id': senderId,
          'message_body': messageBody,
          if (groupIds.isNotEmpty) 'group_ids': groupIds,
          if (numbers != null && numbers.isNotEmpty) 'numbers': numbers,
        },
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches the attendance records archive.
  Future<PaginatedResponse<AttendanceModel>> getArchive({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.archive,
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          'message_type': 'attendance_records',
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<AttendanceModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<AttendanceModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              AttendanceModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ?? PaginatedResponse<AttendanceModel>.empty();
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(apiClientProvider));
});
