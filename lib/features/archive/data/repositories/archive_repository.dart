import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/archive/data/datasources/archive_remote_datasource.dart';
import 'package:orbit_app/features/archive/data/models/archive_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository that wraps [ArchiveRemoteDataSource] with error handling.
///
/// All methods return the result directly on success or throw a typed
/// [ApiException] on failure. The presentation layer catches these
/// exceptions and maps them to UI-friendly error states.
class ArchiveRepository {
  ArchiveRepository(this._dataSource);

  final ArchiveRemoteDataSource _dataSource;

  // ─── List ──────────────────────────────────────────────────────────────

  /// Fetches a paginated archive list with optional filters.
  ///
  /// Throws [ApiException] on network or server errors.
  Future<PaginatedResponse<ArchiveItem>> getArchiveList({
    required ArchiveType archiveType,
    int page = 1,
    int perPage = 15,
    ArchiveFilter? filter,
  }) async {
    try {
      return await _dataSource.fetchArchiveList(
        archiveType: archiveType,
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

  // ─── Count ─────────────────────────────────────────────────────────────

  /// Returns the count of archive items matching the current filters.
  Future<ArchiveCountResult> getArchiveCount({
    required ArchiveType archiveType,
    ArchiveFilter? filter,
  }) async {
    try {
      return await _dataSource.fetchArchiveCount(
        archiveType: archiveType,
        filter: filter,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────

  /// Deletes the specified archive messages. Returns the API response.
  Future<bool> deleteMessages({
    required ArchiveType archiveType,
    required List<int> messageIds,
  }) async {
    try {
      final result = await _dataSource.deleteArchiveMessages(
        archiveType: archiveType,
        messageIds: messageIds,
      );
      return result['success'] == true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ─── Export ─────────────────────────────────────────────────────────────

  /// Triggers an export of archive messages matching the filter.
  Future<String?> exportArchive({
    required ArchiveType archiveType,
    ArchiveFilter? filter,
  }) async {
    try {
      final result = await _dataSource.exportArchive(
        archiveType: archiveType,
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

  // ─── Print ─────────────────────────────────────────────────────────────

  /// Fetches all archive items for print (up to 1000).
  Future<List<ArchiveItem>> getArchiveForPrint({
    required ArchiveType archiveType,
    ArchiveFilter? filter,
  }) async {
    try {
      final result = await _dataSource.fetchArchiveForPrint(
        archiveType: archiveType,
        filter: filter,
      );
      return result.data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ─── Cancel Pending ────────────────────────────────────────────────────

  /// Cancels pending messages. Returns true on success.
  Future<bool> cancelPendingMessages({
    required List<int> messageIds,
  }) async {
    try {
      final result = await _dataSource.cancelPendingMessages(
        messageIds: messageIds,
      );
      return result['success'] == true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ─── Add to Archive ────────────────────────────────────────────────────

  /// Adds messages to the general archive. Returns true on success.
  Future<bool> addToArchive({
    required List<int> messageIds,
  }) async {
    try {
      final result = await _dataSource.addToArchive(
        messageIds: messageIds,
      );
      return result['success'] == true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ─── Restore ───────────────────────────────────────────────────────────

  /// Restores messages from the archive. Returns true on success.
  Future<bool> restoreMessages({
    required List<int> messageIds,
  }) async {
    try {
      final result = await _dataSource.restoreMessages(
        messageIds: messageIds,
      );
      return result['success'] == true;
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

/// Riverpod provider for [ArchiveRepository].
final archiveRepositoryProvider = Provider<ArchiveRepository>((ref) {
  final dataSource = ref.watch(archiveRemoteDataSourceProvider);
  return ArchiveRepository(dataSource);
});
