import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/certifications/data/models/certification_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote datasource for the V3 Certifications Link feature.
///
/// Wraps:
/// - `POST /certifications-link/list`
/// - `POST /certifications-link/send`
/// - `POST /certifications-link/preview`
/// - `POST /certifications-link/noor/login`
/// - `GET  /certifications-link/noor/profiles`
class CertificationsLinkRemoteDatasource {
  CertificationsLinkRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  // ─── List ────────────────────────────────────────────────────────────────

  /// `POST /certifications-link/list`.
  Future<PaginatedResponse<CertificationModel>> list({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.certificationsLinkList,
        data: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
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

  // ─── Send ────────────────────────────────────────────────────────────────

  /// `POST /certifications-link/send`.
  Future<Map<String, dynamic>> send({
    required List<String> numbers,
    required String senderId,
    required String message,
    String? sendAtOption,
    String? replayingService,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.certificationsLinkSend,
        data: {
          'numbers': numbers,
          'sender_id': senderId,
          'message': message,
          if (sendAtOption != null) 'send_at_option': sendAtOption,
          if (replayingService != null) 'replaying_service': replayingService,
        },
      );
      return response.data ?? const {};
    } on ApiException {
      rethrow;
    }
  }

  // ─── Preview ─────────────────────────────────────────────────────────────

  /// `POST /certifications-link/preview`.
  Future<Map<String, dynamic>> preview({
    required List<String> numbers,
    required String senderId,
    required String message,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.certificationsLinkPreview,
        data: {
          'numbers': numbers,
          'sender_id': senderId,
          'message': message,
        },
      );
      return response.data?['data'] as Map<String, dynamic>? ??
          response.data ??
          const {};
    } on ApiException {
      rethrow;
    }
  }

  // ─── Noor login ──────────────────────────────────────────────────────────

  /// `POST /certifications-link/noor/login` — Noor credentials.
  Future<Map<String, dynamic>> noorLogin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.certificationsLinkNoorLogin,
        data: {
          'username': username,
          'password': password,
        },
      );
      return response.data?['data'] as Map<String, dynamic>? ??
          response.data ??
          const {};
    } on ApiException {
      rethrow;
    }
  }

  // ─── Noor profiles ───────────────────────────────────────────────────────

  /// `GET /certifications-link/noor/profiles`.
  Future<List<NoorProfile>> noorProfiles() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.certificationsLinkNoorProfiles,
      );
      final raw = response.data?['data'];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(NoorProfile.fromJson)
            .toList();
      }
      return const [];
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final certificationsLinkRemoteDatasourceProvider =
    Provider<CertificationsLinkRemoteDatasource>((ref) {
  return CertificationsLinkRemoteDatasource(ref.watch(apiClientProvider));
});
