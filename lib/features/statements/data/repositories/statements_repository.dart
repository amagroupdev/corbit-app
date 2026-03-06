import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/statements/data/datasources/statements_remote_datasource.dart';
import 'package:orbit_app/features/statements/data/models/statement_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository that wraps [StatementsRemoteDataSource] with error handling.
///
/// All methods return the result directly on success or throw a typed
/// [ApiException] on failure. The presentation layer catches these
/// exceptions and maps them to UI-friendly error states.
class StatementsRepository {
  StatementsRepository(this._dataSource);

  final StatementsRemoteDataSource _dataSource;

  // ─── List ──────────────────────────────────────────────────────────────

  /// Fetches a paginated statements list with optional filters.
  ///
  /// Throws [ApiException] on network or server errors.
  Future<PaginatedResponse<StatementResponseItem>> getStatementsList({
    required StatementType statementType,
    int page = 1,
    int perPage = 15,
    StatementFilter? filter,
  }) async {
    try {
      return await _dataSource.fetchStatementsList(
        statementType: statementType,
        page: page,
        perPage: perPage,
        filter: filter,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────

  /// Deletes the specified statement responses. Returns true on success.
  Future<bool> deleteResponses({
    required List<int> responseIds,
  }) async {
    try {
      final result = await _dataSource.deleteStatementResponses(
        responseIds: responseIds,
      );
      return result['success'] == true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ─── Export ─────────────────────────────────────────────────────────────

  /// Triggers an export of statement responses matching the filter.
  Future<String?> exportStatements({
    required StatementType statementType,
    StatementFilter? filter,
  }) async {
    try {
      final result = await _dataSource.exportStatements(
        statementType: statementType,
        filter: filter,
      );
      // The server may return a download URL in the `data` field.
      final data = result['data'];
      if (data is Map<String, dynamic>) {
        return data['url'] as String? ?? data['download_url'] as String?;
      }
      return result['message'] as String?;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ─── Show ──────────────────────────────────────────────────────────────

  /// Fetches a single statement response detail.
  Future<StatementResponseItem> getStatementDetail({
    required int id,
  }) async {
    try {
      return await _dataSource.fetchStatementDetail(id: id);
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

/// Riverpod provider for [StatementsRepository].
final statementsRepositoryProvider = Provider<StatementsRepository>((ref) {
  final dataSource = ref.watch(statementsRemoteDataSourceProvider);
  return StatementsRepository(dataSource);
});
