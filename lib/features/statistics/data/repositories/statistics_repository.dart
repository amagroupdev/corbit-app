import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/statistics/data/models/statistics_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for the ORBIT SMS V3 Statistics endpoints.
///
/// Handles API calls for listing, exporting, and downloading statistics
/// data with proper error handling and response parsing.
class StatisticsRepository {
  StatisticsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Base path for all v3 statistics endpoints.
  static const String _basePath = '/statistics';

  // ─── List ──────────────────────────────────────────────────────────────

  /// Fetches a paginated list of statistics records.
  ///
  /// [statisticsType] determines the category (absence, custom, teacher).
  /// [page] is 1-indexed. [perPage] defaults to 15.
  /// [filter] adds optional filter criteria (date range, semester, group, etc.).
  Future<PaginatedResponse<StatisticsItem>> getStatisticsList({
    required StatisticsType statisticsType,
    int page = 1,
    int perPage = 15,
    StatisticsFilter? filter,
  }) async {
    try {
      final body = <String, dynamic>{
        'statistics_type': statisticsType.apiValue,
        'page': page,
        'per_page': perPage,
      };

      if (filter != null && filter.isNotEmpty) {
        body['filters'] = filter.toJson(statisticsType);
      }

      final response = await _apiClient.post(
        '$_basePath/list',
        data: body,
      );

      final json = response.data as Map<String, dynamic>;
      final dataPayload = json['data'] as Map<String, dynamic>? ?? json;

      return PaginatedResponse<StatisticsItem>.fromJson(
        dataPayload,
        itemFromJson: (item) =>
            StatisticsItem.fromJson(item as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ─── Export ─────────────────────────────────────────────────────────────

  /// Triggers an export of statistics data matching the filter criteria.
  ///
  /// Returns a message or download URL on success.
  Future<String?> exportStatistics({
    required StatisticsType statisticsType,
    StatisticsFilter? filter,
  }) async {
    try {
      final body = <String, dynamic>{
        'statistics_type': statisticsType.apiValue,
      };

      if (filter != null && filter.isNotEmpty) {
        body['filters'] = filter.toJson(statisticsType);
      }

      final response = await _apiClient.post(
        '$_basePath/export',
        data: body,
      );

      final json = response.data as Map<String, dynamic>;

      // The server may return a download URL or a success message.
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return data['url'] as String? ?? data['download_url'] as String?;
      }
      return json['message'] as String?;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ─── Export Download ────────────────────────────────────────────────────

  /// Fetches the download URL for a previously requested statistics export.
  ///
  /// Uses GET with `statistics_type` as a query parameter.
  Future<String?> getExportDownloadUrl({
    required StatisticsType statisticsType,
  }) async {
    try {
      final response = await _apiClient.get(
        '$_basePath/export-download',
        queryParameters: {
          'statistics_type': statisticsType.apiValue,
        },
      );

      final json = response.data as Map<String, dynamic>;
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return data['url'] as String? ?? data['download_url'] as String?;
      }
      if (data is String) return data;
      return json['message'] as String?;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Riverpod provider for [StatisticsRepository].
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StatisticsRepository(apiClient);
});
