import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/short_links/data/models/short_link_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for managing shortened URLs.
class ShortLinksRepository {
  const ShortLinksRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches a paginated list of short links.
  Future<PaginatedResponse<ShortLinkModel>> getShortLinks({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.shortLinks}/list',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<ShortLinkModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<ShortLinkModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              ShortLinkModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ?? PaginatedResponse<ShortLinkModel>.empty();
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches details of a single short link by [id].
  Future<ShortLinkModel> getShortLink(int id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.shortLinkShow(id),
      );

      final apiResponse = ApiResponse<ShortLinkModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            ShortLinkModel.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Creates a new short link from [originalUrl].
  Future<ShortLinkModel> createShortLink(String originalUrl) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.shortLinks,
        data: {'original_url': originalUrl},
      );

      final apiResponse = ApiResponse<ShortLinkModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            ShortLinkModel.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Deletes a short link by [id].
  Future<void> deleteShortLink(int id) async {
    try {
      await _apiClient.delete(
        ApiConstants.shortLinkDelete(id),
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Deletes multiple short links by [ids].
  Future<void> bulkDelete(List<int> ids) async {
    try {
      await _apiClient.post(
        '${ApiConstants.shortLinks}/bulk-delete',
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

final shortLinksRepositoryProvider = Provider<ShortLinksRepository>((ref) {
  return ShortLinksRepository(ref.watch(apiClientProvider));
});
