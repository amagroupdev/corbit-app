import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/certifications/data/models/certification_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for certification operations (Noor system integration).
class CertificationsRepository {
  const CertificationsRepository(this._apiClient);

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

  /// Fetches available Noor profiles.
  Future<List<NoorProfile>> getNoorProfiles() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.certifications}/noor/profiles',
      );

      final apiResponse = ApiResponse<List<NoorProfile>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => (data as List<dynamic>)
            .map((item) =>
                NoorProfile.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      return apiResponse.data ?? [];
    } on ApiException {
      rethrow;
    }
  }

  /// Sends certifications.
  Future<void> sendCertification({
    required int profileId,
    required int senderId,
    required String messageBody,
    required List<int> groupIds,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.certifications}/send',
        data: {
          'profile_id': profileId,
          'sender_id': senderId,
          'message_body': messageBody,
          if (groupIds.isNotEmpty) 'group_ids': groupIds,
        },
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Previews certifications before sending.
  Future<Map<String, dynamic>> preview({
    required int profileId,
    required int senderId,
    required String messageBody,
    required List<int> groupIds,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.certifications}/preview',
        data: {
          'profile_id': profileId,
          'sender_id': senderId,
          'message_body': messageBody,
          if (groupIds.isNotEmpty) 'group_ids': groupIds,
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

  /// Fetches the certification archive.
  Future<PaginatedResponse<CertificationModel>> getArchive({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.certifications}/list',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<CertificationModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<CertificationModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              CertificationModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ??
          PaginatedResponse<CertificationModel>.empty();
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final certificationsRepositoryProvider =
    Provider<CertificationsRepository>((ref) {
  return CertificationsRepository(ref.watch(apiClientProvider));
});
