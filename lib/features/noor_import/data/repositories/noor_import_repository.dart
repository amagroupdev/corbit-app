import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/noor_import/data/models/noor_import_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for Noor system import operations.
///
/// Noor imports are messages sent via message_type=from_noor.
/// This involves logging into the Noor system, selecting students,
/// and sending SMS messages to their guardians.
class NoorImportRepository {
  const NoorImportRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Authenticates with the Noor system.
  Future<Map<String, dynamic>> noorLogin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.certifications}/noor/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
      );

      return apiResponse.data ?? {};
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches available Noor student groups/classes for import.
  Future<List<NoorStudentGroup>> getNoorStudentGroups() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.certifications}/noor/student-groups',
      );

      final apiResponse = ApiResponse<List<NoorStudentGroup>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => (data as List<dynamic>)
            .map((item) =>
                NoorStudentGroup.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      return apiResponse.data ?? [];
    } on ApiException {
      rethrow;
    }
  }

  /// Sends messages via Noor import.
  Future<void> sendNoorImport({
    required int senderId,
    required String messageBody,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.messagesSend,
        data: {
          'message_type': 'from_noor',
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

  /// Fetches the Noor import archive.
  Future<PaginatedResponse<NoorImportModel>> getArchive({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.archive,
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          'message_type': 'from_noor',
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<NoorImportModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<NoorImportModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              NoorImportModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ?? PaginatedResponse<NoorImportModel>.empty();
    } on ApiException {
      rethrow;
    }
  }
}

/// Model for a Noor student group/class used for import.
class NoorStudentGroup {
  const NoorStudentGroup({
    required this.id,
    required this.name,
    required this.studentCount,
    this.className,
    this.grade,
  });

  final int id;
  final String name;
  final int studentCount;
  final String? className;
  final String? grade;

  factory NoorStudentGroup.fromJson(Map<String, dynamic> json) {
    return NoorStudentGroup(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      studentCount: json['student_count'] as int? ?? 0,
      className: json['class_name'] as String?,
      grade: json['grade'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'student_count': studentCount,
      if (className != null) 'class_name': className,
      if (grade != null) 'grade': grade,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final noorImportRepositoryProvider = Provider<NoorImportRepository>((ref) {
  return NoorImportRepository(ref.watch(apiClientProvider));
});
