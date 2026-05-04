import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/certifications/data/models/certification_model.dart';
import 'package:orbit_app/features/certifications/data/models/certification_settings_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote datasource for the advanced V3 Certifications endpoints.
///
/// Wraps the V3 endpoints introduced in Wave 9:
/// - `POST /certifications/list`
/// - `POST /certifications/delete`
/// - `POST /certifications/upload-pdf-file`
/// - `GET  /certifications/filter-options`
/// - `GET  /certifications/settings`
/// - `POST /certifications/settings/noor`
/// - `POST /certifications/settings/madrasati`
class CertificationsRemoteDatasource {
  CertificationsRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  // ─── List ────────────────────────────────────────────────────────────────

  /// `POST /certifications/list` — paginated list with filters.
  Future<PaginatedResponse<CertificationModel>> list({
    int page = 1,
    int perPage = 15,
    String? search,
    String? status,
    String? platform,
    int? profileId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.certificationsList,
        data: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (platform != null && platform.isNotEmpty) 'platform': platform,
          if (profileId != null) 'profile_id': profileId,
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<CertificationModel>>.fromJson(
        response.data ?? const {},
        fromJsonT: (data) => PaginatedResponse<CertificationModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              CertificationModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ?? PaginatedResponse<CertificationModel>.empty();
    } on ApiException {
      rethrow;
    }
  }

  // ─── Delete ──────────────────────────────────────────────────────────────

  /// `POST /certifications/delete` — bulk delete by IDs.
  Future<bool> delete(List<int> certificationIds) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.certificationsDelete,
        data: {
          'certification_ids': certificationIds,
        },
      );
      return response.data?['success'] as bool? ?? true;
    } on ApiException {
      rethrow;
    }
  }

  // ─── Upload PDF ──────────────────────────────────────────────────────────

  /// `POST /certifications/upload-pdf-file` — multipart PDF upload.
  Future<Map<String, dynamic>> uploadPdf({
    required MultipartFile file,
    Map<String, dynamic>? extraFields,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final response = await _apiClient.upload<Map<String, dynamic>>(
        ApiConstants.certificationsUploadPdf,
        file: file,
        fileFieldName: 'pdf_file',
        data: extraFields,
        onSendProgress: onSendProgress,
      );
      return response.data ?? const {};
    } on ApiException {
      rethrow;
    }
  }

  // ─── Filter options ──────────────────────────────────────────────────────

  /// `GET /certifications/filter-options` — cached filter options.
  Future<CertificationFilterOptionsModel> filterOptions() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.certificationsFilterOptions,
      );
      final raw = response.data?['data'];
      if (raw is Map<String, dynamic>) {
        return CertificationFilterOptionsModel.fromJson(raw);
      }
      return const CertificationFilterOptionsModel();
    } on ApiException {
      rethrow;
    }
  }

  // ─── Settings ────────────────────────────────────────────────────────────

  /// `GET /certifications/settings`.
  Future<CertificationSettingsModel> getSettings() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.certificationsSettings,
      );
      final raw = response.data?['data'];
      if (raw is Map<String, dynamic>) {
        return CertificationSettingsModel.fromJson(raw);
      }
      return const CertificationSettingsModel();
    } on ApiException {
      rethrow;
    }
  }

  /// `POST /certifications/settings/noor` — `{message_body: '...'}`.
  Future<bool> updateNoorSettings({required String messageBody}) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.certificationsSettingsNoor,
        data: {'message_body': messageBody},
      );
      return response.data?['success'] as bool? ?? true;
    } on ApiException {
      rethrow;
    }
  }

  /// `POST /certifications/settings/madrasati` — `{message_body: '...'}`.
  Future<bool> updateMadrasatiSettings({required String messageBody}) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.certificationsSettingsMadrasati,
        data: {'message_body': messageBody},
      );
      return response.data?['success'] as bool? ?? true;
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final certificationsRemoteDatasourceProvider =
    Provider<CertificationsRemoteDatasource>((ref) {
  return CertificationsRemoteDatasource(ref.watch(apiClientProvider));
});
