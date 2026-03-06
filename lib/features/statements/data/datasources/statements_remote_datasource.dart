import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/statements/data/models/statement_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote data source for the ORBIT SMS V3 Statements & Responses endpoints.
///
/// All statements endpoints use POST with JSON bodies. The server expects
/// a Bearer token in the Authorization header (handled by [ApiClient]).
class StatementsRemoteDataSource {
  const StatementsRemoteDataSource(this._client);

  final ApiClient _client;

  // Base path for all v3 statements endpoints.
  static const String _basePath = '/statements';

  // ─── List (paginated) ──────────────────────────────────────────────────

  /// Fetches a paginated list of statement responses for the given [statementType].
  ///
  /// [page] is 1-indexed. [perPage] defaults to 15.
  /// [filter] adds optional filter criteria (date range, sender, etc.).
  Future<PaginatedResponse<StatementResponseItem>> fetchStatementsList({
    required StatementType statementType,
    int page = 1,
    int perPage = 15,
    StatementFilter? filter,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': statementType.apiValue,
        'page': page,
        'per_page': perPage,
      };

      if (filter != null && filter.isNotEmpty) {
        body['filters'] = filter.toJson();
      }

      final response = await _client.post(
        _basePath,
        data: body,
      );

      final json = response.data as Map<String, dynamic>;
      final dataPayload = json['data'] as Map<String, dynamic>? ?? json;

      return PaginatedResponse<StatementResponseItem>.fromJson(
        dataPayload,
        itemFromJson: (item) =>
            StatementResponseItem.fromJson(item as Map<String, dynamic>),
      );
    } catch (_) {
      // Endpoint may not exist yet; return empty result.
      return PaginatedResponse<StatementResponseItem>.empty();
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────

  /// Deletes the statement responses with the given [responseIds].
  Future<Map<String, dynamic>> deleteStatementResponses({
    required List<int> responseIds,
  }) async {
    final response = await _client.post(
      '$_basePath/delete',
      data: {
        'response_ids': responseIds,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // ─── Export ─────────────────────────────────────────────────────────────

  /// Triggers an export of statement responses matching the filter criteria.
  ///
  /// The server typically returns a download URL or sends the export file
  /// via email.
  Future<Map<String, dynamic>> exportStatements({
    required StatementType statementType,
    StatementFilter? filter,
  }) async {
    final body = <String, dynamic>{
      'type': statementType.apiValue,
    };

    if (filter != null && filter.isNotEmpty) {
      body['filters'] = filter.toJson();
    }

    final response = await _client.post(
      '$_basePath/export',
      data: body,
    );

    return response.data as Map<String, dynamic>;
  }

  // ─── Show Single ───────────────────────────────────────────────────────

  /// Fetches a single statement response by its [id].
  Future<StatementResponseItem> fetchStatementDetail({
    required int id,
  }) async {
    final response = await _client.get(
      '$_basePath/$id',
    );

    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return StatementResponseItem.fromJson(data);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Riverpod provider for [StatementsRemoteDataSource].
final statementsRemoteDataSourceProvider =
    Provider<StatementsRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return StatementsRemoteDataSource(client);
});
