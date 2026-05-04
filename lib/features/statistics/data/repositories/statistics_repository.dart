import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
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

  // ─── Sub-accounts (Wave 8) ─────────────────────────────────────────────

  /// Fetches per-sub-account statistics from `POST /statistics/subaccounts`.
  ///
  /// Optional [subaccountId] narrows the report to a single sub-account.
  /// [filters] mirrors the generic statistics filters and is forwarded
  /// untouched to the server.
  Future<List<SubaccountStat>> getSubaccountsStats({
    int? subaccountId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final body = <String, dynamic>{
        if (subaccountId != null) 'subaccount_id': subaccountId,
        if (filters != null && filters.isNotEmpty) 'filters': filters,
      };

      final response = await _apiClient.post(
        ApiConstants.statisticsSubaccounts,
        data: body,
      );

      final json = response.data as Map<String, dynamic>?;
      if (json == null) return const [];
      final data = json['data'];

      // Server shape may be either a list or a wrapper map — accept both.
      List<dynamic> rows;
      if (data is List) {
        rows = data;
      } else if (data is Map<String, dynamic>) {
        rows = data['subaccounts'] is List
            ? data['subaccounts'] as List<dynamic>
            : data['data'] is List
                ? data['data'] as List<dynamic>
                : const <dynamic>[];
      } else {
        rows = const [];
      }

      return rows
          .whereType<Map<String, dynamic>>()
          .map(SubaccountStat.fromJson)
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUB-ACCOUNT STATS (Wave 8)
// ═══════════════════════════════════════════════════════════════════════════════

/// One row of the `/statistics/subaccounts` response. The server shape is
/// loosely typed across deployments, so all numeric fields are best-effort
/// parses with a 0 fallback.
class SubaccountStat {
  const SubaccountStat({
    required this.id,
    required this.name,
    this.totalSent = 0,
    this.totalDelivered = 0,
    this.totalFailed = 0,
    this.balanceConsumed = 0,
  });

  final int id;
  final String name;
  final int totalSent;
  final int totalDelivered;
  final int totalFailed;
  final int balanceConsumed;

  factory SubaccountStat.fromJson(Map<String, dynamic> json) {
    int parse(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return SubaccountStat(
      id: parse(json['id']),
      name: (json['name'] as String?) ?? (json['username'] as String?) ?? '',
      totalSent: parse(json['total_sent'] ?? json['sent']),
      totalDelivered: parse(json['total_delivered'] ?? json['delivered']),
      totalFailed: parse(json['total_failed'] ?? json['failed']),
      balanceConsumed:
          parse(json['balance_consumed'] ?? json['consumed_balance']),
    );
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
