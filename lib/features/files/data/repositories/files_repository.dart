import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/files/data/models/file_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for file management operations.
class FilesRepository {
  const FilesRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches a paginated list of uploaded files.
  Future<PaginatedResponse<FileModel>> getFiles({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.files}/list',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      ).timeout(const Duration(seconds: 15));

      final apiResponse =
          ApiResponse<PaginatedResponse<FileModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<FileModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              FileModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ?? PaginatedResponse<FileModel>.empty();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(message: 'انتهت مهلة الاتصال. حاول مرة أخرى.');
    }
  }

  /// Uploads a new file.
  Future<FileModel> uploadFile({
    required MultipartFile file,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final response = await _apiClient.upload(
        '${ApiConstants.files}/upload',
        file: file,
        onSendProgress: onProgress,
      );

      final apiResponse = ApiResponse<FileModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            FileModel.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Gets the download URL for a file.
  Future<String> getDownloadUrl(int id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.fileDownload(id),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
      );

      return apiResponse.data?['download_url'] as String? ?? '';
    } on ApiException {
      rethrow;
    }
  }

  /// Deletes a file by [id].
  Future<void> deleteFile(int id) async {
    try {
      await _apiClient.delete(
        ApiConstants.fileDelete(id),
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Deletes multiple files by [ids].
  Future<void> bulkDelete(List<int> ids) async {
    try {
      await _apiClient.post(
        '${ApiConstants.files}/bulk-delete',
        data: {'ids': ids},
      );
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final filesRepositoryProvider = Provider<FilesRepository>((ref) {
  return FilesRepository(ref.watch(apiClientProvider));
});
