import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/certifications/data/datasources/certifications_link_remote_datasource.dart';
import 'package:orbit_app/features/certifications/data/datasources/certifications_remote_datasource.dart';
import 'package:orbit_app/features/certifications/data/models/certification_model.dart';
import 'package:orbit_app/features/certifications/data/models/certification_settings_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for certification operations (Noor / Madrasati integration).
///
/// Wraps both the legacy Noor login flow and the V3 advanced endpoints
/// (list/delete/upload-pdf/filter-options/settings) via
/// [CertificationsRemoteDatasource], plus the Certifications Link
/// feature via [CertificationsLinkRemoteDatasource].
class CertificationsRepository {
  const CertificationsRepository(
    this._apiClient,
    this._remote,
    this._link,
  );

  final ApiClient _apiClient;
  final CertificationsRemoteDatasource _remote;
  final CertificationsLinkRemoteDatasource _link;

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

  // ═══════════════════════════════════════════════════════════════════════
  // V3 — Advanced Certifications (Wave 9)
  // ═══════════════════════════════════════════════════════════════════════

  /// `POST /certifications/list` — V3 paginated list with filters.
  Future<PaginatedResponse<CertificationModel>> listAdvanced({
    int page = 1,
    int perPage = 15,
    String? search,
    String? status,
    String? platform,
    int? profileId,
    String? dateFrom,
    String? dateTo,
  }) {
    return _remote.list(
      page: page,
      perPage: perPage,
      search: search,
      status: status,
      platform: platform,
      profileId: profileId,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  /// `POST /certifications/delete`.
  Future<bool> deleteCertifications(List<int> ids) =>
      _remote.delete(ids);

  /// `POST /certifications/upload-pdf-file`.
  Future<Map<String, dynamic>> uploadPdfFile({
    required MultipartFile file,
    Map<String, dynamic>? extraFields,
    void Function(int sent, int total)? onSendProgress,
  }) {
    return _remote.uploadPdf(
      file: file,
      extraFields: extraFields,
      onSendProgress: onSendProgress,
    );
  }

  /// `GET /certifications/filter-options`.
  Future<CertificationFilterOptionsModel> getFilterOptions() =>
      _remote.filterOptions();

  /// `GET /certifications/settings`.
  Future<CertificationSettingsModel> getSettings() => _remote.getSettings();

  /// `POST /certifications/settings/noor`.
  Future<bool> updateNoorSettings({required String messageBody}) =>
      _remote.updateNoorSettings(messageBody: messageBody);

  /// `POST /certifications/settings/madrasati`.
  Future<bool> updateMadrasatiSettings({required String messageBody}) =>
      _remote.updateMadrasatiSettings(messageBody: messageBody);

  // ═══════════════════════════════════════════════════════════════════════
  // V3 — Certifications Link (Wave 9)
  // ═══════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<CertificationModel>> linkList({
    int page = 1,
    int perPage = 15,
    String? search,
  }) =>
      _link.list(page: page, perPage: perPage, search: search);

  Future<Map<String, dynamic>> linkSend({
    required List<String> numbers,
    required String senderId,
    required String message,
    String? sendAtOption,
    String? replayingService,
  }) =>
      _link.send(
        numbers: numbers,
        senderId: senderId,
        message: message,
        sendAtOption: sendAtOption,
        replayingService: replayingService,
      );

  Future<Map<String, dynamic>> linkPreview({
    required List<String> numbers,
    required String senderId,
    required String message,
  }) =>
      _link.preview(
        numbers: numbers,
        senderId: senderId,
        message: message,
      );

  Future<Map<String, dynamic>> linkNoorLogin({
    required String username,
    required String password,
  }) =>
      _link.noorLogin(username: username, password: password);

  Future<List<NoorProfile>> linkNoorProfiles() => _link.noorProfiles();
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final certificationsRepositoryProvider =
    Provider<CertificationsRepository>((ref) {
  return CertificationsRepository(
    ref.watch(apiClientProvider),
    ref.watch(certificationsRemoteDatasourceProvider),
    ref.watch(certificationsLinkRemoteDatasourceProvider),
  );
});
